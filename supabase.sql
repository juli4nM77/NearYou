-- ============================================================
-- Pega TODO esto en Supabase → SQL Editor → Run
-- ============================================================

-- 1) Tabla: una fila por placa (código → URL de destino)
create table if not exists public.redirecciones (
  codigo     text primary key,
  url        text not null,
  updated_at timestamptz not null default now()
);

-- 2) Seguridad: cualquiera puede LEER (lo necesita quien escanea),
--    pero nadie puede escribir directamente en la tabla.
alter table public.redirecciones enable row level security;

drop policy if exists "lectura publica" on public.redirecciones;
create policy "lectura publica"
  on public.redirecciones for select
  using (true);

-- 3) Función de guardado: verifica la contraseña EN EL SERVIDOR.
--    ⚠️ Cambia 'CAMBIA_ESTA_CLAVE' por tu contraseña antes de ejecutar.
create or replace function public.guardar_redireccion(
  p_codigo text,
  p_url    text,
  p_clave  text
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_clave is distinct from 'CAMBIA_ESTA_CLAVE' then
    raise exception 'clave incorrecta';
  end if;

  if p_url !~* '^https?://' then
    raise exception 'url invalida';
  end if;

  insert into public.redirecciones (codigo, url)
  values (upper(trim(p_codigo)), p_url)
  on conflict (codigo)
  do update set url = excluded.url, updated_at = now();
end;
$$;

grant execute on function public.guardar_redireccion(text, text, text) to anon;

-- 4) (Opcional) Placa de prueba
insert into public.redirecciones (codigo, url)
values ('PLACA-001', 'https://www.google.com')
on conflict (codigo) do nothing;
