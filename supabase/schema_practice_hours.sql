create table if not exists public.practice_hours (
  user_id uuid primary key references auth.users(id) on delete cascade,
  total_minutes bigint not null default 0 check (total_minutes >= 0),
  updated_at timestamptz not null default now()
);

alter table public.practice_hours enable row level security;

drop policy if exists "Users can read own practice hours"
  on public.practice_hours;
create policy "Users can read own practice hours"
  on public.practice_hours
  for select
  to authenticated
  using (auth.uid() = user_id);

grant select on public.practice_hours to authenticated;

create or replace function public.get_or_create_practice_hours(
  p_initial_minutes bigint
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_total bigint;
begin
  if auth.uid() is null then
    raise exception 'Se requiere una sesión activa.';
  end if;

  insert into public.practice_hours (user_id, total_minutes, updated_at)
  values (
    auth.uid(),
    greatest(coalesce(p_initial_minutes, 0), 0),
    now()
  )
  on conflict (user_id) do nothing;

  select total_minutes
  into current_total
  from public.practice_hours
  where user_id = auth.uid();

  return current_total;
end;
$$;

create or replace function public.add_practice_minutes(p_minutes bigint)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_total bigint;
begin
  if auth.uid() is null then
    raise exception 'Se requiere una sesión activa.';
  end if;

  if p_minutes is null or p_minutes <= 0 then
    raise exception 'Los minutos deben ser mayores que cero.';
  end if;

  insert into public.practice_hours as current_hours (
    user_id,
    total_minutes,
    updated_at
  )
  values (auth.uid(), p_minutes, now())
  on conflict (user_id) do update
  set total_minutes = current_hours.total_minutes + excluded.total_minutes,
      updated_at = now()
  returning total_minutes into current_total;

  return current_total;
end;
$$;

revoke all on function public.get_or_create_practice_hours(bigint) from public;
revoke all on function public.add_practice_minutes(bigint) from public;
grant execute on function public.get_or_create_practice_hours(bigint)
  to authenticated;
grant execute on function public.add_practice_minutes(bigint)
  to authenticated;

notify pgrst, 'reload schema';
