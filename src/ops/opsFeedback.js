import { reactive } from 'vue'

// Single dialog + toast stack shared by every Ops view (rendered in OpsShell).
export const feedback = reactive({
  dialog: null,
  toasts: [],
})

let toastId = 0

export function toast(message, tone = 'good') {
  const id = ++toastId
  feedback.toasts.push({ id, message, tone })
  window.setTimeout(() => {
    const index = feedback.toasts.findIndex((item) => item.id === id)
    if (index >= 0) feedback.toasts.splice(index, 1)
  }, tone === 'bad' ? 7000 : 3500)
}

function open(dialog) {
  return new Promise((resolve) => {
    feedback.dialog = { ...dialog, resolve }
  })
}

/**
 * Resolves true/false. `typed` forces the operator to type a word before a
 * destructive action is enabled.
 */
export function confirmAction({ title, message, confirmLabel = 'Confirmar', danger = false, typed = '' }) {
  return open({ kind: 'confirm', title, message, confirmLabel, danger, typed })
}

/** Resolves the edited values object, or null when cancelled. */
export function editForm({ title, message = '', fields, values, confirmLabel = 'Guardar' }) {
  return open({ kind: 'form', title, message, fields, values: { ...values }, confirmLabel })
}

export function closeDialog(result) {
  const dialog = feedback.dialog
  feedback.dialog = null
  dialog?.resolve(result)
}
