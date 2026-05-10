-- Tables for FairShare (Splitwise Clone)

-- 1. Profiles (linked to Supabase Auth)
create table public.profiles (
  id uuid references auth.users not null primary key,
  email text,
  display_name text,
  avatar_url text,
  updated_at timestamp with time zone default now()
);

-- Enable RLS for profiles
alter table public.profiles enable row level security;
create policy "Public profiles are viewable by everyone." on profiles for select using (true);
create policy "Users can insert their own profile." on profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile." on profiles for update using (auth.uid() = id);

-- 2. Groups
create table public.groups (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  created_at timestamp with time zone default now(),
  created_by uuid references public.profiles(id)
);

-- Enable RLS for groups
alter table public.groups enable row level security;
create policy "Users can see groups they belong to" on groups
  for select using (
    exists (
      select 1 from public.group_members
      where group_id = groups.id and profile_id = auth.uid()
    )
  );
create policy "Users can create groups" on groups for insert with check (auth.uid() = created_by);

-- 3. Group Members
create table public.group_members (
  group_id uuid references public.groups(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete cascade,
  role text default 'member',
  primary key (group_id, profile_id)
);

-- Enable RLS for group members
alter table public.group_members enable row level security;
create policy "Members can see other members in same group" on group_members
  for select using (
    exists (
      select 1 from public.group_members m
      where m.group_id = group_members.group_id and m.profile_id = auth.uid()
    )
  );
create policy "Users can join groups" on group_members for insert with check (true);

-- 4. Expenses
create table public.expenses (
  id uuid default gen_random_uuid() primary key,
  group_id uuid references public.groups(id) on delete cascade,
  description text not null,
  amount decimal(12,2) not null,
  date date default current_date,
  payer_id uuid references public.profiles(id),
  created_by uuid references public.profiles(id),
  created_at timestamp with time zone default now()
);

-- Enable RLS for expenses
alter table public.expenses enable row level security;
create policy "Group members can see expenses" on expenses
  for select using (
    exists (
      select 1 from public.group_members
      where group_id = expenses.group_id and profile_id = auth.uid()
    )
  );

-- 5. Expense Splits
create table public.expense_splits (
  expense_id uuid references public.expenses(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete cascade,
  amount decimal(12,2) not null,
  primary key (expense_id, profile_id)
);

-- Enable RLS for expense splits
alter table public.expense_splits enable row level security;
create policy "Group members can see splits" on expense_splits
  for select using (
    exists (
      select 1 from public.expenses e
      join public.group_members m on e.group_id = m.group_id
      where e.id = expense_splits.expense_id and m.profile_id = auth.uid()
    )
  );
