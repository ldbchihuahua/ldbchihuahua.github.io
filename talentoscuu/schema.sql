-- =====================================================================
-- Talentos CUU · Control de ampayeo y pagos
-- Ejecutar UNA vez en Supabase: SQL Editor > New query > pegar > Run
-- Proyecto: https://muackgffpnpdojzhduuk.supabase.co
-- Todas las tablas llevan prefijo tc_ para no chocar con otras apps.
-- =====================================================================

-- ---------- Perfiles y roles ----------
create table if not exists public.tc_perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  nombre text,
  rol text not null default 'pendiente' check (rol in ('admin','usuario','pendiente')),
  creado timestamptz not null default now()
);

create or replace function public.tc_rol() returns text
language sql stable security definer set search_path = public as $$
  select rol from public.tc_perfiles where id = auth.uid()
$$;

create or replace function public.tc_es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select rol = 'admin' from public.tc_perfiles where id = auth.uid()), false)
$$;

create or replace function public.tc_es_miembro() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select rol in ('admin','usuario') from public.tc_perfiles where id = auth.uid()), false)
$$;

-- La app la llama al iniciar sesión: crea el perfil si no existe.
-- El PRIMER usuario que entra queda como admin; los demás quedan "pendiente"
-- hasta que un admin los active.
create or replace function public.tc_registrar(p_nombre text default null) returns text
language plpgsql security definer set search_path = public as $$
declare v_rol text;
begin
  if auth.uid() is null then return null; end if;
  select rol into v_rol from tc_perfiles where id = auth.uid();
  if v_rol is not null then return v_rol; end if;
  v_rol := case when exists (select 1 from tc_perfiles where rol = 'admin') then 'pendiente' else 'admin' end;
  insert into tc_perfiles (id, email, nombre, rol)
  values (auth.uid(), (select email from auth.users where id = auth.uid()), p_nombre, v_rol);
  return v_rol;
end $$;

-- ---------- Catálogos ----------
create table if not exists public.tc_torneos (
  id bigint generated always as identity primary key,
  nombre text not null,
  tipo text not null default 'Torneo' check (tipo in ('Torneo','Liga')),
  costo_ampayeo numeric(10,2) not null default 0,
  activo boolean not null default true,
  creado timestamptz not null default now()
);

create table if not exists public.tc_jugadores (
  id bigint generated always as identity primary key,
  nombre text not null,
  numero text,
  posicion text,
  telefono text,
  activo boolean not null default true,
  creado timestamptz not null default now()
);

-- Qué peloteros juegan en cada torneo / liga
create table if not exists public.tc_torneo_jugadores (
  torneo_id bigint not null references public.tc_torneos(id) on delete cascade,
  jugador_id bigint not null references public.tc_jugadores(id) on delete cascade,
  primary key (torneo_id, jugador_id)
);

create table if not exists public.tc_conceptos (
  id bigint generated always as identity primary key,
  nombre text not null,
  descripcion text,
  activo boolean not null default true,
  creado timestamptz not null default now()
);

-- ---------- Juegos y cargos ----------
create table if not exists public.tc_juegos (
  id bigint generated always as identity primary key,
  fecha date not null default current_date,
  torneo_id bigint not null references public.tc_torneos(id),
  concepto_id bigint references public.tc_conceptos(id),
  rival text not null,
  costo_total numeric(10,2) not null default 0,
  notas text,
  creado_por uuid default auth.uid(),
  creado timestamptz not null default now()
);

-- Un renglón por pelotero que asistió: su parte del ampayeo y si ya pagó
create table if not exists public.tc_cargos (
  id bigint generated always as identity primary key,
  juego_id bigint not null references public.tc_juegos(id) on delete cascade,
  jugador_id bigint not null references public.tc_jugadores(id),
  monto numeric(10,2) not null default 0,
  pagado boolean not null default false,
  fecha_pago timestamptz,
  unique (juego_id, jugador_id)
);

create index if not exists tc_cargos_jugador_idx on public.tc_cargos(jugador_id);
create index if not exists tc_juegos_torneo_idx on public.tc_juegos(torneo_id);

-- ---------- Seguridad (RLS) ----------
alter table public.tc_perfiles enable row level security;
alter table public.tc_torneos enable row level security;
alter table public.tc_jugadores enable row level security;
alter table public.tc_torneo_jugadores enable row level security;
alter table public.tc_conceptos enable row level security;
alter table public.tc_juegos enable row level security;
alter table public.tc_cargos enable row level security;

drop policy if exists tc_perfiles_sel on public.tc_perfiles;
create policy tc_perfiles_sel on public.tc_perfiles for select to authenticated
  using (id = auth.uid() or public.tc_es_admin());
drop policy if exists tc_perfiles_upd on public.tc_perfiles;
create policy tc_perfiles_upd on public.tc_perfiles for update to authenticated
  using (public.tc_es_admin()) with check (public.tc_es_admin());
drop policy if exists tc_perfiles_del on public.tc_perfiles;
create policy tc_perfiles_del on public.tc_perfiles for delete to authenticated
  using (public.tc_es_admin() and id <> auth.uid());

-- Catálogos: todos los miembros leen; solo admin da de alta / edita / borra
do $$
declare t text;
begin
  foreach t in array array['tc_torneos','tc_jugadores','tc_torneo_jugadores','tc_conceptos'] loop
    execute format('drop policy if exists %1$s_sel on public.%1$s', t);
    execute format('create policy %1$s_sel on public.%1$s for select to authenticated using (public.tc_es_miembro())', t);
    execute format('drop policy if exists %1$s_adm on public.%1$s', t);
    execute format('create policy %1$s_adm on public.%1$s for all to authenticated using (public.tc_es_admin()) with check (public.tc_es_admin())', t);
  end loop;
end $$;

-- Juegos y cargos: los miembros registran juegos y marcan pagos; solo admin borra
do $$
declare t text;
begin
  foreach t in array array['tc_juegos','tc_cargos'] loop
    execute format('drop policy if exists %1$s_sel on public.%1$s', t);
    execute format('create policy %1$s_sel on public.%1$s for select to authenticated using (public.tc_es_miembro())', t);
    execute format('drop policy if exists %1$s_ins on public.%1$s', t);
    execute format('create policy %1$s_ins on public.%1$s for insert to authenticated with check (public.tc_es_miembro())', t);
    execute format('drop policy if exists %1$s_upd on public.%1$s', t);
    execute format('create policy %1$s_upd on public.%1$s for update to authenticated using (public.tc_es_miembro()) with check (public.tc_es_miembro())', t);
    execute format('drop policy if exists %1$s_del on public.%1$s', t);
    execute format('create policy %1$s_del on public.%1$s for delete to authenticated using (public.tc_es_admin())', t);
  end loop;
end $$;

grant execute on function public.tc_registrar(text) to authenticated;
grant execute on function public.tc_rol(), public.tc_es_admin(), public.tc_es_miembro() to authenticated;

-- Concepto de pago inicial (opcional)
insert into public.tc_conceptos (nombre, descripcion)
select 'Ampayeo', 'Pago de umpires por juego'
where not exists (select 1 from public.tc_conceptos where nombre = 'Ampayeo');
