import { supabase } from '@/lib/supabase'

async function call(name, args = {}) {
  if (!supabase) throw new Error('Supabase no está configurado.')
  const { data, error } = await supabase.rpc(name, args)
  if (error) throw new Error(friendlyError(error))
  return data
}

function friendlyError(error) {
  const message = error?.message ?? 'Error desconocido.'
  if (/Could not find the function|PGRST202/i.test(message)) {
    return 'Falta aplicar la migración 20261004000000_ops_backoffice_v2.sql en Supabase.'
  }
  if (/violates foreign key/i.test(message)) {
    return 'No se puede eliminar: hay registros vinculados que lo impiden.'
  }
  return message
}

export function loadOverview() {
  return call('ops_overview')
}

export function listResource(resource, { search = '', filter = '', limit = 50, offset = 0 } = {}) {
  return call('ops_list', {
    p_resource: resource,
    p_search: search || null,
    p_filter: filter || null,
    p_limit: limit,
    p_offset: offset,
  })
}

export function loadDetail(resource, id) {
  return call('ops_detail', { p_resource: resource, p_id: String(id) })
}

export function mutate(resource, id, action, payload = {}) {
  return call('ops_mutate', { p_resource: resource, p_id: String(id), p_action: action, p_payload: payload })
}

export async function loadProviderCredits() {
  if (!supabase) throw new Error('Supabase no está configurado.')
  const { data, error } = await supabase.functions.invoke('ops-provider-credits')
  if (error) throw error
  return data
}

export function saveOpsSettings(key, value) {
  return call('ops_update_settings_audited', { p_key: key, p_value: value })
}

export function storagePublicUrl(path) {
  const base = import.meta.env.VITE_SUPABASE_URL
  if (!base || !path) return ''
  return `${base}/storage/v1/object/public/poi-media/${String(path).split('/').map(encodeURIComponent).join('/')}`
}
