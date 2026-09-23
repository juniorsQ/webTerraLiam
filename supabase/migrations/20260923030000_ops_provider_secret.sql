-- Service-role reader for Fal/Recraft keys stored in Vault.
-- Values live in vault.secrets, never in this file.
create or replace function public.ops_provider_secret(p_name text)
returns text
language plpgsql
stable
security definer
set search_path = vault, public
as $$
begin
  if auth.role() is distinct from 'service_role' then
    raise exception using errcode = '42501', message = 'Acceso restringido.';
  end if;
  if p_name not in ('FAL_KEY', 'RECRAFT_API_KEY', 'RECRAFT_API_TOKEN') then
    raise exception using errcode = '42501', message = 'Secret not allowed.';
  end if;
  return (
    select decrypted_secret
    from vault.decrypted_secrets
    where name = p_name
    limit 1
  );
end;
$$;

revoke all on function public.ops_provider_secret(text) from public, anon, authenticated;
grant execute on function public.ops_provider_secret(text) to service_role;
