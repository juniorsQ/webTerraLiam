<template>
  <footer class="foot">
    <div class="wrap row">
      <p class="brand">
        <span class="wordmark">
          <span class="terra">Terra</span>
          <span class="liam">Liam</span>
        </span>
        <span class="blurb">{{ footer.blurb }}</span>
      </p>
      <nav aria-label="Pie">
        <router-link
          v-for="link in legalLinks"
          :key="link.href"
          :to="link.href"
        >
          {{ link.label }}
        </router-link>
        <a :href="footer.contactHref">{{ footer.contact }}</a>
      </nav>
    </div>
    <div class="wrap copy">
      © {{ year }} {{ footer.copyright }}
    </div>
  </footer>
</template>

<script setup>
import { computed } from 'vue'

const year = new Date().getFullYear()

const props = defineProps({
  footer: { type: Object, required: true },
})

const legalLinks = computed(() => {
  if (props.footer.links?.length) return props.footer.links
  if (props.footer.privacy) {
    return [{ label: props.footer.privacy, href: props.footer.privacyHref || '/privacidad' }]
  }
  return []
})
</script>

<style scoped>
.foot {
  background: var(--cream);
  border-top: 3px solid var(--sand);
  padding: 1.8rem 0 2rem;
}

.row {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
  align-items: flex-end;
}

.wordmark {
  display: block;
  font-size: 1.3rem;
  margin-bottom: 0.25rem;
}

.terra {
  color: var(--ink);
}

.liam {
  color: var(--teal-deep);
  margin-left: 0.25rem;
}

.blurb {
  color: var(--muted);
}

nav {
  display: flex;
  flex-wrap: wrap;
  gap: 0.65rem 1.1rem;
  justify-content: flex-end;
}

nav a {
  color: var(--ink);
  font-weight: 800;
}

.copy {
  margin-top: 1rem;
  color: var(--muted);
  font-size: 0.92rem;
}
</style>
