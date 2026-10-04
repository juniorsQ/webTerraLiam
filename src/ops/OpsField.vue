<template>
  <label v-if="field.type === 'bool'" class="field toggle">
    <input type="checkbox" :checked="Boolean(modelValue)" @change="emit('update:modelValue', $event.target.checked)" />
    <span class="switch" aria-hidden="true" />
    {{ field.label }}
  </label>
  <label v-else class="field">
    {{ field.label }}
    <select v-if="field.type === 'select'" :value="modelValue" @change="emit('update:modelValue', $event.target.value)">
      <option v-for="option in field.options" :key="option.value" :value="option.value">{{ option.label }}</option>
    </select>
    <textarea v-else-if="field.type === 'textarea'" rows="3" :value="modelValue ?? ''" @input="emit('update:modelValue', $event.target.value)" />
    <input
      v-else
      :type="field.type === 'number' ? 'number' : 'text'"
      :value="modelValue ?? ''"
      :min="field.min"
      :max="field.max"
      :minlength="field.minlength"
      :maxlength="field.maxlength"
      required
      @input="emit('update:modelValue', field.type === 'number' ? Number($event.target.value) : $event.target.value)"
    />
  </label>
</template>

<script setup>
defineProps({
  field: { type: Object, required: true },
  modelValue: { type: [String, Number, Boolean, null], default: null },
})
const emit = defineEmits(['update:modelValue'])
</script>

<style scoped>
.field { display: grid; gap: .4rem; margin-bottom: .9rem; color: var(--ops-muted); font-size: .76rem; }
input, select, textarea { min-height: 42px; padding: .55rem .8rem; border: 1px solid var(--ops-line); border-radius: 8px; background: #0d1527; color: var(--ops-text); font: inherit; font-size: .86rem; }
textarea { resize: vertical; }
input:focus, select:focus, textarea:focus { outline: none; border-color: var(--ops-cyan); box-shadow: 0 0 0 3px rgba(86,215,237,.12); }
.toggle { display: flex; align-items: center; gap: .65rem; color: var(--ops-text); font-size: .84rem; cursor: pointer; }
.toggle input { position: absolute; opacity: 0; pointer-events: none; }
.switch { position: relative; flex: none; width: 36px; height: 20px; border-radius: 99px; background: rgba(255,255,255,.12); transition: background .15s; }
.switch::after { content: ''; position: absolute; top: 3px; left: 3px; width: 14px; height: 14px; border-radius: 50%; background: var(--ops-text); transition: transform .15s; }
.toggle input:checked + .switch { background: var(--ops-cyan); }
.toggle input:checked + .switch::after { transform: translateX(16px); background: #081018; }
.toggle input:focus-visible + .switch { box-shadow: 0 0 0 3px rgba(86,215,237,.3); }
</style>
