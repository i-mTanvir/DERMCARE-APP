create extension if not exists "pgcrypto";

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  email text not null default '',
  phone text not null default '',
  profile_image text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.doctors (
  id text primary key,
  name text not null,
  specialty text not null default '',
  gender text not null default 'male',
  image_url text not null default '',
  about text not null default '',
  rating double precision not null default 0,
  experience integer not null default 0,
  available_days text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  doctor_id text not null references public.doctors (id) on delete restrict,
  doctor_name text not null default '',
  date text not null,
  time text not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists appointments_user_id_idx on public.appointments (user_id);
create index if not exists appointments_created_at_idx on public.appointments (created_at desc);
create index if not exists doctors_gender_idx on public.doctors (gender);

alter table public.users enable row level security;
alter table public.doctors enable row level security;
alter table public.appointments enable row level security;

drop policy if exists "users_select_own" on public.users;
create policy "users_select_own"
on public.users for select
to authenticated
using (auth.uid() = id);

drop policy if exists "users_insert_own" on public.users;
create policy "users_insert_own"
on public.users for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own"
on public.users for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "doctors_select_authenticated" on public.doctors;
create policy "doctors_select_authenticated"
on public.doctors for select
to authenticated
using (true);

drop policy if exists "appointments_select_own" on public.appointments;
create policy "appointments_select_own"
on public.appointments for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "appointments_insert_own" on public.appointments;
create policy "appointments_insert_own"
on public.appointments for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "appointments_update_own" on public.appointments;
create policy "appointments_update_own"
on public.appointments for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
before update on public.users
for each row execute procedure public.set_updated_at();

drop trigger if exists doctors_set_updated_at on public.doctors;
create trigger doctors_set_updated_at
before update on public.doctors
for each row execute procedure public.set_updated_at();

drop trigger if exists appointments_set_updated_at on public.appointments;
create trigger appointments_set_updated_at
before update on public.appointments
for each row execute procedure public.set_updated_at();
