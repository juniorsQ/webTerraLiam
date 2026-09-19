<template>
  <main class="section">
    <div class="wrap">
      <p><router-link to="/admin">← Secciones</router-link></p>
      <h1>{{ label }}</h1>
      <p class="admin-note">
        Página pública <code>/{{ slug }}</code>. El copy vive en <code>site_sections</code> (key
        <code>body</code>).
      </p>
      <p v-if="error" class="error">{{ error }}</p>
      <p v-else-if="!model">Cargando…</p>
      <form v-else class="card form" @submit.prevent="onSave">
        <template v-for="field in fields" :key="field.key">
          <label v-if="field.type === 'text'" class="field">
            <span class="field-label">{{ field.label }}</span>
            <input v-model="model[field.key]" class="input" type="text" />
          </label>
          <label v-else-if="field.type === 'textarea'" class="field">
            <span class="field-label">{{ field.label }}</span>
            <textarea v-model="model[field.key]" />
          </label>
          <label v-else-if="field.type === 'lines'" class="field">
            <span class="field-label">{{ field.label }}</span>
            <textarea v-model="lineBuffers[field.key]" />
          </label>
          <fieldset v-else-if="field.type === 'objects'" class="field group">
            <legend>{{ field.label }}</legend>
            <article v-for="(item, index) in model[field.key]" :key="index" class="nested">
              <p>{{ field.itemLabel }} {{ index + 1 }}</p>
              <label v-for="sub in field.fields" :key="sub.key" class="field">
                <span class="field-label">{{ sub.label }}</span>
                <textarea v-if="sub.type === 'textarea'" v-model="item[sub.key]" />
                <input v-else v-model="item[sub.key]" class="input" type="text" />
              </label>
            </article>
          </fieldset>
        </template>
        <p v-if="saved" class="ok">Guardado.</p>
        <div class="actions">
          <button class="btn btn-lime" type="submit" :disabled="busy">Guardar</button>
          <a class="btn btn-sky" :href="`/${slug}`" target="_blank" rel="noreferrer">Vista previa</a>
        </div>
      </form>
    </div>
  </main>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadAdminLegalPage, saveSectionContent } from '@/lib/cms'
import { LEGAL_FIELDS } from '@/admin/sectionSchemas'
import { LEGAL_PAGES } from '@/lib/legalText'
import { useAdminSession } from '@/admin/useAdminSession'

const props = defineProps({
  slug: { type: String, required: true },
})

const router = useRouter()
const { refresh, session, hasSupabase } = useAdminSession()
const rowId = ref(null)
const model = ref(null)
const lineBuffers = reactive({})
const error = ref('')
const saved = ref(false)
const busy = ref(false)

const fields = LEGAL_FIELDS
const label = computed(
  () => LEGAL_PAGES.find((page) => page.slug === props.slug)?.label ?? props.slug,
)

function prepareContent(raw) {
  const content = structuredClone(raw ?? {})
  content.statements = content.statements ?? []
  content.steps = content.steps ?? []
  content.blocks = (content.blocks ?? []).map((block) => ({
    ...block,
    bullets: Array.isArray(block.bullets) ? block.bullets.join('\n') : (block.bullets ?? ''),
  }))
  content.related = content.related ?? []
  for (const field of fields) {
    if (field.type === 'lines') {
      lineBuffers[field.key] = (content[field.key] ?? []).join('\n')
    }
  }
  return content
}

onMounted(async () => {
  await refresh()
  if (!hasSupabase || !session.value) {
    router.replace('/admin/login')
    return
  }
  try {
    const data = await loadAdminLegalPage(props.slug)
    if (!data.row) {
      error.value = 'No existe esa página en Postgres. Aplica la migración site_legal_pages.'
      return
    }
    rowId.value = data.row.id
    model.value = prepareContent(data.row.content)
  } catch (err) {
    error.value = err.message ?? 'No se pudo abrir el editor.'
  }
})

async function onSave() {
  saved.value = false
  error.value = ''
  busy.value = true
  try {
    const payload = structuredClone(model.value)
    for (const field of fields) {
      if (field.type === 'lines') {
        payload[field.key] = String(lineBuffers[field.key] ?? '')
          .split('\n')
          .map((line) => line.trim())
          .filter(Boolean)
      }
    }
    payload.blocks = (payload.blocks ?? []).map((block) => ({
      ...block,
      bullets: String(block.bullets ?? '')
        .split('\n')
        .map((line) => line.trim())
        .filter(Boolean),
    }))
    await saveSectionContent(rowId.value, payload)
    saved.value = true
  } catch (err) {
    error.value = err.message ?? 'No se pudo guardar.'
  } finally {
    busy.value = false
  }
}
</script>

<style scoped>
h1 {
  color: var(--ink);
  font-size: 2.1rem;
}

.form {
  margin-top: 1.2rem;
  padding: 1.4rem;
}

.group {
  border: 3px solid var(--sand);
  border-radius: 24px;
  padding: 0.8rem 1rem 1rem;
}

.nested {
  border-top: 2px solid var(--sand);
  padding-top: 0.8rem;
  margin-top: 0.8rem;
}

.actions {
  display: flex;
  gap: 0.7rem;
  flex-wrap: wrap;
  margin-top: 1.2rem;
}

.ok {
  color: var(--teal-deep);
  font-weight: 800;
}

.error {
  color: #c2410c;
  font-weight: 800;
}
</style>
