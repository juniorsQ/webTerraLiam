-- Extend Ops dashboard and tables with storage, auth, tokens, jobs, and product queues.

create or replace function public.ops_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_result jsonb;
  v_unit numeric;
  v_budget numeric;
  v_video jsonb;
  v_recraft jsonb;
begin
  if not public.is_platform_admin() then
    raise exception using errcode = '42501', message = 'Acceso restringido.';
  end if;

  select coalesce(value, '{}'::jsonb) into v_video
  from public.platform_settings where key = 'video_policy';
  select coalesce(value, '{}'::jsonb) into v_recraft
  from public.platform_settings where key = 'recraft_policy';
  v_unit := coalesce((v_video ->> 'unit_cost_usd')::numeric, 0.28);
  v_budget := coalesce((v_video ->> 'monthly_budget_usd')::numeric, v_unit * 4);

  select jsonb_build_object(
    'users', (select count(*) from public.profiles),
    'users_7d', (select count(*) from public.profiles where created_at >= now() - interval '7 days'),
    'worlds', (select count(*) from public.worlds),
    'explorers', (select count(*) from public.world_explorers),
    'characters', (select count(*) from public.pois where active),
    'captures', (select count(*) from public.captures),
    'captures_7d', (select count(*) from public.captures where captured_at >= now() - interval '7 days'),
    'videos', (select count(*) from public.pois where anim_video_url is not null),
    'video_jobs', (select count(*) from public.video_generation_jobs),
    'video_spend_usd', (
      select coalesce(sum(cost_usd_est), 0)
      from public.video_generation_jobs
      where status in ('queued', 'processing', 'completed')
    ),
    'pending_prizes', (select count(*) from public.prize_grant_requests where status = 'pending'),
    'video_policy', v_video,
    'recraft_policy', v_recraft,
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
      select jsonb_agg(jsonb_build_object('world', x.name, 'captures', x.captures, 'characters', x.characters) order by x.captures desc, x.name)
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
          coalesce(nullif(p.display_name, ''), 'Creador del mundo') as parent,
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
          coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.stylized_image_url, ''), nullif(poi.image_url, '')) as image
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
          coalesce(nullif(p.display_name, ''), 'Jugador') as player,
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
          coalesce(nullif(p.display_name, ''), 'Creador del mundo') as parent,
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
    ), '[]'::jsonb),
    'map_characters', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.world, x.name)
      from (
        select
          poi.id,
          poi.title as name,
          coalesce(w.name, 'Mundo sin nombre') as world,
          coalesce(nullif(author.display_name, ''), nullif(owner.display_name, ''), 'Creador del mundo') as creator,
          coalesce(poi.rarity, 'common') as rarity,
          ST_Y(poi.location::geometry) as lat,
          ST_X(poi.location::geometry) as lng,
          coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.image_url, '')) as image,
          (select count(*) from public.captures c where c.poi_id = poi.id)::int as captures,
          coalesce((
            select jsonb_agg(distinct coalesce(nullif(pr.display_name, ''), 'Jugador'))
            from public.captures c
            left join public.profiles pr on pr.id = c.user_id
            where c.poi_id = poi.id
          ), '[]'::jsonb) as captured_by
        from public.pois poi
        left join public.worlds w on w.id = poi.world_id
        left join public.profiles author on author.id = poi.created_by
        left join public.profiles owner on owner.id = w.created_by
        where poi.location is not null
      ) x
    ), '[]'::jsonb),
    'providers', jsonb_build_object(
      'fal', jsonb_build_object(
        'unit_cost_usd', v_unit,
        'monthly_budget_usd', v_budget,
        'max_videos_per_world_per_month', coalesce((v_video ->> 'max_videos_per_world_per_month')::int, 4),
        'videos', (select count(*) from public.pois where anim_video_url is not null),
        'jobs', (select count(*) from public.provider_jobs where provider = 'fal'),
        'job_spend_usd', (
          select coalesce(sum(cost_usd_est), 0)
          from public.video_generation_jobs
          where status in ('queued', 'processing', 'completed')
        ),
        'estimated_used_usd', greatest(
          coalesce((select sum(cost_usd_est) from public.video_generation_jobs where status in ('queued', 'processing', 'completed')), 0),
          (select count(*) from public.pois where anim_video_url is not null) * v_unit
        )
      ),
      'recraft', jsonb_build_object(
        'cutouts', (select count(*) from public.pois where nullif(cutout_image_url, '') is not null),
        'stylized', (select count(*) from public.pois where nullif(stylized_image_url, '') is not null),
        'jobs', (select count(*) from public.provider_jobs where provider = 'recraft'),
        'used_credits', (
          select coalesce(sum(credits_est), 0) from public.provider_jobs where provider = 'recraft'
        ),
        'alert_threshold', coalesce((v_recraft ->> 'alert_threshold')::numeric, 200)
      )
    ),
    'storage', jsonb_build_object(
      'bucket', 'poi-media',
      'files', (select count(*) from storage.objects where bucket_id = 'poi-media'),
      'bytes', (select coalesce(sum(coalesce((metadata ->> 'size')::bigint, 0)), 0) from storage.objects where bucket_id = 'poi-media')
    ),
    'auth', jsonb_build_object(
      'accounts', (select count(*) from auth.users),
      'admins', (select count(*) from auth.users where coalesce((raw_app_meta_data ->> 'platform_admin')::boolean, false)),
      'signed_7d', (select count(*) from auth.users where last_sign_in_at >= now() - interval '7 days'),
      'never_signed', (select count(*) from auth.users where last_sign_in_at is null),
      'orphans', (
        select count(*) from auth.users u
        where not exists (select 1 from public.profiles p where p.id = u.id)
      )
    ),
    'pair_tokens', jsonb_build_object(
      'total', (select count(*) from public.world_pair_tokens),
      'active', (select count(*) from public.world_pair_tokens where used_at is null and expires_at > now()),
      'used', (select count(*) from public.world_pair_tokens where used_at is not null),
      'expired', (select count(*) from public.world_pair_tokens where used_at is null and expires_at <= now())
    ),
    'progress', jsonb_build_object(
      'rows', (select count(*) from public.player_progress),
      'players', (select count(distinct user_id) from public.player_progress)
    ),
    'prizes', jsonb_build_object(
      'total', (select count(*) from public.prize_grant_requests),
      'pending', (select count(*) from public.prize_grant_requests where status = 'pending')
    ),
    'reports', jsonb_build_object(
      'total', (select count(*) from public.reports),
      'open', (select count(*) from public.reports where status::text in ('open', 'pending', 'new'))
    ),
    'analytics', jsonb_build_object(
      'events', (select count(*) from public.analytics_events)
    ),
    'missions', jsonb_build_object(
      'missions', (select count(*) from public.missions),
      'steps', (select count(*) from public.mission_steps),
      'progress', (select count(*) from public.mission_progress)
    ),
    'maps', jsonb_build_object(
      'pins', (select count(*) from public.pois where location is not null),
      'worlds', (select count(distinct world_id) from public.pois where location is not null)
    )
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
        coalesce(nullif(p.display_name, ''), split_part(coalesce(u.email, ''), '@', 1), 'Sin nombre') as nombre,
        p.avatar_url,
        case
          when coalesce((u.raw_app_meta_data ->> 'platform_admin')::boolean, false) then 'Admin'
          when exists (select 1 from public.worlds w where w.created_by = p.id) then 'Creador'
          else 'Jugador'
        end as rol,
        coalesce((select count(*) from public.worlds w where w.created_by = p.id), 0) as mundos_creados,
        coalesce((select count(*) from public.world_explorers e where e.created_by = p.id), 0) as ninos_representados,
        u.email as correo,
        u.last_sign_in_at as ultimo_acceso,
        p.created_at
      from public.profiles p
      left join auth.users u on u.id = p.id
      order by p.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'explorers' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        e.nickname as nino,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(nullif(p.display_name, ''), nullif(owner.display_name, ''), 'Creador del mundo') as agregado_por,
        e.avatar_url,
        e.created_at
      from public.world_explorers e
      left join public.worlds w on w.id = e.world_id
      left join public.profiles p on p.id = e.created_by
      left join public.profiles owner on owner.id = w.created_by
      order by e.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'worlds' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        w.name as mundo,
        w.visibility as visibilidad,
        coalesce(nullif(p.display_name, ''), 'Creador del mundo') as padre,
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
        coalesce(nullif(author.display_name, ''), nullif(owner.display_name, ''), 'Creador del mundo') as agregado_por,
        poi.rarity as rareza,
        poi.active as activo,
        coalesce((select count(*) from public.captures c where c.poi_id = poi.id), 0) as capturas,
        coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.stylized_image_url, ''), poi.image_url) as imagen,
        poi.video_prize_enabled as premio_video,
        poi.created_at
      from public.pois poi
      left join public.worlds w on w.id = poi.world_id
      left join public.profiles author on author.id = poi.created_by
      left join public.profiles owner on owner.id = w.created_by
      order by poi.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'captures' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.captured_at desc), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(nullif(p.display_name, ''), 'Jugador') as jugador,
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
  elsif p_resource in ('video-spend', 'provider-jobs') then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        j.provider as proveedor,
        j.job_type as tipo,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(poi.title, 'Personaje sin nombre') as personaje,
        j.status as estado,
        j.cost_usd_est as costo_usd,
        j.credits_est as creditos,
        j.source as origen,
        j.created_at
      from public.provider_jobs j
      left join public.worlds w on w.id = j.world_id
      left join public.pois poi on poi.id = j.poi_id
      order by j.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'prize-grants' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(nullif(g.player_name, ''), nullif(p.display_name, ''), 'Jugador') as jugador,
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
  elsif p_resource = 'storage' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        o.name as archivo,
        coalesce(o.metadata ->> 'mimetype', 'archivo') as tipo,
        coalesce((o.metadata ->> 'size')::bigint, 0) as bytes,
        o.created_at
      from storage.objects o
      where o.bucket_id = 'poi-media'
      order by o.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'pair-tokens' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(e.nickname, 'Explorador') as nino,
        case
          when t.used_at is not null then 'used'
          when t.expires_at <= now() then 'expired'
          else 'active'
        end as estado,
        t.created_at,
        t.expires_at,
        t.used_at
      from public.world_pair_tokens t
      left join public.worlds w on w.id = t.world_id
      left join public.world_explorers e on e.id = t.explorer_id
      order by t.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'progress' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.puntos desc, x.jugador), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(nullif(pr.player_name, ''), nullif(p.display_name, ''), 'Jugador') as jugador,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        pr.level as nivel,
        pr.points as puntos,
        pr.capture_count as capturas,
        pr.prize_credits as creditos_premio,
        pr.updated_at
      from public.player_progress pr
      left join public.profiles p on p.id = pr.user_id
      left join public.worlds w on w.id = pr.world_id
      order by pr.points desc, pr.updated_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'missions' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        m.title as mision,
        m.active as activa,
        coalesce((select count(*) from public.mission_steps s where s.mission_id = m.id), 0) as pasos,
        m.created_at
      from public.missions m
      left join public.worlds w on w.id = m.world_id
      order by m.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'reports' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(poi.title, 'Personaje sin nombre') as personaje,
        coalesce(nullif(p.display_name, ''), 'Reportante') as reportado_por,
        r.reason as motivo,
        r.status::text as estado,
        r.created_at
      from public.reports r
      left join public.worlds w on w.id = r.world_id
      left join public.pois poi on poi.id = r.poi_id
      left join public.profiles p on p.id = r.reporter_id
      order by r.created_at desc
      limit least(p_limit, 200)
    ) x;
  elsif p_resource = 'analytics' then
    select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb) into v_rows
    from (
      select
        a.event_name as evento,
        coalesce(w.name, 'Sin mundo') as mundo,
        coalesce(nullif(p.display_name, ''), 'Cuenta') as cuenta,
        a.created_at
      from public.analytics_events a
      left join public.worlds w on w.id = a.world_id
      left join public.profiles p on p.id = a.user_id
      order by a.created_at desc
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
