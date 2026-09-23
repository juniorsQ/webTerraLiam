-- Ops dashboard: human-readable relationships, charts, and character cards.
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
    'worlds', (select count(*) from public.worlds),
    'explorers', (select count(*) from public.world_explorers),
    'characters', (select count(*) from public.pois where active),
    'captures', (select count(*) from public.captures),
    'captures_7d', (select count(*) from public.captures where captured_at >= now() - interval '7 days'),
    'videos', (select count(*) from public.video_generation_jobs where status = 'completed'),
    'video_spend_usd', (
      select coalesce(sum(cost_usd_est), 0)
      from public.video_generation_jobs
      where status in ('queued', 'processing', 'completed')
    ),
    'pending_prizes', (select count(*) from public.prize_grant_requests where status = 'pending'),
    'captures_by_week', coalesce((
      select jsonb_agg(jsonb_build_object('week', x.week, 'count', x.count) order by x.week)
      from (
        select gs.week::date as week, coalesce(c.n, 0)::int as count
        from generate_series(
          date_trunc('week', now()) - interval '7 weeks',
          date_trunc('week', now()),
          interval '1 week'
        ) as gs(week)
        left join (
          select date_trunc('week', captured_at) as week, count(*) as n
          from public.captures
          group by 1
        ) c on c.week = gs.week
      ) x
    ), '[]'::jsonb),
    'rarity', coalesce((
      select jsonb_agg(jsonb_build_object('key', x.rarity, 'count', x.count) order by x.count desc)
      from (
        select coalesce(nullif(rarity, ''), 'common') as rarity, count(*)::int as count
        from public.pois
        where active
        group by 1
      ) x
    ), '[]'::jsonb),
    'captures_by_world', coalesce((
      select jsonb_agg(jsonb_build_object(
        'world', x.name,
        'captures', x.captures,
        'characters', x.characters
      ) order by x.captures desc, x.name)
      from (
        select
          w.name,
          (select count(*) from public.captures c where c.world_id = w.id)::int as captures,
          (select count(*) from public.pois poi where poi.world_id = w.id)::int as characters
        from public.worlds w
      ) x
    ), '[]'::jsonb),
    'families', coalesce((
      select jsonb_agg(to_jsonb(f) order by f.world_count desc, f.parent)
      from (
        select
          p.id,
          coalesce(nullif(p.display_name, ''), 'Cuenta sin perfil') as parent,
          (select count(*) from public.worlds w where w.created_by = p.id)::int as world_count,
          coalesce((
            select jsonb_agg(to_jsonb(ww) order by ww.captures desc, ww.name)
            from (
              select
                w.name,
                w.visibility,
                coalesce((
                  select jsonb_agg(e.nickname order by e.created_at)
                  from public.world_explorers e
                  where e.world_id = w.id
                ), '[]'::jsonb) as kids,
                (select count(*) from public.pois poi where poi.world_id = w.id)::int as characters,
                (select count(*) from public.captures c where c.world_id = w.id)::int as captures
              from public.worlds w
              where w.created_by = p.id
            ) ww
          ), '[]'::jsonb) as worlds
        from public.profiles p
        where exists (select 1 from public.worlds w where w.created_by = p.id)
      ) f
    ), '[]'::jsonb),
    'top_characters', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.captures desc, x.name)
      from (
        select
          poi.title as name,
          coalesce(w.name, 'Mundo sin nombre') as world,
          coalesce(poi.rarity, 'common') as rarity,
          (select count(*) from public.captures c where c.poi_id = poi.id)::int as captures,
          coalesce(
            nullif(poi.cutout_image_url, ''),
            nullif(poi.stylized_image_url, ''),
            nullif(poi.image_url, '')
          ) as image
        from public.pois poi
        left join public.worlds w on w.id = poi.world_id
        order by 4 desc, poi.title
        limit 8
      ) x
    ), '[]'::jsonb),
    'recent_captures', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.captured_at desc)
      from (
        select
          coalesce(nullif(p.display_name, ''), 'Jugador sin perfil') as player,
          coalesce(w.name, 'Mundo sin nombre') as world,
          coalesce(poi.title, 'Personaje sin nombre') as character_name,
          coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.image_url, '')) as image,
          c.captured_at
        from public.captures c
        left join public.profiles p on p.id = c.user_id
        left join public.worlds w on w.id = c.world_id
        left join public.pois poi on poi.id = c.poi_id
        order by c.captured_at desc
        limit 8
      ) x
    ), '[]'::jsonb),
    'recent_worlds', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.created_at desc)
      from (
        select
          w.name,
          w.visibility,
          w.created_at,
          coalesce(nullif(p.display_name, ''), 'Cuenta sin perfil') as parent,
          coalesce((
            select string_agg(e.nickname, ', ' order by e.created_at)
            from public.world_explorers e
            where e.world_id = w.id
          ), 'Sin niños') as kids
        from public.worlds w
        left join public.profiles p on p.id = w.created_by
        order by w.created_at desc
        limit 8
      ) x
    ), '[]'::jsonb)
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
declare
  v_rows jsonb;
