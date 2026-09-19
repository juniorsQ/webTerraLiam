<template>
  <section id="como-funciona" class="section">
    <div class="wrap">
      <header class="section-head">
        <h2>{{ how.title }}</h2>
        <p class="lede">{{ how.subtitle }}</p>
      </header>
      <ol class="grid-3 steps">
        <li v-for="step in how.steps" :key="step.n" class="card step">
          <div class="icon" :data-n="step.n" aria-hidden="true">
            <svg v-if="Number(step.n) === 1" viewBox="0 0 80 80">
              <rect x="22" y="10" width="36" height="60" rx="10" fill="#FF8A65" />
              <circle cx="40" cy="36" r="10" fill="#fff" />
              <rect x="28" y="50" width="24" height="10" rx="5" fill="#FFE4B8" />
            </svg>
            <svg v-else-if="Number(step.n) === 2" viewBox="0 0 80 80">
              <ellipse cx="40" cy="42" rx="28" ry="18" fill="#7ED6FF" />
              <ellipse cx="28" cy="36" rx="14" ry="12" fill="#4BB8F0" />
              <ellipse cx="52" cy="34" rx="16" ry="13" fill="#B39DFF" />
              <circle cx="54" cy="52" r="8" fill="#FF8A65" />
            </svg>
            <svg v-else viewBox="0 0 80 80">
              <circle cx="30" cy="28" r="10" fill="#FFC94A" />
              <rect x="18" y="40" width="24" height="20" rx="10" fill="#2BB8C8" />
              <rect x="46" y="34" width="18" height="28" rx="9" fill="#1A9AAB" />
              <circle cx="55" cy="26" r="7" fill="#5DD67A" />
            </svg>
          </div>
          <p class="n">{{ step.n }}</p>
          <h3>{{ step.title }}</h3>
          <p>{{ step.body }}</p>
        </li>
      </ol>
    </div>
  </section>
</template>

<script setup>
defineProps({
  how: { type: Object, required: true },
})
</script>

<style scoped>
.steps {
  list-style: none;
  margin: 0;
  padding: 0;
}

.step {
  padding: 1.35rem 1.2rem 1.2rem;
  text-align: left;
}

.step p {
  color: var(--muted);
  margin: 0;
}

.step h3 {
  color: var(--ink);
}

.n {
  font-family: var(--font-display);
  color: var(--teal-deep);
  font-size: 1.4rem;
  margin: 0.2rem 0 0.3rem;
}

.icon {
  width: 72px;
  height: 72px;
  margin-bottom: 0.4rem;
}

.icon svg {
  width: 72px;
  height: 72px;
}
</style>
