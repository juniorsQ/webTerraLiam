-- Ops backoffice v2: overview with deltas/funnel/alerts, searchable lists with ids,
-- entity detail with relationships, audited mutations (edit / moderate / delete).
-- New function names (ops_overview, ops_list, ops_detail, ops_mutate) so the
-- previous ops_dashboard / ops_table keep working until the web is redeployed.

create table if not exists public.ops_audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  actor_email text,
  action text not null,
  resource text not null,
  target_id text,
  target_label text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists ops_audit_log_created_idx on public.ops_audit_log (created_at desc);
alter table public.ops_audit_log enable row level security;
revoke all on table public.ops_audit_log from public, anon, authenticated;

create or replace function public.ops_assert_admin()
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception using errcode = '42501', message = 'Acceso restringido.';
  end if;
end;
$$;

revoke all on function public.ops_assert_admin() from public;
grant execute on function public.ops_assert_admin() to authenticated;

create or replace function public.ops_is_kid_email(p_email text)
returns boolean
language sql
immutable
as $$
  select coalesce(p_email, '') ilike '%@kid.terraliam.app';
$$;

create or replace function public.ops_log(
  p_action text,
  p_resource text,
  p_target_id text,
  p_label text,
  p_payload jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.ops_audit_log (actor_id, actor_email, action, resource, target_id, target_label, payload)
  values (auth.uid(), auth.jwt() ->> 'email', p_action, p_resource, p_target_id, p_label, coalesce(p_payload, '{}'::jsonb));
$$;

revoke all on function public.ops_log(text, text, text, text, jsonb) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Overview
-- ---------------------------------------------------------------------------
create or replace function public.ops_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_video jsonb;
  v_recraft jsonb;
  v_unit numeric;
  v_budget numeric;
  v_limit integer;
  v_month timestamptz := date_trunc('month', now());
  v_7 timestamptz := now() - interval '7 days';
  v_14 timestamptz := now() - interval '14 days';
  v_30 timestamptz := now() - interval '30 days';
begin
  perform public.ops_assert_admin();

  select coalesce(value, '{}'::jsonb) into v_video from public.platform_settings where key = 'video_policy';
  select coalesce(value, '{}'::jsonb) into v_recraft from public.platform_settings where key = 'recraft_policy';
  v_video := coalesce(v_video, '{}'::jsonb);
  v_recraft := coalesce(v_recraft, '{}'::jsonb);
  v_unit := coalesce((v_video ->> 'unit_cost_usd')::numeric, 0.28);
  v_limit := coalesce((v_video ->> 'max_videos_per_world_per_month')::int, 4);
  v_budget := coalesce((v_video ->> 'monthly_budget_usd')::numeric, v_unit * v_limit);

  return jsonb_build_object(
    'generated_at', now(),
    'video_policy', v_video,
    'recraft_policy', v_recraft,

    'kpis', jsonb_build_object(
      'adults', (
        select jsonb_build_object(
          'total', count(*),
          'd7', count(*) filter (where u.created_at >= v_7),
          'prev7', count(*) filter (where u.created_at >= v_14 and u.created_at < v_7))
        from auth.users u where not public.ops_is_kid_email(u.email)
      ),
      'kids', (
        select jsonb_build_object(
          'total', count(*),
          'd7', count(*) filter (where e.created_at >= v_7),
          'prev7', count(*) filter (where e.created_at >= v_14 and e.created_at < v_7))
        from public.world_explorers e
      ),
      'worlds', (
        select jsonb_build_object(
          'total', count(*),
          'd7', count(*) filter (where w.created_at >= v_7),
          'prev7', count(*) filter (where w.created_at >= v_14 and w.created_at < v_7))
        from public.worlds w
      ),
      'characters', (
        select jsonb_build_object(
          'total', count(*) filter (where poi.active),
          'd7', count(*) filter (where poi.created_at >= v_7),
          'prev7', count(*) filter (where poi.created_at >= v_14 and poi.created_at < v_7))
        from public.pois poi
      ),
      'captures', (
        select jsonb_build_object(
          'total', count(*),
          'd7', count(*) filter (where c.captured_at >= v_7),
          'prev7', count(*) filter (where c.captured_at >= v_14 and c.captured_at < v_7))
        from public.captures c
      ),
      'active_7d', (
        select count(distinct a.uid) from (
          select user_id as uid from public.captures where captured_at >= v_7
          union all select user_id from public.analytics_events where created_at >= v_7 and user_id is not null
          union all select user_id from public.player_progress where updated_at >= v_7
          union all select id from auth.users where last_sign_in_at >= v_7
        ) a
      ),
      'active_30d', (
        select count(distinct a.uid) from (
          select user_id as uid from public.captures where captured_at >= v_30
          union all select user_id from public.analytics_events where created_at >= v_30 and user_id is not null
          union all select user_id from public.player_progress where updated_at >= v_30
          union all select id from auth.users where last_sign_in_at >= v_30
        ) a
      ),
      'kid_accounts', (select count(*) from auth.users u where public.ops_is_kid_email(u.email))
    ),

    'daily', coalesce((
      select jsonb_agg(jsonb_build_object(
        'day', d.day::date,
        'captures', (select count(*) from public.captures c where c.captured_at >= d.day and c.captured_at < d.day + interval '1 day'),
        'characters', (select count(*) from public.pois poi where poi.created_at >= d.day and poi.created_at < d.day + interval '1 day'),
        'accounts', (select count(*) from auth.users u where u.created_at >= d.day and u.created_at < d.day + interval '1 day' and not public.ops_is_kid_email(u.email))
      ) order by d.day)
      from generate_series(date_trunc('day', now()) - interval '29 days', date_trunc('day', now()), interval '1 day') as d(day)
    ), '[]'::jsonb),

    'funnel', (
      with adults as (
        select u.id from auth.users u
        where not public.ops_is_kid_email(u.email)
          and not coalesce((u.raw_app_meta_data ->> 'platform_admin')::boolean, false)
      )
      select jsonb_build_object(
        'accounts', (select count(*) from adults),
        'with_world', (select count(distinct w.created_by) from public.worlds w join adults a on a.id = w.created_by),
        'with_character', (
          select count(distinct w.created_by) from public.worlds w join adults a on a.id = w.created_by
          where exists (select 1 from public.pois poi where poi.world_id = w.id)
        ),
        -- Steps are cumulative so each one is a subset of the previous.
        'with_kid', (
          select count(distinct w.created_by) from public.worlds w join adults a on a.id = w.created_by
          where exists (select 1 from public.pois poi where poi.world_id = w.id)
            and exists (select 1 from public.world_explorers e where e.world_id = w.id)
        ),
        'with_capture', (
          select count(distinct w.created_by) from public.worlds w join adults a on a.id = w.created_by
          where exists (select 1 from public.world_explorers e where e.world_id = w.id)
            and exists (select 1 from public.captures c where c.world_id = w.id)
        )
      )
    ),

    'economy', jsonb_build_object(
      'unit_cost_usd', v_unit,
      'monthly_budget_usd', v_budget,
      'max_videos_per_world_per_month', v_limit,
      'video_spend_month_usd', greatest(
        (select coalesce(sum(cost_usd_est), 0) from public.video_generation_jobs
          where created_at >= v_month and status in ('queued', 'processing', 'completed')),
        (select coalesce(sum(cost_usd_est), 0) from public.provider_jobs
          where provider = 'fal' and created_at >= v_month)
      ),
      'video_spend_total_usd', greatest(
        (select coalesce(sum(cost_usd_est), 0) from public.video_generation_jobs
          where status in ('queued', 'processing', 'completed')),
        (select coalesce(sum(cost_usd_est), 0) from public.provider_jobs where provider = 'fal')
      ),
      'videos_month', greatest(
        (select count(*) from public.video_generation_jobs where created_at >= v_month and status = 'completed'),
        (select count(*) from public.provider_jobs where provider = 'fal' and created_at >= v_month)
      ),
      'videos_total', (select count(*) from public.pois where nullif(anim_video_url, '') is not null),
      'jobs_failed_month', (select count(*) from public.video_generation_jobs where created_at >= v_month and status = 'failed'),
      'jobs_stuck', (
        select count(*) from public.video_generation_jobs
        where status in ('queued', 'processing') and created_at < now() - interval '30 minutes'
      ),
      'recraft_credits_month', (
        select coalesce(sum(credits_est), 0) from public.provider_jobs where provider = 'recraft' and created_at >= v_month
      ),
      'recraft_credits_total', (select coalesce(sum(credits_est), 0) from public.provider_jobs where provider = 'recraft'),
      'recraft_alert_threshold', coalesce((v_recraft ->> 'alert_threshold')::numeric, 200),
      'cutouts', (select count(*) from public.pois where nullif(cutout_image_url, '') is not null),
      'stylized', (select count(*) from public.pois where nullif(stylized_image_url, '') is not null)
    ),

    'attention', jsonb_build_object(
      'pending_prizes', (select count(*) from public.prize_grant_requests where status = 'pending'),
      'open_reports', (select count(*) from public.reports where status = 'open'),
      'failed_jobs_7d', (select count(*) from public.video_generation_jobs where status = 'failed' and created_at >= v_7),
      'stuck_jobs', (
        select count(*) from public.video_generation_jobs
        where status in ('queued', 'processing') and created_at < now() - interval '30 minutes'
      ),
      'orphan_accounts', (
        select count(*) from auth.users u where not exists (select 1 from public.profiles p where p.id = u.id)
      ),
      'adults_without_world', (
        select count(*) from auth.users u
        where not public.ops_is_kid_email(u.email)
          and not exists (select 1 from public.worlds w where w.created_by = u.id)
          and u.created_at < now() - interval '2 days'
      ),
      'worlds_without_characters', (
        select count(*) from public.worlds w where not exists (select 1 from public.pois poi where poi.world_id = w.id)
      ),
      'worlds_without_kids', (
        select count(*) from public.worlds w where not exists (select 1 from public.world_explorers e where e.world_id = w.id)
      ),
      'characters_never_captured', (
        select count(*) from public.pois poi
        where poi.active and not exists (select 1 from public.captures c where c.poi_id = poi.id)
      ),
      'dormant_worlds', (
        select count(*) from public.worlds w
        where w.created_at < v_30
          and not exists (select 1 from public.captures c where c.world_id = w.id and c.captured_at >= v_30)
      )
    ),

    'top_worlds', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.captures_7d desc, x.captures desc, x.name)
      from (
        select
          w.id,
          w.name,
          w.visibility::text as visibility,
          w.created_by as owner_id,
          coalesce(nullif(p.display_name, ''), split_part(coalesce(u.email, ''), '@', 1), 'Sin nombre') as owner,
          (select count(*) from public.world_explorers e where e.world_id = w.id)::int as kids,
          (select count(*) from public.pois poi where poi.world_id = w.id and poi.active)::int as characters,
          (select count(*) from public.captures c where c.world_id = w.id)::int as captures,
          (select count(*) from public.captures c where c.world_id = w.id and c.captured_at >= v_7)::int as captures_7d,
          (select max(c.captured_at) from public.captures c where c.world_id = w.id) as last_capture_at
        from public.worlds w
        left join public.profiles p on p.id = w.created_by
        left join auth.users u on u.id = w.created_by
        order by 9 desc, 8 desc
        limit 8
      ) x
    ), '[]'::jsonb),

    'top_characters', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.captures desc, x.name)
      from (
        select
          poi.id,
          poi.title as name,
          poi.world_id,
          coalesce(w.name, 'Mundo sin nombre') as world,
          coalesce(nullif(poi.rarity, ''), 'common') as rarity,
          (select count(*) from public.captures c where c.poi_id = poi.id)::int as captures,
          nullif(poi.anim_video_url, '') is not null as has_video,
          coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.stylized_image_url, ''), nullif(poi.image_url, '')) as image
        from public.pois poi
        left join public.worlds w on w.id = poi.world_id
        order by 6 desc, poi.created_at desc
        limit 8
      ) x
    ), '[]'::jsonb),

    'rarity', coalesce((
      select jsonb_agg(jsonb_build_object('key', x.rarity, 'count', x.count, 'captures', x.captures) order by x.count desc)
      from (
        select coalesce(nullif(poi.rarity, ''), 'common') as rarity,
               count(*)::int as count,
               coalesce(sum(cc.n), 0)::int as captures
        from public.pois poi
        left join lateral (select count(*) as n from public.captures c where c.poi_id = poi.id) cc on true
        where poi.active
        group by 1
      ) x
    ), '[]'::jsonb),

    'activity', coalesce((
      select jsonb_agg(to_jsonb(f) order by f.at desc)
      from (
        select * from (
          (select 'capture' as kind, c.captured_at as at,
                  coalesce(nullif(p.display_name, ''), 'Jugador') || ' capturó ' || coalesce(poi.title, 'un personaje') as title,
                  coalesce(w.name, 'Mundo sin nombre') as detail,
                  'captures' as resource, c.id::text as target_id,
                  coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.image_url, '')) as image
             from public.captures c
             left join public.profiles p on p.id = c.user_id
             left join public.pois poi on poi.id = c.poi_id
             left join public.worlds w on w.id = c.world_id
            order by c.captured_at desc limit 12)
          union all
          (select 'world', w.created_at, 'Nuevo mundo «' || w.name || '»',
                  'por ' || coalesce(nullif(p.display_name, ''), 'Sin nombre'),
                  'worlds', w.id::text, null::text
             from public.worlds w left join public.profiles p on p.id = w.created_by
            order by w.created_at desc limit 6)
          union all
          (select 'character', poi.created_at, 'Personaje agregado: ' || poi.title,
                  coalesce(w.name, 'Mundo sin nombre'),
                  'pois', poi.id::text,
                  coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.image_url, ''))
             from public.pois poi left join public.worlds w on w.id = poi.world_id
            order by poi.created_at desc limit 6)
          union all
          (select 'account', u.created_at, 'Cuenta nueva: ' || coalesce(nullif(p.display_name, ''), split_part(coalesce(u.email, ''), '@', 1)),
                  'Adulto', 'users', u.id::text, p.avatar_url
             from auth.users u left join public.profiles p on p.id = u.id
            where not public.ops_is_kid_email(u.email)
            order by u.created_at desc limit 6)
          union all
          (select 'prize', g.created_at,
                  coalesce(nullif(g.player_name, ''), 'Jugador') || ' pidió premio (nivel ' || g.level || ')',
                  coalesce(w.name, 'Mundo sin nombre') || ' · ' ||
                    case g.status when 'pending' then 'pendiente' when 'granted' then 'aprobado' else 'negado' end,
                  'prize-grants', g.id::text, null
             from public.prize_grant_requests g left join public.worlds w on w.id = g.world_id
            order by g.created_at desc limit 6)
          union all
          (select 'report', r.created_at, 'Reporte: ' || left(r.reason, 60),
                  coalesce(w.name, 'Sin mundo') || ' · ' ||
                    case r.status when 'open' then 'abierto' when 'reviewed' then 'revisado' else 'descartado' end,
                  'reports', r.id::text, null
             from public.reports r left join public.worlds w on w.id = r.world_id
            order by r.created_at desc limit 6)
        ) all_events
        order by at desc
        limit 20
      ) f
    ), '[]'::jsonb),

    'map_characters', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.world, x.name)
      from (
        select
          poi.id,
          poi.title as name,
          poi.world_id,
          coalesce(w.name, 'Mundo sin nombre') as world,
          coalesce(nullif(author.display_name, ''), nullif(owner.display_name, ''), 'Creador del mundo') as creator,
          coalesce(nullif(poi.rarity, ''), 'common') as rarity,
          poi.active,
          ST_Y(poi.location::geometry) as lat,
          ST_X(poi.location::geometry) as lng,
          coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.image_url, '')) as image,
          (select count(*) from public.captures c where c.poi_id = poi.id)::int as captures,
          coalesce((
            select jsonb_agg(distinct coalesce(nullif(pr.display_name, ''), 'Jugador'))
            from public.captures c left join public.profiles pr on pr.id = c.user_id
            where c.poi_id = poi.id
          ), '[]'::jsonb) as captured_by
        from public.pois poi
        left join public.worlds w on w.id = poi.world_id
        left join public.profiles author on author.id = poi.created_by
        left join public.profiles owner on owner.id = w.created_by
        where poi.location is not null
      ) x
    ), '[]'::jsonb),

    'system', jsonb_build_object(
      'storage_files', (select count(*) from storage.objects where bucket_id = 'poi-media'),
      'storage_bytes', (select coalesce(sum(coalesce((metadata ->> 'size')::bigint, 0)), 0) from storage.objects where bucket_id = 'poi-media'),
      'tokens_active', (select count(*) from public.world_pair_tokens where used_at is null and expires_at > now()),
      'tokens_used', (select count(*) from public.world_pair_tokens where used_at is not null),
      'missions', (select count(*) from public.missions),
      'missions_active', (select count(*) from public.missions where active),
      'analytics_events_7d', (select count(*) from public.analytics_events where created_at >= v_7),
      'admins', (select count(*) from auth.users where coalesce((raw_app_meta_data ->> 'platform_admin')::boolean, false)),
      'audit_7d', (select count(*) from public.ops_audit_log where created_at >= v_7)
    )
  );
