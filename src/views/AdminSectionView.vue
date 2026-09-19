<template>
  <main class="section">
    <div class="wrap">
      <p><router-link to="/admin">← Secciones</router-link></p>
      <h1>{{ labelFor(sectionKey) }}</h1>
      <p class="admin-note">Editor de la sección <code>{{ sectionKey }}</code>. Los campos coinciden con el JSON de Postgres.</p>
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
          <a class="btn btn-sky" href="/" target="_blank" rel="noreferrer">Vista previa</a>
        </div>
      </form>
    </div>
  </main>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { loadAdminHome, saveSectionContent } from '@/lib/cms'
import { labelFor, SECTION_FIELDS } from '@/admin/sectionSchemas'
import { useAdminSession } from '@/admin/useAdminSession'

const props = defineProps({
  sectionKey: { type: String, required: true },
})

const router = useRouter()
const { refresh, session, hasSupabase } = useAdminSession()
const rowId = ref(null)
const model = ref(null)
const lineBuffers = reactive({})
const error = ref('')
const saved = ref(false)
const busy = ref(false)

const fields = computed(() => SECTION_FIELDS[props.sectionKey] ?? [])

onMounted(async () => {
  await refresh()
  if (!hasSupabase || !session.value) {
    router.replace('/admin/login')
    return
  }
  try {
    const data = await loadAdminHome()
    const row = data.rows.find((item) => item.key === props.sectionKey)
    if (!row) {
      error.value = 'No existe esa sección en Postgres. Aplica la migración del CMS.'
      return
    }
    rowId.value = row.id
    const content = structuredClone(row.content ?? {})
    for (const field of SECTION_FIELDS[props.sectionKey] ?? []) {
      if (field.type === 'lines') {
        lineBuffers[field.key] = (content[field.key] ?? []).join('\n')
      }
    }
    model.value = content
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
    for (const field of fields.value) {
      if (field.type === 'lines') {
        payload[field.key] = String(lineBuffers[field.key] ?? '')
          .split('\n')
          .map((line) => line.trim())
          .filter(Boolean)
      }
    }
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