begin
  if not public.is_platform_admin() then
    raise exception using errcode = '42501', message = 'Acceso restringido.';
  end if;

  if p_resource = 'users' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(nullif(p.display_name, ''), 'Cuenta sin nombre') as nombre,
        p.avatar_url,
        case
          when exists (select 1 from public.worlds w where w.created_by = p.id) then 'Creador'
          else 'Jugador'
        end as rol,
        coalesce((select count(*) from public.worlds w where w.created_by = p.id), 0) as mundos_creados,
        coalesce((select count(*) from public.world_explorers e where e.created_by = p.id), 0) as ninos_representados,
        p.created_at
      from public.profiles p
      order by p.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'explorers' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        e.nickname as nino,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(nullif(p.display_name, ''), 'Cuenta sin perfil') as creado_por,
        e.avatar_url,
        e.created_at
      from public.world_explorers e
      left join public.worlds w on w.id = e.world_id
      left join public.profiles p on p.id = e.created_by
      order by e.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'worlds' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        w.name as mundo,
        w.visibility as visibilidad,
        coalesce(nullif(p.display_name, ''), 'Cuenta sin perfil') as padre,
        coalesce((
          select string_agg(e.nickname, ', ' order by e.created_at)
          from public.world_explorers e
          where e.world_id = w.id
        ), 'Sin niños') as ninos,
        coalesce((select count(*) from public.world_members m where m.world_id = w.id), 0) as miembros,
        coalesce((select count(*) from public.pois poi where poi.world_id = w.id), 0) as personajes,
        coalesce((select count(*) from public.captures c where c.world_id = w.id), 0) as capturas,
        w.video_rewards_enabled as premios_video,
        w.created_at
      from public.worlds w
      left join public.profiles p on p.id = w.created_by
      order by w.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'pois' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        poi.title as personaje,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(nullif(p.display_name, ''), 'Cuenta sin perfil') as creado_por,
        poi.rarity as rareza,
        poi.active as activo,
        coalesce((select count(*) from public.captures c where c.poi_id = poi.id), 0) as capturas,
        coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.stylized_image_url, ''), poi.image_url) as imagen,
        poi.video_prize_enabled as premio_video,
        poi.created_at
      from public.pois poi
      left join public.worlds w on w.id = poi.world_id
      left join public.profiles p on p.id = poi.created_by
      order by poi.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'captures' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.captured_at desc), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(nullif(p.display_name, ''), 'Jugador sin perfil') as jugador,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(poi.title, 'Personaje sin nombre') as personaje,
        c.photo_url,
        c.captured_at
      from public.captures c
      left join public.profiles p on p.id = c.user_id
      left join public.worlds w on w.id = c.world_id
      left join public.pois poi on poi.id = c.poi_id
      order by c.captured_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'video-spend' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(poi.title, 'Personaje sin nombre') as personaje,
        coalesce(nullif(p.display_name, ''), 'Cuenta sin perfil') as solicitado_por,
        j.status as estado,
        j.cost_usd_est as costo_usd,
        j.created_at,
        j.completed_at,
        j.error
      from public.video_generation_jobs j
      left join public.worlds w on w.id = j.world_id
      left join public.pois poi on poi.id = j.poi_id
      left join public.profiles p on p.id = j.requested_by
      order by j.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'prize-grants' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(nullif(g.player_name, ''), nullif(p.display_name, ''), 'Jugador sin perfil') as jugador,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        g.level as nivel,
        g.points_at_request as puntos,
        g.status as estado,
        g.created_at,
        g.used_at
      from public.prize_grant_requests g
      left join public.profiles p on p.id = g.user_id
      left join public.worlds w on w.id = g.world_id
      order by g.created_at desc
      limit least(p_limit, 200)
    ) x;
  else
    raise exception 'Recurso Ops no permitido.';
  end if;

  return v_rows;
end;
$$;

revoke all on function public.ops_table(text, integer) from public;
grant execute on function public.ops_table(text, integer) to authenticated;
