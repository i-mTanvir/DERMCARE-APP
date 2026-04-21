alter table public.users
add column if not exists role text not null default 'patient';

alter table public.doctors
add column if not exists user_id uuid unique references auth.users (id) on delete cascade,
add column if not exists license_number text not null default '',
add column if not exists designation text not null default '',
add column if not exists age integer;

create index if not exists doctors_user_id_idx on public.doctors (user_id);
