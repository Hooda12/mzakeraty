-- Mzakeraty Cloud v4: owner-controlled content + student read-only access
create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  is_admin boolean not null default false,
  preferred_language text not null default 'ar' check (preferred_language in ('ar','en')),
  created_at timestamptz not null default now()
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name_ar text not null,
  name_en text not null default '',
  icon text not null default '📚',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.lectures (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  title_ar text not null,
  title_en text not null default '',
  status text not null default 'not_started' check (status in ('not_started','studied','review','mastered')),
  note_ar text not null default '',
  note_en text not null default '',
  file_path text,
  file_name text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.flashcards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  front_ar text not null, back_ar text not null,
  front_en text not null default '', back_en text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  question_ar text not null, question_en text not null default '',
  options_ar jsonb not null, options_en jsonb not null default '[]'::jsonb,
  answer_index int not null check (answer_index between 0 and 3),
  created_at timestamptz not null default now()
);


-- Compatibility migration from the previous v3 schema
alter table public.subjects alter column name drop not null;
alter table public.lectures alter column title drop not null;
alter table public.lectures alter column note drop not null;
alter table public.lectures drop constraint if exists lectures_status_check;
alter table public.lectures add constraint lectures_status_check check (status in ('not_started','studied','review','mastered','لم أبدأ','ذاكرتها','مراجعة','متقن'));

-- Make existing installations compatible
alter table public.profiles add column if not exists is_admin boolean not null default false;
alter table public.profiles add column if not exists preferred_language text not null default 'ar';
alter table public.subjects add column if not exists name_ar text;
alter table public.subjects add column if not exists name_en text default '';
alter table public.subjects add column if not exists sort_order int not null default 0;
alter table public.lectures add column if not exists title_ar text;
alter table public.lectures add column if not exists title_en text default '';
alter table public.lectures add column if not exists note_ar text default '';
alter table public.lectures add column if not exists note_en text default '';
alter table public.lectures add column if not exists sort_order int not null default 0;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_admin=true); $$;

alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.lectures enable row level security;
alter table public.flashcards enable row level security;
alter table public.questions enable row level security;

drop policy if exists "profiles own" on public.profiles;
drop policy if exists "profiles admin read" on public.profiles;
drop policy if exists "subjects own" on public.subjects;
drop policy if exists "subjects authenticated read" on public.subjects;
drop policy if exists "subjects admin write" on public.subjects;
drop policy if exists "lectures own" on public.lectures;
drop policy if exists "lectures authenticated read" on public.lectures;
drop policy if exists "lectures admin write" on public.lectures;
drop policy if exists "cards own" on public.flashcards;
drop policy if exists "questions own" on public.questions;

create policy "profiles own" on public.profiles for select to authenticated using (auth.uid()=id);

-- Everyone signed in can read the learning library.
create policy "subjects authenticated read" on public.subjects for select to authenticated using (true);
create policy "subjects admin write" on public.subjects for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "lectures authenticated read" on public.lectures for select to authenticated using (true);
create policy "lectures admin write" on public.lectures for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Personal study tools stay private to each student.
create policy "cards own" on public.flashcards for all to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy "questions own" on public.questions for all to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name',split_part(coalesce(new.email,''),'@',1))) on conflict(id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

insert into storage.buckets(id,name,public) values('lecture-files','lecture-files',false) on conflict(id) do nothing;
drop policy if exists "lecture files read" on storage.objects;
drop policy if exists "lecture files admin insert" on storage.objects;
drop policy if exists "lecture files admin update" on storage.objects;
drop policy if exists "lecture files admin delete" on storage.objects;
create policy "lecture files read" on storage.objects for select to authenticated using(bucket_id='lecture-files');
create policy "lecture files admin insert" on storage.objects for insert to authenticated with check(bucket_id='lecture-files' and public.is_admin());
create policy "lecture files admin update" on storage.objects for update to authenticated using(bucket_id='lecture-files' and public.is_admin()) with check(bucket_id='lecture-files' and public.is_admin());
create policy "lecture files admin delete" on storage.objects for delete to authenticated using(bucket_id='lecture-files' and public.is_admin());

-- After creating your account, run this once with your account UUID to make yourself owner/admin:
-- update public.profiles set is_admin=true where id='YOUR-USER-UUID';
