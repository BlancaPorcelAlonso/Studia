-- Añade la relación opcional entre una tarea y una entrega.
-- Las tareas existentes se conservan y quedan sin entrega vinculada.
alter table public.tasks
  add column if not exists linked_deliverable_id text
  references public.deliverables(id) on delete set null;

notify pgrst, 'reload schema';
