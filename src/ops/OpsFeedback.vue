<template>
  <div v-if="dialog" class="dialog-backdrop" @click.self="cancel">
    <form class="dialog" role="dialog" aria-modal="true" :aria-label="dialog.title" @submit.prevent="submit">
      <h2>{{ dialog.title }}</h2>
      <p v-if="dialog.message" class="dialog-message">{{ dialog.message }}</p>

      <template v-if="dialog.kind === 'form'">
        <OpsField v-for="field in dialog.fields" :key="field.key" v-model="dialog.values[field.key]" :field="field" />
      </template>

      <label v-if="dialog.typed" class="typed">
        Escribe <strong>{{ dialog.typed }}</strong> para confirmar
        <input v-model="typedValue" autocomplete="off" />
      </label>

      <div class="dialog-actions">
        <button type="button" class="ghost" @click="cancel">Cancelar</button>
        <button type="submit" :class="dialog.danger ? 'danger' : 'primary'" :disabled="blocked">
          {{ dialog.confirmLabel }}
        </button>
      </div>
    </form>
  </div>

  <div class="toast-stack" aria-live="polite">
    <p v-for="item in feedback.toasts" :key="item.id" class="toast" :class="`toast-${item.tone}`">
      <span>{{ item.tone === 'bad' ? '!' : '✓' }}</span>{{ item.message }}
    </p>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import OpsField from '@/ops/OpsField.vue'
import { closeDialog, feedback } from '@/ops/opsFeedback'

const typedValue = ref('')
const dialog = computed(() => feedback.dialog)
const blocked = computed(() => Boolean(dialog.value?.typed) && typedValue.value.trim() !== dialog.value.typed)

watch(dialog, () => { typedValue.value = '' })

function cancel() {
  closeDialog(dialog.value?.kind === 'form' ? null : false)
}

function submit() {
  if (blocked.value) return
  closeDialog(dialog.value.kind === 'form' ? { ...dialog.value.values } : true)
}

function onKey(event) {
  if (event.key === 'Escape' && dialog.value) cancel()
}

onMounted(() => window.addEventListener('keydown', onKey))
onBeforeUnmount(() => window.removeEventListener('keydown', onKey))
</script>

<style scoped>
.dialog-backdrop { position: fixed; inset: 0; z-index: 80; display: grid; place-items: center; padding: 1rem; background: rgba(4,8,18,.7); }
.dialog { width: min(100%, 460px); max-height: 90vh; overflow: auto; padding: 1.4rem; border: 1px solid var(--ops-line); border-radius: 14px; background: var(--ops-panel); box-shadow: 0 30px 90px rgba(0,0,0,.45); }
h2 { margin: 0 0 .5rem; color: var(--ops-text); font-family: var(--font-display); font-size: 1.3rem; }
.dialog-message { margin: 0 0 1.1rem; color: var(--ops-muted); font-size: .85rem; line-height: 1.5; }
.typed { display: grid; gap: .45rem; margin-top: .4rem; color: var(--ops-muted); font-size: .78rem; }
.typed strong { color: var(--ops-coral); }
.typed input { min-height: 42px; padding: 0 .8rem; border: 1px solid var(--ops-line); border-radius: 8px; background: #0d1527; color: var(--ops-text); font: inherit; }
.dialog-actions { display: flex; justify-content: flex-end; gap: .6rem; margin-top: 1.3rem; }
.dialog-actions button { min-height: 42px; padding: 0 1rem; border-radius: 8px; font: inherit; font-weight: 800; font-size: .82rem; cursor: pointer; }
.ghost { border: 1px solid var(--ops-line); background: transparent; color: var(--ops-text); }
.primary { border: 0; background: var(--ops-cyan); color: #081018; }
.danger { border: 0; background: var(--ops-coral); color: #1d0707; }
.dialog-actions button:disabled { opacity: .4; cursor: not-allowed; }
.toast-stack { position: fixed; right: 1rem; bottom: 1rem; z-index: 90; display: grid; gap: .5rem; max-width: min(92vw, 380px); }
.toast { display: flex; gap: .6rem; align-items: flex-start; margin: 0; padding: .75rem .9rem; border: 1px solid var(--ops-line); border-radius: 10px; background: #18233b; color: var(--ops-text); font-size: .82rem; box-shadow: 0 12px 40px rgba(0,0,0,.35); }
.toast span { display: grid; place-items: center; flex: none; width: 20px; height: 20px; border-radius: 50%; font-size: .72rem; font-weight: 900; }
.toast-good span { background: rgba(184,232,92,.18); color: var(--ops-lime); }
.toast-bad { border-color: rgba(255,124,120,.4); }
.toast-bad span { background: rgba(255,124,120,.18); color: var(--ops-coral); }
</style>
