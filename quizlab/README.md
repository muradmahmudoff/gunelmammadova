# QuizLab — Supabase + Vercel

## 1. Supabase
1. supabase.com-da yeni layihə yaradın.
2. **SQL Editor** → `schema.sql` faylının məzmununu yapışdırıb **Run** edin.
3. **Authentication → Providers → Email** → **"Confirm email"** seçimini söndürün (şagirdlər real email olmadan, yalnız istifadəçi adı ilə girəcək).
4. **Authentication → Users → Add user** ilə müəllimin hesabını yaradın (real email + parol).
5. SQL Editor-də müəllimi təyin edin:
   `update profiles set role='teacher', full_name='Ad Soyad' where id=(select id from auth.users where email='MUELLIM@EMAIL.COM');`
6. **Project Settings → API** bölməsindən `Project URL` və `anon public` key-i götürün.

## 2. Kod
`index.html` faylının yuxarısındakı `SUPABASE_URL` və `SUPABASE_KEY` sətirlərinə bunları yazın.

## 3. Vercel
- Qovluğu GitHub-a yükləyin → vercel.com → **Add New Project** → həmin repo → **Deploy** (build lazım deyil, statik saytdır).
- Və ya: `npx vercel` əmri ilə qovluqdan birbaşa deploy edin.

## Giriş
- **Şagird:** "Şagird" tabında qeydiyyatdan keçir (ad soyad, istifadəçi adı, parol).
- **Müəllim:** "Müəllim" tabında email + parol ilə girir.

## Təhlükəsizlik
Düzgün cavablar ayrıca cədvəldədir və şagird testi bitirməmiş onları görə bilmir. Bal serverdə hesablanır (`submit_attempt`), şagird nəticəni dəyişə bilməz.
