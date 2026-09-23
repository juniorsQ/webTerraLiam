-- Platform admin authorization, server-side AI video budget, and Ops metrics.
-- Apply after the mobile app migrations that create worlds, pois, captures,
-- player_progress, prize_grant_requests, and world_points_config.

create table if not exists public.platform_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

insert into public.platform_settings (key, value)
values
  ('video_policy', '{"max_videos_per_world_per_month": 4, "unit_cost_usd": 0.28}'::jsonb)
on conflict (key) do nothing;

create table if not exists public.video_generation_jobs (
  id uuid primary key default gen_random_uuid(),
  world_id uuid not null references public.worlds(id) on delete cascade,
  poi_id uuid not null references public.pois(id) on delete cascade,
  requested_by uuid not null references auth.users(id) on delete cascade,
  status text not null default 'queued'
    check (status in ('queued', 'processing', 'completed', 'failed', 'cancelled')),
  fal_request_id text,
  cost_usd_est numeric(10, 4) not null default 0.28,
  video_url text,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  error text
);

create index if not exists video_generation_jobs_world_month_idx
  on public.video_generation_jobs (world_id, created_at desc);
create index if not exists video_generation_jobs_status_idx
  on public.video_generation_jobs (status, created_at desc);

alter table public.prize_grant_requests
  add column if not exists used_at timestamptz;

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'platform_admin')::boolean, false);
$$;

grant execute on function public.is_platform_admin() to authenticated;

alter table public.platform_settings enable row level security;
alter table public.video_generation_jobs enable row level security;

drop policy if exists platform_settings_admin on public.platform_settings;
create policy platform_settings_admin on public.platform_settings
  for all to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists video_jobs_admin on public.video_generation_jobs;
create policy video_jobs_admin on public.video_generation_jobs
  for select to authenticated
  using (public.is_platform_admin());

drop policy if exists video_jobs_requester on public.video_generation_jobs;
create policy video_jobs_requester on public.video_generation_jobs
  for select to authenticated
  using (requested_by = auth.uid());

create or replace function public.request_video_generation(
  p_world_id uuid,
  p_poi_id uuid,
  p_regenerate boolean default false
)
returns public.video_generation_jobs
language plpgsql
security definer
set search_path = public
as $$
declare
  v_poi public.pois%rowtype;
  v_world public.worlds%rowtype;
  v_progress public.player_progress%rowtype;
  v_grant public.prize_grant_requests%rowtype;
  v_job public.video_generation_jobs%rowtype;
  v_limit integer := 4;
  v_used integer;
  v_policy jsonb;
begin
  if auth.uid() is null then
    raise exception using errcode = '42501', message = 'Debes iniciar sesión.';
  end if;

  select * into v_world from public.worlds where id = p_world_id for share;
  if not found then raise exception 'Mundo no encontrado.'; end if;

  if not exists (
    select 1 from public.world_members
    where world_id = p_world_id and user_id = auth.uid() and role in ('owner', 'editor')
  ) then
    raise exception using errcode = '42501', message = 'No tienes permisos para este mundo.';
  end if;

  if not v_world.video_rewards_enabled then
    raise exception 'Los premios de video están desactivados en este mundo.';
  end if;

  select * into v_poi from public.pois where id = p_poi_id and world_id = p_world_id for share;
  if not found then raise exception 'Hallazgo no encontrado.'; end if;
  if not v_poi.video_prize_enabled then raise exception 'Este hallazgo no tiene premio de video.'; end if;
  if v_poi.anim_video_url is not null and not p_regenerate then
    raise exception 'Este hallazgo ya tiene un video.';
  end if;

  select value into v_policy from public.platform_settings where key = 'video_policy';
  v_limit := coalesce((v_policy ->> 'max_videos_per_world_per_month')::integer, 4);
  select count(*) into v_used
  from public.video_generation_jobs
  where world_id = p_world_id
    and created_at >= date_trunc('month', now())
    and status in ('queued', 'processing', 'completed');
  if v_used >= v_limit then raise exception 'Se alcanzó el límite mensual de videos de este mundo.'; end if;

  select * into v_progress from public.player_progress
  where world_id = p_world_id and user_id = auth.uid() for update;
  select * into v_grant from public.prize_grant_requests
  where world_id = p_world_id and user_id = auth.uid() and status = 'granted' and used_at is null
  order by created_at asc limit 1 for update;
  if not found and (v_progress.user_id is null or v_progress.prize_credits < 1) then
    raise exception 'No tienes créditos de video disponibles.';
  end if;

  if found then
    update public.prize_grant_requests set used_at = now() where id = v_grant.id;
  elsif v_progress.prize_credits > 0 then
    update public.player_progress set prize_credits = prize_credits - 1, updated_at = now()
    where user_id = auth.uid() and world_id = p_world_id;
  end if;

  insert into public.video_generation_jobs (world_id, poi_id, requested_by, cost_usd_est)
  values (p_world_id, p_poi_id, auth.uid(), coalesce((v_policy ->> 'unit_cost_usd')::numeric, 0.28))
  returning * into v_job;
  return v_job;
