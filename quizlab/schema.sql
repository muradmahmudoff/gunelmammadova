-- Supabase > SQL Editor-də bunu bir dəfə işə salın
create table profiles(
  id uuid primary key references auth.users on delete cascade,
  full_name text not null default '',
  role text not null default 'student' check (role in ('student','teacher'))
);
create or replace function is_teacher() returns boolean language sql security definer stable as
$$ select exists(select 1 from profiles where id=auth.uid() and role='teacher') $$;

create or replace function handle_new_user() returns trigger language plpgsql security definer as $$
begin
  insert into profiles(id,full_name) values(new.id, coalesce(new.raw_user_meta_data->>'full_name',''));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

create table tests(
  id uuid primary key default gen_random_uuid(),
  title text not null, video_url text, seconds_per_q int not null default 20,
  deadline timestamptz, created_by uuid default auth.uid(), created_at timestamptz default now());
create table questions(
  id uuid primary key default gen_random_uuid(),
  test_id uuid not null references tests on delete cascade,
  position int not null, text text not null, options jsonb not null, explanation text);
create table answer_keys(
  question_id uuid primary key references questions on delete cascade, correct int not null);
create table attempts(
  id uuid primary key default gen_random_uuid(),
  test_id uuid not null references tests on delete cascade,
  student_id uuid not null references profiles on delete cascade default auth.uid(),
  score int, correct int, total int, answers jsonb, per_q jsonb, time_sec int,
  created_at timestamptz default now(), unique(test_id,student_id));

alter table profiles enable row level security;
alter table tests enable row level security;
alter table questions enable row level security;
alter table answer_keys enable row level security;
alter table attempts enable row level security;

create policy p_self on profiles for select using (id=auth.uid() or is_teacher());
create policy t_read on tests for select to authenticated using (true);
create policy t_write on tests for all using (is_teacher()) with check (is_teacher());
create policy q_read on questions for select to authenticated using (true);
create policy q_write on questions for all using (is_teacher()) with check (is_teacher());
-- düzgün cavabları şagird yalnız testi bitirdikdən sonra görə bilər
create policy k_teacher on answer_keys for all using (is_teacher()) with check (is_teacher());
create policy k_student on answer_keys for select using (exists(
  select 1 from questions q join attempts a on a.test_id=q.test_id
  where q.id=answer_keys.question_id and a.student_id=auth.uid()));
create policy a_read on attempts for select using (student_id=auth.uid() or is_teacher());
-- attempts-ə birbaşa yazmaq olmaz, yalnız aşağıdakı funksiya ilə

create or replace function submit_attempt(p_test uuid, p_answers jsonb, p_time int) returns jsonb
language plpgsql security definer as $$
declare r record; i int:=0; c int:=0; tot int:=0; per jsonb:='[]'; ok bool; dl timestamptz;
begin
  if is_teacher() then raise exception 'Müəllim test həll edə bilməz'; end if;
  select deadline into dl from tests where id=p_test;
  if dl is not null and now()>dl+interval '1 minute' then raise exception 'Testin vaxtı bitib'; end if;
  if exists(select 1 from attempts where test_id=p_test and student_id=auth.uid()) then raise exception 'Test artıq həll olunub'; end if;
  for r in select q.id,k.correct from questions q join answer_keys k on k.question_id=q.id where q.test_id=p_test order by q.position loop
    ok := (p_answers->>i)::int = r.correct;
    if ok then c:=c+1; end if; tot:=tot+1; per:=per||jsonb_build_array(ok); i:=i+1;
  end loop;
  insert into attempts(test_id,student_id,score,correct,total,answers,per_q,time_sec)
  values(p_test,auth.uid(),c*100,c,tot,p_answers,per,p_time);
  return jsonb_build_object('correct',c,'total',tot);
end $$;
