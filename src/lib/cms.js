import fallback from '@/data/fallback.json'
import { LEGAL_SLUGS } from '@/lib/legalText'
import { hasSupabase, supabase } from '@/lib/supabase'

function mergeSections(rows) {
  const sections = structuredClone(fallback)
  for (const row of rows ?? []) {
    if (!row?.key || !row.content) continue
    sections[row.key] = { ...sections[row.key], ...row.content }
  }
  return sections
}

export async function loadHomeSections() {
  if (!hasSupabase) {
    return { sections: structuredClone(fallback), source: 'fallback' }
  }

  const { data: page, error: pageError } = await supabase
    .from('site_pages')
    .select('id, slug, title, published')
    .eq('slug', 'home')
    .eq('published', true)
    .maybeSingle()

  if (pageError || !page) {
    return { sections: structuredClone(fallback), source: 'fallback' }
  }

  const { data: rows, error } = await supabase
    .from('site_sections')
    .select('key, sort, content')
    .eq('page_id', page.id)
    .order('sort')

  if (error || !rows?.length) {
    return { sections: structuredClone(fallback), source: 'fallback' }
  }

  return { sections: mergeSections(rows), source: 'supabase', page }
}

function localLegal(slug) {
  const key = LEGAL_SLUGS[slug]
  return structuredClone(fallback[key] ?? {})
}

export async function loadLegalPage(slug) {
  const local = localLegal(slug)
  if (!hasSupabase) return { content: local, source: 'fallback' }

  const { data: page } = await supabase
    .from('site_pages')
    .select('id')
    .eq('slug', slug)
    .eq('published', true)
    .maybeSingle()

  if (!page) return { content: local, source: 'fallback' }

  const { data: row } = await supabase
    .from('site_sections')
    .select('content')
    .eq('page_id', page.id)
    .eq('key', 'body')
    .maybeSingle()

  return {
    content: { ...local, ...(row?.content ?? {}) },
    source: row ? 'supabase' : 'fallback',
  }
}

export async function loadPrivacy() {
  return loadLegalPage('privacidad')
}

export async function loadAdminHome() {
  if (!hasSupabase) {
    throw new Error('Faltan VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY.')
  }

  const { data: page, error: pageError } = await supabase
    .from('site_pages')
    .select('*')
    .eq('slug', 'home')
    .single()

  if (pageError) throw pageError

  const { data: rows, error } = await supabase
    .from('site_sections')
    .select('*')
    .eq('page_id', page.id)
    .order('sort')

  if (error) throw error
  return { page, rows }
}

export async function loadAdminLegalPage(slug) {
  if (!hasSupabase) {
    throw new Error('Faltan VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY.')
  }

  const { data: page, error: pageError } = await supabase
    .from('site_pages')
    .select('*')
    .eq('slug', slug)
    .single()

  if (pageError) throw pageError

  const { data: row, error } = await supabase
    .from('site_sections')
    .select('*')
    .eq('page_id', page.id)
    .eq('key', 'body')
    .maybeSingle()

  if (error) throw error
  return { page, row }
}

export async function saveSectionContent(id, content) {
  const { error } = await supabase
    .from('site_sections')
    .update({ content })
    .eq('id', id)
  if (error) throw error
}