end;
$$;

revoke all on function public.ops_overview() from public;
grant execute on function public.ops_overview() to authenticated;

-- ---------------------------------------------------------------------------
-- Lists: { total, rows } with ids for drill-down
-- ---------------------------------------------------------------------------
create or replace function public.ops_list(
  p_resource text,
  p_search text default null,
  p_filter text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_q text := nullif(trim(coalesce(p_search, '')), '');
  v_pat text;
  v_f text := nullif(trim(coalesce(p_filter, '')), '');
  v_limit integer := least(greatest(coalesce(p_limit, 50), 1), 200);
  v_offset integer := greatest(coalesce(p_offset, 0), 0);
  v_rows jsonb;
  v_total bigint;
begin
  perform public.ops_assert_admin();
  v_pat := '%' || coalesce(v_q, '') || '%';

  if p_resource = 'users' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        u.id,
        coalesce(nullif(p.display_name, ''), split_part(coalesce(u.email, ''), '@', 1), 'Sin nombre') as nombre,
        p.avatar_url,
        case when public.ops_is_kid_email(u.email) then null else u.email end as correo,
        case
          when coalesce((u.raw_app_meta_data ->> 'platform_admin')::boolean, false) then 'admin'
          when public.ops_is_kid_email(u.email) then 'kid'
          else 'adult'
        end as tipo,
        coalesce((
          select string_agg(w.name, ', ' order by w.name)
          from public.world_members m join public.worlds w on w.id = m.world_id
          where m.user_id = u.id
        ), '—') as mundos_nombres,
        (select count(*) from public.worlds w where w.created_by = u.id)::int as mundos_creados,
        (select count(*) from public.captures c where c.user_id = u.id)::int as capturas,
        p.id is null as sin_perfil,
        u.last_sign_in_at as ultimo_acceso,
        u.created_at,
        count(*) over () as _total
      from auth.users u
      left join public.profiles p on p.id = u.id
      where (v_q is null or u.email ilike v_pat or p.display_name ilike v_pat or u.id::text = v_q)
        and (
          v_f is null
          or (v_f = 'adult' and not public.ops_is_kid_email(u.email))
          or (v_f = 'kid' and public.ops_is_kid_email(u.email))
          or (v_f = 'admin' and coalesce((u.raw_app_meta_data ->> 'platform_admin')::boolean, false))
          or (v_f = 'never' and u.last_sign_in_at is null)
          or (v_f = 'orphan' and p.id is null)
          or (v_f = 'no_world' and not public.ops_is_kid_email(u.email)
              and not exists (select 1 from public.worlds w where w.created_by = u.id))
        )
      order by u.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'explorers' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        e.id,
        e.nickname as nino,
        e.avatar_url,
        e.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        w.created_by as owner_id,
        coalesce(nullif(owner.display_name, ''), 'Sin nombre') as padre,
        kid.user_id as kid_user_id,
        kid.user_id is not null as emparejado,
        coalesce((select count(*) from public.captures c where c.user_id = kid.user_id and c.world_id = e.world_id), 0)::int as capturas,
        e.created_at,
        count(*) over () as _total
      from public.world_explorers e
      left join public.worlds w on w.id = e.world_id
      left join public.profiles owner on owner.id = w.created_by
      left join lateral (
        select m.user_id from public.world_members m
        join auth.users u on u.id = m.user_id
        where m.world_id = e.world_id and public.ops_is_kid_email(u.email)
          and lower(trim(coalesce(m.nickname, ''))) = lower(trim(e.nickname))
        limit 1
      ) kid on true
      where (v_q is null or e.nickname ilike v_pat or w.name ilike v_pat or owner.display_name ilike v_pat)
        and (v_f is null or (v_f = 'paired' and kid.user_id is not null) or (v_f = 'unpaired' and kid.user_id is null))
      order by e.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'worlds' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        w.id,
        w.name as mundo,
        w.visibility::text as visibilidad,
        w.invite_code as codigo,
        w.created_by as owner_id,
        coalesce(nullif(p.display_name, ''), 'Sin nombre') as padre,
        (select count(*) from public.world_explorers e where e.world_id = w.id)::int as ninos,
        (select count(*) from public.pois poi where poi.world_id = w.id and poi.active)::int as personajes,
        (select count(*) from public.captures c where c.world_id = w.id)::int as capturas,
        (select count(*) from public.captures c where c.world_id = w.id and c.captured_at >= now() - interval '7 days')::int as capturas_7d,
        w.video_rewards_enabled as premios_video,
        (select max(c.captured_at) from public.captures c where c.world_id = w.id) as ultima_captura,
        w.created_at,
        count(*) over () as _total
      from public.worlds w
      left join public.profiles p on p.id = w.created_by
      where (v_q is null or w.name ilike v_pat or p.display_name ilike v_pat or w.invite_code ilike v_pat)
        and (
          v_f is null
          or (v_f = 'public' and w.visibility = 'public')
          or (v_f = 'private' and w.visibility = 'private')
          or (v_f = 'video' and w.video_rewards_enabled)
          or (v_f = 'empty' and not exists (select 1 from public.pois poi where poi.world_id = w.id))
          or (v_f = 'dormant' and w.created_at < now() - interval '30 days'
              and not exists (select 1 from public.captures c where c.world_id = w.id and c.captured_at >= now() - interval '30 days'))
        )
      order by w.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'pois' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        poi.id,
        coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.stylized_image_url, ''), poi.image_url) as imagen,
        poi.title as personaje,
        poi.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        poi.created_by as author_id,
        coalesce(nullif(author.display_name, ''), 'Sin nombre') as agregado_por,
        coalesce(nullif(poi.rarity, ''), 'common') as rareza,
        poi.active as activo,
        (select count(*) from public.captures c where c.poi_id = poi.id)::int as capturas,
        poi.video_prize_enabled as premio_video,
        nullif(poi.anim_video_url, '') is not null as tiene_video,
        poi.created_at,
        count(*) over () as _total
      from public.pois poi
      left join public.worlds w on w.id = poi.world_id
      left join public.profiles author on author.id = poi.created_by
      where (v_q is null or poi.title ilike v_pat or w.name ilike v_pat or poi.character_identity ilike v_pat)
        and (
          v_f is null
          or (v_f in ('common', 'rare', 'epic') and coalesce(nullif(poi.rarity, ''), 'common') = v_f)
          or (v_f = 'inactive' and not poi.active)
          or (v_f = 'never_captured' and poi.active and not exists (select 1 from public.captures c where c.poi_id = poi.id))
          or (v_f = 'video' and nullif(poi.anim_video_url, '') is not null)
        )
      order by poi.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'captures' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.captured_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        c.id,
        c.photo_url as foto,
        c.user_id,
        coalesce(nullif(p.display_name, ''), 'Jugador') as jugador,
        c.poi_id,
        coalesce(poi.title, 'Personaje eliminado') as personaje,
        c.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(nullif(poi.rarity, ''), 'common') as rareza,
        c.captured_at,
        count(*) over () as _total
      from public.captures c
      left join public.profiles p on p.id = c.user_id
      left join public.worlds w on w.id = c.world_id
      left join public.pois poi on poi.id = c.poi_id
      where (v_q is null or p.display_name ilike v_pat or poi.title ilike v_pat or w.name ilike v_pat)
        and (v_f is null or (v_f = '7d' and c.captured_at >= now() - interval '7 days') or (v_f = 'today' and c.captured_at >= date_trunc('day', now())))
      order by c.captured_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'videos' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        poi.id,
        poi.title as personaje,
        poi.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        coalesce(nullif(owner.display_name, ''), 'Sin nombre') as padre,
        poi.anim_video_url as video,
        coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.stylized_image_url, ''), poi.image_url) as poster,
        poi.created_at,
        count(*) over () as _total
      from public.pois poi
      left join public.worlds w on w.id = poi.world_id
      left join public.profiles owner on owner.id = w.created_by
      where nullif(poi.anim_video_url, '') is not null
        and (v_q is null or poi.title ilike v_pat or w.name ilike v_pat)
      order by poi.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'video-jobs' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        j.id,
        j.poi_id,
        coalesce(poi.title, 'Personaje eliminado') as personaje,
        j.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        j.requested_by as user_id,
        coalesce(nullif(p.display_name, ''), 'Sin nombre') as solicitado_por,
        j.status as estado,
        j.cost_usd_est as costo_usd,
        j.error,
        j.created_at,
        j.completed_at,
        count(*) over () as _total
      from public.video_generation_jobs j
      left join public.pois poi on poi.id = j.poi_id
      left join public.worlds w on w.id = j.world_id
      left join public.profiles p on p.id = j.requested_by
      where (v_q is null or poi.title ilike v_pat or w.name ilike v_pat or p.display_name ilike v_pat)
        and (v_f is null or j.status = v_f)
      order by j.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'provider-jobs' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        j.id,
        j.provider as proveedor,
        j.job_type as tipo,
        j.poi_id,
        coalesce(poi.title, 'Personaje eliminado') as personaje,
        j.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        j.cost_usd_est as costo_usd,
        j.credits_est as creditos,
        j.source as origen,
        j.created_at,
        count(*) over () as _total
      from public.provider_jobs j
      left join public.worlds w on w.id = j.world_id
      left join public.pois poi on poi.id = j.poi_id
      where (v_q is null or poi.title ilike v_pat or w.name ilike v_pat or j.job_type ilike v_pat)
        and (v_f is null or j.provider = v_f)
      order by j.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'prize-grants' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        g.id,
        g.user_id,
        coalesce(nullif(g.player_name, ''), nullif(p.display_name, ''), 'Jugador') as jugador,
        g.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        g.level as nivel,
        g.points_at_request as puntos,
        g.status as estado,
        g.used_at,
        g.created_at,
        count(*) over () as _total
      from public.prize_grant_requests g
      left join public.profiles p on p.id = g.user_id
      left join public.worlds w on w.id = g.world_id
      where (v_q is null or g.player_name ilike v_pat or p.display_name ilike v_pat or w.name ilike v_pat)
        and (v_f is null or g.status = v_f)
      order by g.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'progress' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.puntos desc, x.jugador), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        pr.user_id || ':' || pr.world_id as id,
        pr.user_id,
        coalesce(nullif(pr.player_name, ''), nullif(p.display_name, ''), 'Jugador') as jugador,
        pr.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        pr.level as nivel,
        pr.points as puntos,
        pr.capture_count as capturas,
        pr.prize_credits as creditos_premio,
        pr.updated_at,
        count(*) over () as _total
      from public.player_progress pr
      left join public.profiles p on p.id = pr.user_id
      left join public.worlds w on w.id = pr.world_id
      where (v_q is null or pr.player_name ilike v_pat or p.display_name ilike v_pat or w.name ilike v_pat)
        and (v_f is null or (v_f = 'credits' and pr.prize_credits > 0))
      order by pr.points desc, pr.updated_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'storage' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        o.id,
        o.name as archivo,
        coalesce(o.metadata ->> 'mimetype', 'archivo') as tipo,
        coalesce((o.metadata ->> 'size')::bigint, 0) as bytes,
        o.created_at,
        count(*) over () as _total
      from storage.objects o
      where o.bucket_id = 'poi-media'
        and (v_q is null or o.name ilike v_pat)
        and (v_f is null or (v_f = 'image' and o.metadata ->> 'mimetype' ilike 'image/%')
             or (v_f = 'video' and o.metadata ->> 'mimetype' ilike 'video/%'))
      order by o.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'pair-tokens' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        t.id,
        t.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        t.explorer_id,
        coalesce(e.nickname, 'Explorador') as nino,
        case when t.used_at is not null then 'used' when t.expires_at <= now() then 'expired' else 'active' end as estado,
        t.created_at,
        t.expires_at,
        t.used_at,
        count(*) over () as _total
      from public.world_pair_tokens t
      left join public.worlds w on w.id = t.world_id
      left join public.world_explorers e on e.id = t.explorer_id
      where (v_q is null or w.name ilike v_pat or e.nickname ilike v_pat)
        and (
          v_f is null
          or (v_f = 'active' and t.used_at is null and t.expires_at > now())
          or (v_f = 'used' and t.used_at is not null)
          or (v_f = 'expired' and t.used_at is null and t.expires_at <= now())
        )
      order by t.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'missions' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        m.id,
        m.title as mision,
        m.world_id,
        coalesce(w.name, 'Mundo sin nombre') as mundo,
        m.active as activa,
        (select count(*) from public.mission_steps s where s.mission_id = m.id)::int as pasos,
        (select count(*) from public.mission_progress mp where mp.mission_id = m.id and mp.completed_at is not null)::int as completadas,
        m.created_at,
        count(*) over () as _total
      from public.missions m
      left join public.worlds w on w.id = m.world_id
      where (v_q is null or m.title ilike v_pat or w.name ilike v_pat)
        and (v_f is null or (v_f = 'active' and m.active) or (v_f = 'inactive' and not m.active))
      order by m.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'reports' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        r.id,
        r.reason as motivo,
        r.status::text as estado,
        r.poi_id,
        coalesce(poi.title, '—') as personaje,
        r.world_id,
        coalesce(w.name, 'Sin mundo') as mundo,
        r.reporter_id as user_id,
        coalesce(nullif(p.display_name, ''), 'Sin nombre') as reportado_por,
        r.created_at,
        count(*) over () as _total
      from public.reports r
      left join public.worlds w on w.id = r.world_id
      left join public.pois poi on poi.id = r.poi_id
      left join public.profiles p on p.id = r.reporter_id
      where (v_q is null or r.reason ilike v_pat or poi.title ilike v_pat or w.name ilike v_pat)
        and (v_f is null or r.status::text = v_f)
      order by r.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'analytics' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        a.id,
        a.event_name as evento,
        a.world_id,
        coalesce(w.name, '—') as mundo,
        a.user_id,
        coalesce(nullif(p.display_name, ''), '—') as cuenta,
        a.payload as datos,
        a.created_at,
        count(*) over () as _total
      from public.analytics_events a
      left join public.worlds w on w.id = a.world_id
      left join public.profiles p on p.id = a.user_id
      where (v_q is null or a.event_name ilike v_pat or w.name ilike v_pat or p.display_name ilike v_pat)
        and (v_f is null or a.event_name = v_f)
      order by a.created_at desc
      limit v_limit offset v_offset
    ) x;

  elsif p_resource = 'audit' then
    select coalesce(jsonb_agg(to_jsonb(x) - '_total' order by x.created_at desc), '[]'::jsonb), coalesce(max(x._total), 0)
      into v_rows, v_total
    from (
      select
        l.id,
        coalesce(l.actor_email, 'Sistema') as operador,
        l.action as accion,
        l.resource as recurso,
        l.target_id,
        l.target_label as objetivo,
        l.payload as datos,
        l.created_at,
        count(*) over () as _total
      from public.ops_audit_log l
      where (v_q is null or l.target_label ilike v_pat or l.actor_email ilike v_pat or l.action ilike v_pat)
        and (v_f is null or l.resource = v_f)
      order by l.created_at desc
      limit v_limit offset v_offset
    ) x;

  else
    raise exception 'Recurso Ops no permitido: %', p_resource;
  end if;

  return jsonb_build_object('total', v_total, 'rows', v_rows, 'limit', v_limit, 'offset', v_offset);
