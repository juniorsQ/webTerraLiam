<template>
  <header class="nav">
    <div class="wrap bar">
      <router-link class="brand" to="/" aria-label="TerraLiam inicio">
        <img src="/brand/buck.svg" width="44" height="50" alt="" />
        <span class="wordmark">
          <span class="terra">{{ nav.wordmarkTerra }}</span><span class="liam">{{ nav.wordmarkLiam }}</span>
        </span>
      </router-link>

      <button
        class="menu-btn"
        type="button"
        :aria-expanded="open ? 'true' : 'false'"
        aria-controls="site-menu"
        @click="open = !open"
      >
        Menú
      </button>

      <nav id="site-menu" :class="['links', { open }]" aria-label="Principal">
        <template v-for="link in nav.links" :key="link.href">
          <router-link v-if="isRoute(link.href)" :to="link.href" @click="open = false">
            {{ link.label }}
          </router-link>
          <a v-else :href="homeLink(link.href)" @click="open = false">
            {{ link.label }}
          </a>
        </template>
        <!-- Legal links live in the footer; the bar stays short. -->
        <a class="btn btn-lime cta" :href="homeLink(nav.ctaHref)" @click="open = false">
          {{ nav.cta }}
        </a>
      </nav>
    </div>
  </header>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute } from 'vue-router'

defineProps({
  nav: { type: Object, required: true },
})

const open = ref(false)
const route = useRoute()

function isRoute(href) {
  return typeof href === 'string' && href.startsWith('/') && !href.startsWith('//')
}

function homeLink(href) {
  if (!href) return '/#descargar'
  if (href.startsWith('#')) {
    return route.path === '/' ? href : `/${href}`
  }
  return href
}
</script>

<style scoped>
.nav {
  position: sticky;
  top: 0;
  z-index: 50;
  background: var(--white);
  border-bottom: 3px solid var(--sand);
}

.bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  min-height: 76px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 0.55rem;
  text-decoration: none;
  color: inherit;
}

.brand img {
  width: 44px;
  height: 50px;
  object-fit: contain;
}

.wordmark {
  font-size: 1.35rem;
}

.terra {
  color: var(--ink);
}

.liam {
  color: var(--teal-deep);
}

.links {
  display: none;
  align-items: center;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 0.85rem 1.15rem;
}

.links a:not(.btn) {
  color: var(--ink);
  font-weight: 800;
  text-decoration: none;
}

.links a:not(.btn):hover {
  color: var(--teal-deep);
}

.cta {
  min-height: 46px;
  padding-inline: 1.2rem;
}

.menu-btn {
  min-height: 44px;
  border-radius: 18px;
  border: 2.5px solid var(--sky-deep);
  background: var(--white);
  color: var(--sky-deep);
  font: inherit;
  font-weight: 800;
  padding: 0.3rem 0.9rem;
}

@media (max-width: 859px) {
  .links.open {
    display: flex;
    flex-direction: column;
    align-items: stretch;
    position: absolute;
    left: 1rem;
    right: 1rem;
    top: 76px;
    background: var(--white);
    border: 3px solid var(--sand);
    border-radius: 24px;
    padding: 1rem;
  }
}

@media (min-width: 860px) {
  .menu-btn {
    display: none;
  }

  .links {
    display: flex;
  }
}
</style>
