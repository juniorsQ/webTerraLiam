<template>
  <section id="seguridad" class="section">
    <div class="wrap">
      <header class="section-head">
        <h2>{{ safety.title }}</h2>
        <p class="lede">{{ safety.subtitle }}</p>
      </header>
      <div class="card body">
        <ul>
          <li v-for="item in safety.items" :key="item">
            <span class="mark" aria-hidden="true">
              <svg viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="10" fill="#2BB8C8" />
                <path d="M7 12.5l3 3 7-7" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round" />
              </svg>
            </span>
            {{ item }}
          </li>
        </ul>
        <p class="ctas">
          <router-link class="btn btn-sky" :to="safety.privacyHref">
            {{ safety.privacyCta }}
          </router-link>
          <router-link
            v-if="safety.familyHref"
            class="btn btn-sky"
            :to="safety.familyHref"
          >
            {{ safety.familyCta }}
          </router-link>
        </p>
      </div>
    </div>
  </section>
</template>

<script setup>
defineProps({
  safety: { type: Object, required: true },
})
</script>

<style scoped>
.body {
  padding: 1.6rem 1.4rem;
  max-width: 800px;
  margin-inline: auto;
}

ul {
  list-style: none;
  margin: 0 0 1.2rem;
  padding: 0;
}

li {
  display: flex;
  gap: 0.7rem;
  align-items: flex-start;
  padding: 0.45rem 0;
  color: var(--ink);
}

.mark {
  flex: 0 0 24px;
  margin-top: 0.1rem;
}

.mark svg {
  width: 24px;
  height: 24px;
  display: block;
}

.ctas {
  display: flex;
  flex-wrap: wrap;
  gap: 0.7rem;
}
</style>