end;
$$;

revoke all on function public.ops_list(text, text, text, integer, integer) from public;
grant execute on function public.ops_list(text, text, text, integer, integer) to authenticated;

-- ---------------------------------------------------------------------------
-- Detail with relationships
-- ---------------------------------------------------------------------------
create or replace function public.ops_detail(p_resource text, p_id text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid;
  v_result jsonb;
  v_month timestamptz := date_trunc('month', now());
begin
  perform public.ops_assert_admin();
  begin
    v_id := p_id::uuid;
  exception when others then
    raise exception using errcode = '22023', message = 'Identificador inválido.';
  end;

  if p_resource = 'users' then
    select jsonb_build_object(
      'record', jsonb_build_object(
        'id', u.id,
        'display_name', p.display_name,
        'avatar_url', p.avatar_url,
        'email', case when public.ops_is_kid_email(u.email) then null else u.email end,
        'kind', case
          when coalesce((u.raw_app_meta_data ->> 'platform_admin')::boolean, false) then 'admin'
          when public.ops_is_kid_email(u.email) then 'kid' else 'adult' end,
        'has_profile', p.id is not null,
        'provider', u.raw_app_meta_data ->> 'provider',
        'email_confirmed_at', u.email_confirmed_at,
        'last_sign_in_at', u.last_sign_in_at,
        'created_at', u.created_at
      ),
      'stats', jsonb_build_object(
        'worlds_owned', (select count(*) from public.worlds w where w.created_by = u.id),
        'memberships', (select count(*) from public.world_members m where m.user_id = u.id),
        'captures', (select count(*) from public.captures c where c.user_id = u.id),
        'characters_added', (select count(*) from public.pois poi where poi.created_by = u.id),
        'points', (select coalesce(sum(points), 0) from public.player_progress pr where pr.user_id = u.id),
        'prize_requests', (select count(*) from public.prize_grant_requests g where g.user_id = u.id),
        'kids_in_owned_worlds', (
          select count(*) from public.world_explorers e join public.worlds w on w.id = e.world_id where w.created_by = u.id
        )
      ),
      'worlds_owned', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', w.id, 'name', w.name, 'visibility', w.visibility,
          'kids', (select count(*) from public.world_explorers e where e.world_id = w.id),
          'characters', (select count(*) from public.pois poi where poi.world_id = w.id),
          'captures', (select count(*) from public.captures c where c.world_id = w.id),
          'created_at', w.created_at) order by w.created_at desc)
        from public.worlds w where w.created_by = u.id
      ), '[]'::jsonb),
      'memberships', coalesce((
        select jsonb_agg(jsonb_build_object(
          'world_id', w.id, 'name', w.name, 'role', m.role, 'nickname', m.nickname, 'joined_at', m.joined_at)
          order by m.joined_at desc)
        from public.world_members m join public.worlds w on w.id = m.world_id where m.user_id = u.id
      ), '[]'::jsonb),
      'progress', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', pr.user_id || ':' || pr.world_id, 'world_id', pr.world_id, 'world', w.name,
          'level', pr.level, 'points', pr.points, 'captures', pr.capture_count,
          'prize_credits', pr.prize_credits, 'updated_at', pr.updated_at) order by pr.points desc)
        from public.player_progress pr left join public.worlds w on w.id = pr.world_id where pr.user_id = u.id
      ), '[]'::jsonb),
      'captures', coalesce((
        select jsonb_agg(to_jsonb(x) order by x.captured_at desc) from (
          select c.id, c.poi_id, poi.title as character, c.world_id, w.name as world, c.captured_at,
                 coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.image_url, '')) as image
          from public.captures c
          left join public.pois poi on poi.id = c.poi_id
          left join public.worlds w on w.id = c.world_id
          where c.user_id = u.id order by c.captured_at desc limit 30) x
      ), '[]'::jsonb),
      'prizes', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', g.id, 'world_id', g.world_id, 'world', w.name, 'level', g.level, 'points', g.points_at_request,
          'status', g.status, 'used_at', g.used_at, 'created_at', g.created_at) order by g.created_at desc)
        from public.prize_grant_requests g left join public.worlds w on w.id = g.world_id where g.user_id = u.id
      ), '[]'::jsonb)
    ) into v_result
    from auth.users u
    left join public.profiles p on p.id = u.id
    where u.id = v_id;

  elsif p_resource = 'worlds' then
    select jsonb_build_object(
      'record', jsonb_build_object(
        'id', w.id, 'name', w.name, 'invite_code', w.invite_code, 'visibility', w.visibility,
        'video_rewards_enabled', w.video_rewards_enabled, 'created_at', w.created_at
      ),
      'owner', jsonb_build_object(
        'id', w.created_by,
        'name', coalesce(nullif(p.display_name, ''), split_part(coalesce(u.email, ''), '@', 1), 'Sin nombre'),
        'email', u.email,
        'avatar_url', p.avatar_url
      ),
      'stats', jsonb_build_object(
        'members', (select count(*) from public.world_members m where m.world_id = w.id),
        'kids', (select count(*) from public.world_explorers e where e.world_id = w.id),
        'characters', (select count(*) from public.pois poi where poi.world_id = w.id and poi.active),
        'characters_inactive', (select count(*) from public.pois poi where poi.world_id = w.id and not poi.active),
        'captures', (select count(*) from public.captures c where c.world_id = w.id),
        'captures_7d', (select count(*) from public.captures c where c.world_id = w.id and c.captured_at >= now() - interval '7 days'),
        'videos_month', (
          select count(*) from public.video_generation_jobs j
          where j.world_id = w.id and j.created_at >= v_month and j.status in ('queued', 'processing', 'completed')
        ),
        'video_limit', coalesce((select (value ->> 'max_videos_per_world_per_month')::int from public.platform_settings where key = 'video_policy'), 4),
        'pending_prizes', (select count(*) from public.prize_grant_requests g where g.world_id = w.id and g.status = 'pending'),
        'open_reports', (select count(*) from public.reports r where r.world_id = w.id and r.status = 'open'),
        'last_capture_at', (select max(c.captured_at) from public.captures c where c.world_id = w.id)
      ),
      'points_config', (select to_jsonb(cfg) - 'world_id' from public.world_points_config cfg where cfg.world_id = w.id),
      'members', coalesce((
        select jsonb_agg(jsonb_build_object(
          'user_id', m.user_id,
          'name', coalesce(nullif(m.nickname, ''), nullif(mp.display_name, ''), 'Sin nombre'),
          'role', m.role,
          'kind', case when public.ops_is_kid_email(mu.email) then 'kid' else 'adult' end,
          'joined_at', m.joined_at) order by m.role, m.joined_at)
        from public.world_members m
        left join public.profiles mp on mp.id = m.user_id
        left join auth.users mu on mu.id = m.user_id
        where m.world_id = w.id
      ), '[]'::jsonb),
      'kids', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', e.id, 'nickname', e.nickname, 'avatar_url', e.avatar_url, 'created_at', e.created_at,
          'user_id', kid.user_id,
          'captures', coalesce((select count(*) from public.captures c where c.user_id = kid.user_id and c.world_id = w.id), 0)
        ) order by e.created_at)
        from public.world_explorers e
        left join lateral (
          select m.user_id from public.world_members m join auth.users ku on ku.id = m.user_id
          where m.world_id = e.world_id and public.ops_is_kid_email(ku.email)
            and lower(trim(coalesce(m.nickname, ''))) = lower(trim(e.nickname))
          limit 1
        ) kid on true
        where e.world_id = w.id
      ), '[]'::jsonb),
      'characters', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', poi.id, 'title', poi.title, 'rarity', coalesce(nullif(poi.rarity, ''), 'common'), 'active', poi.active,
          'image', coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.stylized_image_url, ''), nullif(poi.image_url, '')),
          'has_video', nullif(poi.anim_video_url, '') is not null,
          'video_prize_enabled', poi.video_prize_enabled,
          'captures', (select count(*) from public.captures c where c.poi_id = poi.id),
          'created_at', poi.created_at) order by poi.created_at desc)
        from public.pois poi where poi.world_id = w.id
      ), '[]'::jsonb),
      'leaderboard', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', pr.user_id || ':' || pr.world_id, 'user_id', pr.user_id,
          'name', coalesce(nullif(pr.player_name, ''), nullif(pp.display_name, ''), 'Jugador'),
          'level', pr.level, 'points', pr.points, 'captures', pr.capture_count, 'prize_credits', pr.prize_credits)
          order by pr.points desc)
        from public.player_progress pr left join public.profiles pp on pp.id = pr.user_id where pr.world_id = w.id
      ), '[]'::jsonb),
      'recent_captures', coalesce((
        select jsonb_agg(to_jsonb(x) order by x.captured_at desc) from (
          select c.id, c.user_id, coalesce(nullif(cp.display_name, ''), 'Jugador') as player,
                 c.poi_id, poi.title as character, c.captured_at,
                 coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.image_url, '')) as image
          from public.captures c
          left join public.profiles cp on cp.id = c.user_id
          left join public.pois poi on poi.id = c.poi_id
          where c.world_id = w.id order by c.captured_at desc limit 20) x
      ), '[]'::jsonb),
      'prizes', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', g.id, 'user_id', g.user_id, 'player', coalesce(nullif(g.player_name, ''), 'Jugador'),
          'level', g.level, 'points', g.points_at_request, 'status', g.status, 'used_at', g.used_at, 'created_at', g.created_at)
          order by g.created_at desc)
        from public.prize_grant_requests g where g.world_id = w.id
      ), '[]'::jsonb),
      'missions', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', m.id, 'title', m.title, 'active', m.active,
          'steps', (select count(*) from public.mission_steps s where s.mission_id = m.id),
          'completed', (select count(*) from public.mission_progress mp where mp.mission_id = m.id and mp.completed_at is not null))
          order by m.created_at desc)
        from public.missions m where m.world_id = w.id
      ), '[]'::jsonb),
      'reports', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', r.id, 'reason', r.reason, 'status', r.status, 'poi_id', r.poi_id, 'character', poi.title, 'created_at', r.created_at)
          order by r.created_at desc)
        from public.reports r left join public.pois poi on poi.id = r.poi_id where r.world_id = w.id
      ), '[]'::jsonb),
      'video_jobs', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', j.id, 'poi_id', j.poi_id, 'character', poi.title, 'status', j.status,
          'cost_usd', j.cost_usd_est, 'error', j.error, 'created_at', j.created_at) order by j.created_at desc)
        from public.video_generation_jobs j left join public.pois poi on poi.id = j.poi_id where j.world_id = w.id
      ), '[]'::jsonb)
    ) into v_result
    from public.worlds w
    left join public.profiles p on p.id = w.created_by
    left join auth.users u on u.id = w.created_by
    where w.id = v_id;

  elsif p_resource = 'pois' then
    select jsonb_build_object(
      'record', jsonb_build_object(
        'id', poi.id, 'title', poi.title, 'body', poi.body, 'rarity', coalesce(nullif(poi.rarity, ''), 'common'),
        'active', poi.active, 'radius_m', poi.radius_m,
        'lat', ST_Y(poi.location::geometry), 'lng', ST_X(poi.location::geometry),
        'image_url', poi.image_url, 'cutout_image_url', poi.cutout_image_url,
        'stylized_image_url', poi.stylized_image_url, 'anim_video_url', poi.anim_video_url,
        'video_prize_enabled', poi.video_prize_enabled,
        'character_identity', poi.character_identity, 'gesture_archetype', poi.gesture_archetype,
        'created_at', poi.created_at
      ),
      'world', jsonb_build_object('id', w.id, 'name', w.name, 'video_rewards_enabled', w.video_rewards_enabled),
      'author', jsonb_build_object('id', poi.created_by, 'name', coalesce(nullif(ap.display_name, ''), 'Sin nombre')),
      'stats', jsonb_build_object(
        'captures', (select count(*) from public.captures c where c.poi_id = poi.id),
        'reports', (select count(*) from public.reports r where r.poi_id = poi.id),
        'missions', (select count(*) from public.mission_steps s where s.poi_id = poi.id),
        'fal_usd', (select coalesce(sum(cost_usd_est), 0) from public.provider_jobs j where j.poi_id = poi.id and j.provider = 'fal'),
        'recraft_credits', (select coalesce(sum(credits_est), 0) from public.provider_jobs j where j.poi_id = poi.id and j.provider = 'recraft')
      ),
      'captures', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', c.id, 'user_id', c.user_id, 'player', coalesce(nullif(cp.display_name, ''), 'Jugador'),
          'photo_url', c.photo_url, 'captured_at', c.captured_at) order by c.captured_at desc)
        from public.captures c left join public.profiles cp on cp.id = c.user_id where c.poi_id = poi.id
      ), '[]'::jsonb),
      'reports', coalesce((
        select jsonb_agg(jsonb_build_object('id', r.id, 'reason', r.reason, 'status', r.status, 'created_at', r.created_at)
          order by r.created_at desc)
        from public.reports r where r.poi_id = poi.id
      ), '[]'::jsonb),
      'jobs', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', j.id, 'provider', j.provider, 'type', j.job_type, 'cost_usd', j.cost_usd_est,
          'credits', j.credits_est, 'created_at', j.created_at) order by j.created_at desc)
        from public.provider_jobs j where j.poi_id = poi.id
      ), '[]'::jsonb)
    ) into v_result
    from public.pois poi
    left join public.worlds w on w.id = poi.world_id
    left join public.profiles ap on ap.id = poi.created_by
    where poi.id = v_id;

  elsif p_resource = 'captures' then
    select jsonb_build_object(
      'record', jsonb_build_object('id', c.id, 'photo_url', c.photo_url, 'captured_at', c.captured_at, 'meta', c.meta),
      'player', jsonb_build_object('id', c.user_id, 'name', coalesce(nullif(cp.display_name, ''), 'Jugador')),
      'character', jsonb_build_object(
        'id', poi.id, 'title', poi.title, 'rarity', coalesce(nullif(poi.rarity, ''), 'common'),
        'image', coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.image_url, ''))),
      'world', jsonb_build_object('id', w.id, 'name', w.name)
    ) into v_result
    from public.captures c
    left join public.profiles cp on cp.id = c.user_id
    left join public.pois poi on poi.id = c.poi_id
    left join public.worlds w on w.id = c.world_id
    where c.id = v_id;

  elsif p_resource = 'explorers' then
    select jsonb_build_object(
      'record', jsonb_build_object('id', e.id, 'nickname', e.nickname, 'avatar_url', e.avatar_url, 'created_at', e.created_at),
      'world', jsonb_build_object('id', w.id, 'name', w.name),
      'owner', jsonb_build_object('id', w.created_by, 'name', coalesce(nullif(op.display_name, ''), 'Sin nombre')),
      'kid_user_id', kid.user_id,
      'stats', jsonb_build_object(
        'captures', coalesce((select count(*) from public.captures c where c.user_id = kid.user_id and c.world_id = e.world_id), 0),
        'points', coalesce((select pr.points from public.player_progress pr where pr.user_id = kid.user_id and pr.world_id = e.world_id), 0),
        'level', coalesce((select pr.level from public.player_progress pr where pr.user_id = kid.user_id and pr.world_id = e.world_id), 0)
      ),
      'captures', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', c.id, 'poi_id', c.poi_id, 'character', poi.title, 'captured_at', c.captured_at,
          'image', coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.image_url, ''))) order by c.captured_at desc)
        from public.captures c left join public.pois poi on poi.id = c.poi_id
        where c.user_id = kid.user_id and c.world_id = e.world_id
      ), '[]'::jsonb),
      'tokens', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', t.id,
          'status', case when t.used_at is not null then 'used' when t.expires_at <= now() then 'expired' else 'active' end,
          'created_at', t.created_at, 'expires_at', t.expires_at, 'used_at', t.used_at) order by t.created_at desc)
        from public.world_pair_tokens t where t.explorer_id = e.id
      ), '[]'::jsonb)
    ) into v_result
    from public.world_explorers e
    left join public.worlds w on w.id = e.world_id
    left join public.profiles op on op.id = w.created_by
    left join lateral (
      select m.user_id from public.world_members m join auth.users ku on ku.id = m.user_id
      where m.world_id = e.world_id and public.ops_is_kid_email(ku.email)
        and lower(trim(coalesce(m.nickname, ''))) = lower(trim(e.nickname))
      limit 1
    ) kid on true
    where e.id = v_id;

  else
    raise exception 'Detalle no disponible para %', p_resource;
  end if;

  if v_result is null then
    raise exception using errcode = 'P0002', message = 'Registro no encontrado.';
  end if;
  return v_result;
