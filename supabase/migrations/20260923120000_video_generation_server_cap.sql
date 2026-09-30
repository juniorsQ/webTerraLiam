-- Harden video generation: optional prize credit, Fal poll URLs, monthly counting.
-- Single unambiguous 4-arg RPC signature.

alter table public.video_generation_jobs
  add column if not exists fal_status_url text,
  add column if not exists fal_response_url text;

drop function if exists public.request_video_generation(uuid, uuid, boolean);

create or replace function public.request_video_generation(
  p_world_id uuid,
  p_poi_id uuid,
  p_regenerate boolean default false,
  p_require_prize_credit boolean default false
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
  v_unit numeric := 0.28;
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

  perform pg_advisory_xact_lock(hashtextextended(p_world_id::text, 0));

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
  v_unit := coalesce((v_policy ->> 'unit_cost_usd')::numeric, 0.28);

  select count(*) into v_used
  from public.video_generation_jobs
  where world_id = p_world_id
    and created_at >= date_trunc('month', now())
    and status in ('queued', 'processing', 'completed');

  if v_used >= v_limit then
    raise exception 'Se alcanzó el límite mensual de videos de este mundo (%).', v_limit;
  end if;

  if p_require_prize_credit then
    select * into v_progress from public.player_progress
    where world_id = p_world_id and user_id = auth.uid() for update;
    select * into v_grant from public.prize_grant_requests
    where world_id = p_world_id and user_id = auth.uid() and status = 'granted' and used_at is null
    order by created_at asc limit 1 for update;
    if not found and coalesce(v_progress.prize_credits, 0) < 1 then
      raise exception 'No tienes créditos de video disponibles.';
    end if;

    if found then
      update public.prize_grant_requests set used_at = now() where id = v_grant.id;
    elsif coalesce(v_progress.prize_credits, 0) > 0 then
      update public.player_progress set prize_credits = prize_credits - 1, updated_at = now()
      where user_id = auth.uid() and world_id = p_world_id;
    end if;
  end if;

  insert into public.video_generation_jobs (world_id, poi_id, requested_by, cost_usd_est, status)
  values (p_world_id, p_poi_id, auth.uid(), v_unit, 'queued')
  returning * into v_job;
  return v_job;
end;
$$;

revoke all on function public.request_video_generation(uuid, uuid, boolean, boolean) from public;
grant execute on function public.request_video_generation(uuid, uuid, boolean, boolean) to authenticated;
