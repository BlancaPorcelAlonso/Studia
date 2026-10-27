create unique index if not exists idx_subjects_user_id_id
  on public.subjects(user_id, id);

create table if not exists public.study_notes (
  id text not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  subject_id text not null,
  title text not null,
  topic text not null,
  category text not null,
  content text not null default '',
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id, subject_id)
    references public.subjects(user_id, id) on delete cascade
);

create table if not exists public.note_check_items (
  id text not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  note_id text not null,
  text text not null,
  is_checked boolean not null default false,
  position integer not null default 0,
  primary key (user_id, id),
  foreign key (user_id, note_id)
    references public.study_notes(user_id, id) on delete cascade
);

create table if not exists public.note_tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  note_id text not null,
  tag text not null,
  foreign key (user_id, note_id)
    references public.study_notes(user_id, id) on delete cascade
);

create table if not exists public.note_attachments (
  id text not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  note_id text not null,
  name text not null,
  storage_path text not null,
  size_bytes bigint not null default 0,
  mime_type text,
  primary key (user_id, id),
  foreign key (user_id, note_id)
    references public.study_notes(user_id, id) on delete cascade
);

alter table public.study_notes enable row level security;
alter table public.note_check_items enable row level security;
alter table public.note_tags enable row level security;
alter table public.note_attachments enable row level security;

drop policy if exists "Users can manage own study notes"
  on public.study_notes;
create policy "Users can manage own study notes"
  on public.study_notes
  for all
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.subjects
      where subjects.id = study_notes.subject_id
        and subjects.user_id = auth.uid()
    )
  );

drop policy if exists "Users can manage own note checklist"
  on public.note_check_items;
create policy "Users can manage own note checklist"
  on public.note_check_items
  for all
  using (
    auth.uid() = user_id
    and exists (
      select 1
      from public.study_notes
      where study_notes.id = note_check_items.note_id
        and study_notes.user_id = auth.uid()
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.study_notes
      where study_notes.id = note_check_items.note_id
        and study_notes.user_id = auth.uid()
    )
  );

drop policy if exists "Users can manage own note tags"
  on public.note_tags;
create policy "Users can manage own note tags"
  on public.note_tags
  for all
  using (
    auth.uid() = user_id
    and exists (
      select 1
      from public.study_notes
      where study_notes.id = note_tags.note_id
        and study_notes.user_id = auth.uid()
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.study_notes
      where study_notes.id = note_tags.note_id
        and study_notes.user_id = auth.uid()
    )
  );

drop policy if exists "Users can manage own note attachments"
  on public.note_attachments;
create policy "Users can manage own note attachments"
  on public.note_attachments
  for all
  using (
    auth.uid() = user_id
    and exists (
      select 1
      from public.study_notes
      where study_notes.id = note_attachments.note_id
        and study_notes.user_id = auth.uid()
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.study_notes
      where study_notes.id = note_attachments.note_id
        and study_notes.user_id = auth.uid()
    )
  );

create index if not exists idx_study_notes_user_id
  on public.study_notes(user_id);
create index if not exists idx_study_notes_subject_id
  on public.study_notes(subject_id);
create index if not exists idx_note_check_items_user_id
  on public.note_check_items(user_id);
create index if not exists idx_note_check_items_note_id
  on public.note_check_items(note_id);
create index if not exists idx_note_tags_user_id
  on public.note_tags(user_id);
create index if not exists idx_note_tags_note_id
  on public.note_tags(note_id);
create index if not exists idx_note_attachments_user_id
  on public.note_attachments(user_id);
create index if not exists idx_note_attachments_note_id
  on public.note_attachments(note_id);

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

notify pgrst, 'reload schema';
