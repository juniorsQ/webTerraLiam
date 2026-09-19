<template>
  <section class="section">
    <div class="wrap">
      <header class="section-head">
        <h2>{{ rarities.title }}</h2>
        <p class="lede">{{ rarities.subtitle }}</p>
      </header>
      <div class="grid-3">
        <article
          v-for="card in rarities.cards"
          :key="card.label"
          class="card rarity"
        >
          <span :class="['chip', `chip-${card.rarity}`]">{{ card.label }}</span>
          <h3>{{ card.game }}</h3>
          <p class="pts">{{ card.points }}</p>
          <p>{{ card.body }}</p>
        </article>
      </div>
    </div>
  </section>
</template>

<script setup>
defineProps({
  rarities: { type: Object, required: true },
})
</script>

<style scoped>
.rarity {
  padding: 1.35rem 1.2rem;
}

.rarity p {
  color: var(--muted);
  margin: 0;
}

.pts {
  color: var(--ink) !important;
  font-weight: 800;
  margin: 0.2rem 0 0.45rem !important;
}

.chip {
  margin-bottom: 0.8rem;
}
</style>
