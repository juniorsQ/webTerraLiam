import { supabase } from '@/lib/supabase'

async function call(name, args = {}) {
  if (!supabase) throw new Error('Supabase no está configurado.')
  const { data, error } = await supabase.rpc(name, args)
  if (error) throw error
  return data
}

export function loadOpsDashboard() {
  return call('ops_dashboard')
}

export function loadOpsTable(resource, limit = 50) {
  return call('ops_table', { p_resource: resource, p_limit: limit })
}
