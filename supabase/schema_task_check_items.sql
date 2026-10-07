-- Migración de Supabase para tabla task_check_items
-- Permite gestionar subtareas / checklist de cada tarea con seguridad RLS por usuario.

create table if not exists public.task_check_items (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  task_id text references public.tasks(id) on delete cascade not null,
  text text not null,
  is_checked boolean not null default false,
  position integer not null default 0,
  created_at timestamptz default now()
);

-- Habilitar Row Level Security (RLS)
alter table public.task_check_items enable row level security;

-- Política para que los usuarios gestionen exclusivamente sus propias subtareas
drop policy if exists "Users can manage own task check items"
  on public.task_check_items;
create policy "Users can manage own task check items"
  on public.task_check_items
  for all
  using (
    auth.uid() = user_id
    and exists (
      select 1
      from public.tasks as parent_task
      where parent_task.id = task_check_items.task_id
        and parent_task.user_id = auth.uid()
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.tasks as parent_task
      where parent_task.id = task_check_items.task_id
        and parent_task.user_id = auth.uid()
    )
  );

-- Índices recomendados para consultas rápidas
create index if not exists idx_task_check_items_user_id on public.task_check_items(user_id);
create index if not exists idx_task_check_items_task_id on public.task_check_items(task_id);