end;
$$;

revoke all on function public.ops_detail(text, text) from public;
grant execute on function public.ops_detail(text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Mutations (whitelisted, audited)
-- ---------------------------------------------------------------------------
create or replace function public.ops_mutate(
  p_resource text,
  p_id text,
  p_action text,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_user uuid;
  v_world uuid;
  v_label text;
  v_payload jsonb := coalesce(p_payload, '{}'::jsonb);
  v_count integer;
begin
  perform public.ops_assert_admin();

  if p_resource = 'progress' then
    v_user := split_part(p_id, ':', 1)::uuid;
    v_world := split_part(p_id, ':', 2)::uuid;
  else
    begin
      v_id := p_id::uuid;
    exception when others then
      raise exception using errcode = '22023', message = 'Identificador inválido.';
    end;
  end if;

  -- Worlds ------------------------------------------------------------------
  if p_resource = 'worlds' then
    select name into v_label from public.worlds where id = v_id;
    if v_label is null then raise exception 'Mundo no encontrado.'; end if;
    if p_action = 'update' then
      if v_payload ? 'name' and char_length(trim(v_payload ->> 'name')) < 2 then
        raise exception using errcode = '22023', message = 'El nombre del mundo es muy corto.';
      end if;
      update public.worlds set
        name = coalesce(nullif(trim(v_payload ->> 'name'), ''), name),
        visibility = coalesce((v_payload ->> 'visibility')::public.world_visibility, visibility),
        video_rewards_enabled = coalesce((v_payload ->> 'video_rewards_enabled')::boolean, video_rewards_enabled)
      where id = v_id;
    elsif p_action = 'delete' then
      delete from public.worlds where id = v_id;
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Characters --------------------------------------------------------------
  elsif p_resource in ('pois', 'videos') then
    select title into v_label from public.pois where id = v_id;
    if v_label is null then raise exception 'Personaje no encontrado.'; end if;
    if p_action = 'update' then
      if v_payload ? 'rarity' and v_payload ->> 'rarity' not in ('common', 'rare', 'epic') then
        raise exception using errcode = '22023', message = 'Rareza inválida.';
      end if;
      update public.pois set
        title = coalesce(nullif(trim(v_payload ->> 'title'), ''), title),
        body = case when v_payload ? 'body' then nullif(trim(v_payload ->> 'body'), '') else body end,
        rarity = coalesce(v_payload ->> 'rarity', rarity),
        active = coalesce((v_payload ->> 'active')::boolean, active),
        video_prize_enabled = coalesce((v_payload ->> 'video_prize_enabled')::boolean, video_prize_enabled),
        radius_m = case when v_payload ? 'radius_m'
          then least(greatest((v_payload ->> 'radius_m')::int, 5), 200) else radius_m end
      where id = v_id;
    elsif p_action = 'clear_video' then
      update public.pois set anim_video_url = null where id = v_id;
    elsif p_action = 'delete' then
      delete from public.pois where id = v_id;
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Kid explorers -----------------------------------------------------------
  elsif p_resource = 'explorers' then
    select nickname, world_id into v_label, v_world from public.world_explorers where id = v_id;
    if v_label is null then raise exception 'Explorador no encontrado.'; end if;
    if p_action = 'update' then
      if char_length(trim(coalesce(v_payload ->> 'nickname', ''))) not between 2 and 20 then
        raise exception using errcode = '22023', message = 'El apodo debe tener entre 2 y 20 caracteres.';
      end if;
      -- Keep the kid seat in world_members aligned with the explorer row.
      update public.world_members m set nickname = trim(v_payload ->> 'nickname')
      from auth.users u
      where u.id = m.user_id and m.world_id = v_world and public.ops_is_kid_email(u.email)
        and lower(trim(coalesce(m.nickname, ''))) = lower(trim(v_label));
      update public.world_explorers set nickname = trim(v_payload ->> 'nickname') where id = v_id;
    elsif p_action = 'delete' then
      delete from public.world_explorers where id = v_id;
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Captures ----------------------------------------------------------------
  elsif p_resource = 'captures' then
    select coalesce(poi.title, 'captura') into v_label
    from public.captures c left join public.pois poi on poi.id = c.poi_id where c.id = v_id;
    if v_label is null then raise exception 'Captura no encontrada.'; end if;
    if p_action = 'delete' then
      delete from public.captures where id = v_id;
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Accounts ----------------------------------------------------------------
  elsif p_resource = 'users' then
    select coalesce(nullif(p.display_name, ''), u.email, u.id::text) into v_label
    from auth.users u left join public.profiles p on p.id = u.id where u.id = v_id;
    if v_label is null then raise exception 'Cuenta no encontrada.'; end if;
    if p_action = 'update' then
      if char_length(trim(coalesce(v_payload ->> 'display_name', ''))) < 2 then
        raise exception using errcode = '22023', message = 'El nombre es muy corto.';
      end if;
      insert into public.profiles (id, display_name)
      values (v_id, trim(v_payload ->> 'display_name'))
      on conflict (id) do update set display_name = excluded.display_name;
    elsif p_action = 'delete' then
      if v_id = auth.uid() then
        raise exception using errcode = '42501', message = 'No puedes eliminar tu propia cuenta desde Ops.';
      end if;
      if exists (select 1 from auth.users where id = v_id and coalesce((raw_app_meta_data ->> 'platform_admin')::boolean, false)) then
        raise exception using errcode = '42501', message = 'No se puede eliminar a otro platform admin.';
      end if;
      select count(*) into v_count from public.worlds where created_by = v_id;
      v_payload := v_payload || jsonb_build_object('worlds_deleted', v_count);
      -- These FKs have no ON DELETE rule; detach them so the account delete is not blocked.
      update public.world_explorers set created_by = null where created_by = v_id;
      update public.world_pair_tokens set created_by = null where created_by = v_id;
      delete from auth.users where id = v_id;
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Prize requests ----------------------------------------------------------
  elsif p_resource = 'prize-grants' then
    select coalesce(nullif(player_name, ''), 'Jugador') || ' · nivel ' || level into v_label
    from public.prize_grant_requests where id = v_id;
    if v_label is null then raise exception 'Solicitud no encontrada.'; end if;
    if p_action in ('grant', 'deny') then
      update public.prize_grant_requests
      set status = case when p_action = 'grant' then 'granted' else 'denied' end
      where id = v_id and used_at is null;
      get diagnostics v_count = row_count;
      if v_count = 0 then raise exception 'Este premio ya fue usado y no se puede cambiar.'; end if;
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Reports -----------------------------------------------------------------
  elsif p_resource = 'reports' then
    select left(reason, 60) into v_label from public.reports where id = v_id;
    if v_label is null then raise exception 'Reporte no encontrado.'; end if;
    if p_action = 'review' then
      update public.reports set status = 'reviewed' where id = v_id;
    elsif p_action = 'dismiss' then
      update public.reports set status = 'dismissed' where id = v_id;
    elsif p_action = 'reopen' then
      update public.reports set status = 'open' where id = v_id;
    elsif p_action = 'hide_character' then
      update public.pois set active = false where id = (select poi_id from public.reports where id = v_id);
      update public.reports set status = 'reviewed' where id = v_id;
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Pair tokens -------------------------------------------------------------
  elsif p_resource = 'pair-tokens' then
    select coalesce(e.nickname, 'token') into v_label
    from public.world_pair_tokens t left join public.world_explorers e on e.id = t.explorer_id where t.id = v_id;
    if v_label is null then raise exception 'Token no encontrado.'; end if;
    if p_action = 'revoke' then
      update public.world_pair_tokens set expires_at = now() where id = v_id and used_at is null and expires_at > now();
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Missions ----------------------------------------------------------------
  elsif p_resource = 'missions' then
    select title into v_label from public.missions where id = v_id;
    if v_label is null then raise exception 'Misión no encontrada.'; end if;
    if p_action = 'update' then
      update public.missions set
        title = coalesce(nullif(trim(v_payload ->> 'title'), ''), title),
        active = coalesce((v_payload ->> 'active')::boolean, active)
      where id = v_id;
    elsif p_action = 'delete' then
      delete from public.missions where id = v_id;
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Player progress ---------------------------------------------------------
  elsif p_resource = 'progress' then
    select coalesce(nullif(player_name, ''), 'Jugador') into v_label
    from public.player_progress where user_id = v_user and world_id = v_world;
    if v_label is null then raise exception 'Progreso no encontrado.'; end if;
    if p_action = 'update' then
      if coalesce((v_payload ->> 'prize_credits')::int, 0) < 0
        or coalesce((v_payload ->> 'points')::int, 0) < 0
        or coalesce((v_payload ->> 'level')::int, 0) < 0 then
        raise exception using errcode = '22023', message = 'Los valores no pueden ser negativos.';
      end if;
      update public.player_progress set
        prize_credits = coalesce((v_payload ->> 'prize_credits')::int, prize_credits),
        points = coalesce((v_payload ->> 'points')::int, points),
        level = coalesce((v_payload ->> 'level')::int, level),
        updated_at = now()
      where user_id = v_user and world_id = v_world;
    else
      raise exception 'Acción no permitida.';
    end if;

  -- Video jobs --------------------------------------------------------------
  elsif p_resource = 'video-jobs' then
    select coalesce(poi.title, 'job') into v_label
    from public.video_generation_jobs j left join public.pois poi on poi.id = j.poi_id where j.id = v_id;
    if v_label is null then raise exception 'Job no encontrado.'; end if;
    if p_action = 'cancel' then
      update public.video_generation_jobs
      set status = 'cancelled', completed_at = now(), error = coalesce(error, 'Cancelado desde Ops')
      where id = v_id and status in ('queued', 'processing');
    else
      raise exception 'Acción no permitida.';
    end if;

  else
    raise exception 'Recurso no editable: %', p_resource;
  end if;

  perform public.ops_log(p_action, p_resource, p_id, v_label, v_payload);
  return jsonb_build_object('ok', true, 'resource', p_resource, 'id', p_id, 'action', p_action);
end;
$$;

revoke all on function public.ops_mutate(text, text, text, jsonb) from public;
grant execute on function public.ops_mutate(text, text, text, jsonb) to authenticated;

-- Settings changes are audited too.
create or replace function public.ops_update_settings_audited(p_key text, p_value jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_value jsonb;
begin
  v_value := public.ops_update_settings(p_key, p_value);
  perform public.ops_log('update', 'settings', p_key, p_key, v_value);
  return v_value;
end;
$$;

revoke all on function public.ops_update_settings_audited(text, jsonb) from public;
grant execute on function public.ops_update_settings_audited(text, jsonb) to authenticated;