end;
$$;

revoke all on function public.request_video_generation(uuid, uuid, boolean) from public;
grant execute on function public.request_video_generation(uuid, uuid, boolean) to authenticated;

create or replace function public.ops_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_result jsonb;
begin
  if not public.is_platform_admin() then
    raise exception using errcode = '42501', message = 'Acceso restringido.';
  end if;
  select jsonb_build_object(
    'users', (select count(*) from public.profiles),
    'users_7d', (select count(*) from public.profiles where created_at >= now() - interval '7 days'),
    'users_30d', (select count(*) from public.profiles where created_at >= now() - interval '30 days'),
    'worlds', (select count(*) from public.worlds),
    'pois', (select count(*) from public.pois where active),
    'captures', (select count(*) from public.captures),
    'videos', (select count(*) from public.video_generation_jobs where status = 'completed'),
    'video_spend_usd', (select coalesce(sum(cost_usd_est), 0) from public.video_generation_jobs where status in ('queued', 'processing', 'completed')),
    'pending_prizes', (select count(*) from public.prize_grant_requests where status = 'pending'),
    'new_users', coalesce((select jsonb_agg(to_jsonb(u) order by u.created_at desc) from (select id, display_name, created_at from public.profiles order by created_at desc limit 8) u), '[]'::jsonb),
    'recent_worlds', coalesce((select jsonb_agg(to_jsonb(w) order by w.created_at desc) from (select id, name, visibility, created_at from public.worlds order by created_at desc limit 8) w), '[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.ops_dashboard() from public;
grant execute on function public.ops_dashboard() to authenticated;

create or replace function public.ops_table(p_resource text, p_limit integer default 50)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare v_rows jsonb;
begin
  if not public.is_platform_admin() then raise exception using errcode = '42501', message = 'Acceso restringido.'; end if;
  if p_resource = 'users' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows from (select id, display_name, avatar_url, created_at from profiles order by created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'worlds' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows from (select id, name, visibility, created_by, video_rewards_enabled, created_at from worlds order by created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'pois' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows from (select id, world_id, title, rarity, active, video_prize_enabled, anim_video_url, created_at from pois order by created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'captures' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.captured_at desc), '[]'::jsonb) into v_rows from (select id, world_id, poi_id, user_id, captured_at from captures order by captured_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'video-spend' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows from (select id, world_id, poi_id, status, cost_usd_est, fal_request_id, created_at, completed_at, error from video_generation_jobs order by created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'prize-grants' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows from (select id, world_id, user_id, player_name, level, points_at_request, status, created_at from prize_grant_requests order by created_at desc limit least(p_limit, 200)) x;
  else raise exception 'Recurso Ops no permitido.';
  end if;
  return v_rows;
end;
$$;

revoke all on function public.ops_table(text, integer) from public;
grant execute on function public.ops_table(text, integer) to authenticated;

comment on function public.is_platform_admin() is 'Authorization source for the product backoffice. Reads auth.users raw_app_meta_data through the JWT app_metadata claim.';