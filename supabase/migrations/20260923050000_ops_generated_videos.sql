create or replace function public.ops_generated_videos()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception using errcode = '42501', message = 'Acceso restringido.';
  end if;

  return coalesce((
    select jsonb_agg(to_jsonb(x) order by x.created_at desc)
    from (
      select
        poi.title as name,
        coalesce(w.name, 'Mundo sin nombre') as world,
        coalesce(nullif(owner.display_name, ''), 'Creador del mundo') as creator,
        poi.anim_video_url as video,
        coalesce(nullif(poi.cutout_image_url, ''), nullif(poi.stylized_image_url, ''), poi.image_url) as poster,
        poi.created_at
      from public.pois poi
      left join public.worlds w on w.id = poi.world_id
      left join public.profiles owner on owner.id = w.created_by
      where nullif(poi.anim_video_url, '') is not null
    ) x
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.ops_generated_videos() from public;
grant execute on function public.ops_generated_videos() to authenticated;
