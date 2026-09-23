-- Expose media fields to the protected Ops resource table.
create or replace function public.ops_table(p_resource text, p_limit integer default 50)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare v_rows jsonb;
begin
  if not public.is_platform_admin() then
    raise exception using errcode = '42501', message = 'Acceso restringido.';
  end if;

  if p_resource = 'users' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (select id, display_name, avatar_url, created_at from profiles order by created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'worlds' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (select id, name, visibility, created_by, video_rewards_enabled, created_at from worlds order by created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'pois' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (select id, world_id, title, rarity, active, image_url, cutout_image_url, stylized_image_url, video_prize_enabled, anim_video_url, created_at from pois order by created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'captures' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.captured_at desc), '[]'::jsonb) into v_rows
    from (select id, world_id, poi_id, user_id, photo_url, captured_at from captures order by captured_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'video-spend' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (select id, world_id, poi_id, status, cost_usd_est, fal_request_id, created_at, completed_at, error from video_generation_jobs order by created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'prize-grants' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (select id, world_id, user_id, player_name, level, points_at_request, status, created_at from prize_grant_requests order by created_at desc limit least(p_limit, 200)) x;
  else
    raise exception 'Recurso Ops no permitido.';
  end if;
  return v_rows;
end;
$$;

revoke all on function public.ops_table(text, integer) from public;
grant execute on function public.ops_table(text, integer) to authenticated;
