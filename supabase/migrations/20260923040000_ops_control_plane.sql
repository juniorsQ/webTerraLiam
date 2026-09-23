-- Ops control plane: editable policies, provider job ledger, storage/auth/token metrics.

update public.platform_settings
set value = value || '{"monthly_budget_usd": 1.12}'::jsonb
where key = 'video_policy'
  and coalesce(value ? 'monthly_budget_usd', false) = false;

insert into public.platform_settings (key, value)
values (
  'recraft_policy',
  '{"cutout_cost_credits": 1, "stylized_cost_credits": 2, "alert_threshold": 200}'::jsonb
)
on conflict (key) do nothing;

create table if not exists public.provider_jobs (
  id uuid primary key default gen_random_uuid(),
  provider text not null check (provider in ('fal', 'recraft')),
  job_type text not null,
  world_id uuid references public.worlds(id) on delete set null,
  poi_id uuid references public.pois(id) on delete set null,
  status text not null default 'completed',
  cost_usd_est numeric(10, 4),
  credits_est numeric(10, 2),
  result_url text,
  source text not null default 'backfill',
  created_at timestamptz not null default now()
);

create index if not exists provider_jobs_provider_created_idx
  on public.provider_jobs (provider, created_at desc);

alter table public.provider_jobs enable row level security;
revoke all on table public.provider_jobs from public, anon, authenticated;

insert into public.provider_jobs (provider, job_type, world_id, poi_id, status, cost_usd_est, result_url, source, created_at)
select 'fal', 'video', poi.world_id, poi.id, 'completed', 0.28, poi.anim_video_url, 'backfill', poi.created_at
from public.pois poi
where nullif(poi.anim_video_url, '') is not null
  and not exists (
    select 1 from public.provider_jobs j
    where j.poi_id = poi.id and j.provider = 'fal' and j.job_type = 'video'
  );

insert into public.provider_jobs (provider, job_type, world_id, poi_id, status, credits_est, result_url, source, created_at)
select 'recraft', 'cutout', poi.world_id, poi.id, 'completed', 1, poi.cutout_image_url, 'backfill', poi.created_at
from public.pois poi
where nullif(poi.cutout_image_url, '') is not null
  and not exists (
    select 1 from public.provider_jobs j
    where j.poi_id = poi.id and j.provider = 'recraft' and j.job_type = 'cutout'
  );

insert into public.provider_jobs (provider, job_type, world_id, poi_id, status, credits_est, result_url, source, created_at)
select 'recraft', 'stylized', poi.world_id, poi.id, 'completed', 2, poi.stylized_image_url, 'backfill', poi.created_at
from public.pois poi
where nullif(poi.stylized_image_url, '') is not null
  and not exists (
    select 1 from public.provider_jobs j
    where j.poi_id = poi.id and j.provider = 'recraft' and j.job_type = 'stylized'
  );

create or replace function public.provider_jobs_from_poi()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_unit numeric := 0.28;
  v_cutout numeric := 1;
  v_style numeric := 2;
begin
  select coalesce((value ->> 'unit_cost_usd')::numeric, 0.28) into v_unit
  from public.platform_settings where key = 'video_policy';
  select coalesce((value ->> 'cutout_cost_credits')::numeric, 1),
         coalesce((value ->> 'stylized_cost_credits')::numeric, 2)
    into v_cutout, v_style
  from public.platform_settings where key = 'recraft_policy';

  if tg_op = 'INSERT' or new.anim_video_url is distinct from old.anim_video_url then
    if nullif(new.anim_video_url, '') is not null then
      insert into public.provider_jobs (provider, job_type, world_id, poi_id, status, cost_usd_est, result_url, source)
      values ('fal', 'video', new.world_id, new.id, 'completed', v_unit, new.anim_video_url, 'live');
    end if;
  end if;
  if tg_op = 'INSERT' or new.cutout_image_url is distinct from old.cutout_image_url then
    if nullif(new.cutout_image_url, '') is not null then
      insert into public.provider_jobs (provider, job_type, world_id, poi_id, status, credits_est, result_url, source)
      values ('recraft', 'cutout', new.world_id, new.id, 'completed', v_cutout, new.cutout_image_url, 'live');
    end if;
  end if;
  if tg_op = 'INSERT' or new.stylized_image_url is distinct from old.stylized_image_url then
    if nullif(new.stylized_image_url, '') is not null then
      insert into public.provider_jobs (provider, job_type, world_id, poi_id, status, credits_est, result_url, source)
      values ('recraft', 'stylized', new.world_id, new.id, 'completed', v_style, new.stylized_image_url, 'live');
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists pois_provider_jobs on public.pois;
create trigger pois_provider_jobs
after insert or update of anim_video_url, cutout_image_url, stylized_image_url
on public.pois
for each row execute function public.provider_jobs_from_poi();

create or replace function public.ops_update_settings(p_key text, p_value jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_value jsonb;
begin
  if not public.is_platform_admin() then
    raise exception using errcode = '42501', message = 'Acceso restringido.';
  end if;
  if p_key not in ('video_policy', 'recraft_policy') then
    raise exception using errcode = '42501', message = 'Ajuste no permitido.';
  end if;
  if p_key = 'video_policy' then
    if coalesce((p_value ->> 'unit_cost_usd')::numeric, 0) <= 0
      or coalesce((p_value ->> 'max_videos_per_world_per_month')::numeric, 0) <= 0
      or coalesce((p_value ->> 'monthly_budget_usd')::numeric, 0) <= 0 then
      raise exception using errcode = '22023', message = 'La política de video requiere costos y topes mayores a cero.';
    end if;
    v_value := jsonb_build_object(
      'unit_cost_usd', (p_value ->> 'unit_cost_usd')::numeric,
      'max_videos_per_world_per_month', (p_value ->> 'max_videos_per_world_per_month')::int,
      'monthly_budget_usd', (p_value ->> 'monthly_budget_usd')::numeric
    );
  else
    if coalesce((p_value ->> 'cutout_cost_credits')::numeric, 0) <= 0
      or coalesce((p_value ->> 'stylized_cost_credits')::numeric, 0) <= 0
      or coalesce((p_value ->> 'alert_threshold')::numeric, 0) <= 0 then
      raise exception using errcode = '22023', message = 'La política de Recraft requiere costos y umbral mayores a cero.';
    end if;
    v_value := jsonb_build_object(
      'cutout_cost_credits', (p_value ->> 'cutout_cost_credits')::numeric,
      'stylized_cost_credits', (p_value ->> 'stylized_cost_credits')::numeric,
      'alert_threshold', (p_value ->> 'alert_threshold')::numeric
    );
  end if;

  insert into public.platform_settings (key, value, updated_at, updated_by)
  values (p_key, v_value, now(), auth.uid())
  on conflict (key) do update
    set value = excluded.value,
        updated_at = now(),
        updated_by = auth.uid();

  return v_value;
end;
$$;

revoke all on function public.ops_update_settings(text, jsonb) from public;
grant execute on function public.ops_update_settings(text, jsonb) to authenticated;
