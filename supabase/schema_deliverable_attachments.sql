create table if not exists public.deliverable_attachments (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  deliverable_id text references public.deliverables(id) on delete cascade not null,
  name text not null,
  storage_path text not null,
  size_bytes bigint not null default 0,
  mime_type text,
  created_at timestamptz not null default now()
);

alter table public.deliverable_attachments enable row level security;

drop policy if exists "Users can manage own deliverable attachments"
  on public.deliverable_attachments;
create policy "Users can manage own deliverable attachments"
  on public.deliverable_attachments
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists idx_deliverable_attachments_user_id
  on public.deliverable_attachments(user_id);
create index if not exists idx_deliverable_attachments_deliverable_id
  on public.deliverable_attachments(deliverable_id);

insert into storage.buckets (id, name, public)
values ('agenda-attachments', 'agenda-attachments', false)
on conflict (id) do update set public = false;

drop policy if exists "Users can read own agenda attachments"
  on storage.objects;
create policy "Users can read own agenda attachments"
  on storage.objects
  for select
  using (
    bucket_id = 'agenda-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can upload own agenda attachments"
  on storage.objects;
create policy "Users can upload own agenda attachments"
  on storage.objects
  for insert
  with check (
    bucket_id = 'agenda-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update own agenda attachments"
  on storage.objects;
create policy "Users can update own agenda attachments"
  on storage.objects
  for update
  using (
    bucket_id = 'agenda-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'agenda-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete own agenda attachments"
  on storage.objects;
create policy "Users can delete own agenda attachments"
  on storage.objects
  for delete
  using (
    bucket_id = 'agenda-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );