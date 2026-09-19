<template>
  <section id="presentacion" class="section" aria-labelledby="pitch-title">
    <div class="wrap">
      <article class="card pitch">
        <p v-if="pitch.eyebrow" class="eyebrow">{{ pitch.eyebrow }}</p>
        <h2 id="pitch-title">{{ pitch.title }}</h2>
        <p v-for="(paragraph, index) in paragraphs" :key="index" class="copy">
          {{ paragraph }}
        </p>
      </article>
    </div>
  </section>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  pitch: { type: Object, required: true },
})

const paragraphs = computed(() => {
  const fromList = props.pitch.paragraphs
  if (Array.isArray(fromList) && fromList.length) {
    return fromList.filter(Boolean)
  }
  return String(props.pitch.body ?? '')
    .split(/\n+/)
    .map((line) => line.trim())
    .filter(Boolean)
})
</script>

<style scoped>
.pitch {
  padding: 1.8rem 1.4rem 1.6rem;
  max-width: 52rem;
  margin-inline: auto;
}

.pitch h2 {
  margin-bottom: 1rem;
}

.copy {
  color: var(--ink);
  font-size: 1.05rem;
  line-height: 1.55;
  margin: 0 0 0.95rem;
}

.copy:last-child {
  margin-bottom: 0;
}

@media (min-width: 720px) {
  .pitch {
    padding: 2.2rem 2.4rem 2rem;
  }
}
</style>
