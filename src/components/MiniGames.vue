<template>
  <section id="minijuegos" class="section games-sec">
    <div class="wrap">
      <header class="section-head">
        <h2>{{ minigames.title }}</h2>
        <p class="lede">{{ minigames.subtitle }}</p>
      </header>
      <div class="grid-3">
        <article v-for="game in minigames.games" :key="game.title" class="card game">
          <img src="/brand/buck.svg" width="64" height="72" alt="" />
          <h3>{{ game.title }}</h3>
          <p class="tag">{{ game.rarity }}</p>
          <p>{{ game.body }}</p>
        </article>
      </div>
    </div>
  </section>
</template>

<script setup>
defineProps({
  minigames: { type: Object, required: true },
})
</script>

<style scoped>
.games-sec {
  padding-top: 0;
}

.game {
  padding: 1.35rem 1.2rem;
  text-align: center;
}

.game img {
  margin: 0 auto 0.6rem;
  height: 72px;
  width: auto;
}

.game p {
  color: var(--muted);
  margin: 0;
}

.tag {
  color: var(--teal-deep) !important;
  font-weight: 800;
  margin-bottom: 0.4rem !important;
}
</style>
