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
    from (select p.display_name as nombre, p.avatar_url, p.created_at,
                 coalesce((select count(*) from worlds w where w.created_by = p.id), 0) as mundos_creados,
                 coalesce((select count(*) from world_explorers e where e.created_by = p.id), 0) as representados
          from profiles p order by p.created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'worlds' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (select w.name as mundo, w.visibility as visibilidad,
                 coalesce(p.display_name, 'Cuenta sin perfil') as padre,
                 coalesce((select string_agg(coalesce(e.nickname, 'Representado'), ', ' order by e.created_at)
                           from world_explorers e where e.world_id = w.id), 'Sin representados') as ninos,
                 coalesce((select count(*) from world_members m where m.world_id = w.id), 0) as miembros,
                 w.video_rewards_enabled as premios_video, w.created_at
          from worlds w left join profiles p on p.id = w.created_by
          order by w.created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'pois' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (select poi.title as hallazgo, w.name as mundo,
                 coalesce(p.display_name, 'Cuenta sin perfil') as creado_por,
                 poi.rarity as rareza, poi.active as activo, poi.image_url, poi.cutout_image_url,
                 poi.stylized_image_url, poi.video_prize_enabled as premio_video, poi.anim_video_url, poi.created_at
          from pois poi left join worlds w on w.id = poi.world_id left join profiles p on p.id = poi.created_by
          order by poi.created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'captures' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.captured_at desc), '[]'::jsonb) into v_rows
    from (select coalesce(p.display_name, 'Jugador sin perfil') as jugador,
                 coalesce(w.name, 'Mundo sin nombre') as mundo, coalesce(poi.title, 'Hallazgo sin nombre') as hallazgo,
                 c.photo_url, c.captured_at
          from captures c left join profiles p on p.id = c.user_id
          left join worlds w on w.id = c.world_id left join pois poi on poi.id = c.poi_id
          order by c.captured_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'video-spend' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (select id, world_id, poi_id, status, cost_usd_est, fal_request_id, created_at, completed_at, error from video_generation_jobs order by created_at desc limit least(p_limit, 200)) x;
  elsif p_resource = 'prize-grants' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (select coalesce(g.player_name, p.display_name, 'Jugador sin perfil') as jugador,
                 coalesce(w.name, 'Mundo sin nombre') as mundo, g.level as nivel,
                 g.points_at_request as puntos, g.status as estado, g.created_at, g.used_at
          from prize_grant_requests g left join profiles p on p.id = g.user_id left join worlds w on w.id = g.world_id
          order by g.created_at desc limit least(p_limit, 200)) x;
  else
    raise exception 'Recurso Ops no permitido.';
  end if;
  return v_rows;
end;
$$;

revoke all on function public.ops_table(text, integer) from public;
grant execute on function public.ops_table(text, integer) to authenticated;
