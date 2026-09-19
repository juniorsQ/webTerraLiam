<template>
  <section class="section faq-sec">
    <div class="wrap">
      <header class="section-head">
        <h2>{{ faq.title }}</h2>
      </header>
      <div class="list">
        <details v-for="item in faq.items" :key="item.q" class="card item">
          <summary>{{ item.q }}</summary>
          <p>{{ item.a }}</p>
        </details>
      </div>
    </div>
  </section>
</template>

<script setup>
defineProps({
  faq: { type: Object, required: true },
})
</script>

<style scoped>
.faq-sec {
  padding-top: 0;
}

.list {
  display: grid;
  gap: 0.8rem;
  max-width: 800px;
  margin-inline: auto;
}

.item {
  padding: 0.2rem 1.1rem 0.2rem;
}

summary {
  cursor: pointer;
  font-weight: 800;
  padding: 0.95rem 0;
  list-style: none;
  color: var(--ink);
}

summary::-webkit-details-marker {
  display: none;
}

.item p {
  color: var(--muted);
  padding-bottom: 0.9rem;
  margin: 0;
}
</style>
