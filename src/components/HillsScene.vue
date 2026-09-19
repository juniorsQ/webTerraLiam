<template>
  <svg
    class="hills"
    viewBox="0 0 1440 280"
    preserveAspectRatio="none"
    aria-hidden="true"
  >
    <path
      :fill="far"
      d="M0 150 C180 90 320 190 520 130 C720 70 860 170 1080 110 C1240 70 1360 130 1440 100 L1440 280 L0 280 Z"
    />
    <path
      :fill="mid"
      d="M0 190 C220 130 380 230 620 170 C860 110 1020 210 1240 160 C1340 140 1400 170 1440 155 L1440 280 L0 280 Z"
    />
    <path
      :fill="near"
      d="M0 230 C260 190 420 250 700 210 C980 170 1180 250 1440 210 L1440 280 L0 280 Z"
    />
    <path
      :stroke="path"
      fill="none"
      stroke-width="8"
      stroke-linecap="round"
      stroke-dasharray="14 16"
      d="M620 280 C700 230 780 250 860 210"
    />
    <g :fill="tree">
      <ellipse cx="160" cy="188" rx="18" ry="22" />
      <rect x="156" y="205" width="8" height="18" rx="2" />
      <ellipse cx="1180" cy="168" rx="22" ry="26" />
      <rect x="1175" y="188" width="10" height="22" rx="2" />
      <ellipse cx="1288" cy="198" rx="14" ry="18" />
      <rect x="1284" y="212" width="7" height="14" rx="2" />
    </g>
  </svg>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: { type: String, default: 'day' },
})

const night = computed(() => props.variant === 'night')
const far = computed(() => (night.value ? '#243556' : '#b8ebc4'))
const mid = computed(() => (night.value ? '#1e334f' : '#8fe0c0'))
const near = computed(() => (night.value ? '#17263e' : '#7ec9b0'))
const tree = computed(() => (night.value ? '#2f4a3a' : '#5dd67a'))
const path = computed(() => (night.value ? '#6b5340' : '#c4a07a'))
</script>

<style scoped>
.hills {
  display: block;
  width: 100%;
  height: 180px;
}
</style>
