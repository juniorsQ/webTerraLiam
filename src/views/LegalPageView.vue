<template>
  <a class="skip-link" href="#contenido">Saltar al contenido</a>
  <SiteNav :nav="nav" />
  <main id="contenido" class="section">
    <article class="wrap card page">
      <p v-if="content.reviewerNote" class="reviewer">{{ content.reviewerNote }}</p>
      <p v-if="content.updated" class="updated">{{ content.updated }}</p>
      <h1>{{ content.title }}</h1>
      <p class="lede">{{ content.intro }}</p>

      <ul v-if="content.statements?.length" class="statements">
        <li v-for="item in content.statements" :key="item">
          <span v-html="emphasize(item)"></span>
        </li>
      </ul>

      <ol v-if="content.steps?.length" class="steps">
        <li v-for="step in content.steps" :key="step.n || step.title">
          <strong>{{ step.title }}</strong>
          <p>{{ step.body }}</p>
        </li>
      </ol>

      <section v-for="block in content.blocks" :key="block.heading" class="block">
        <h2>{{ block.heading }}</h2>
        <p v-for="p in asParagraphs(block.body)" :key="p">{{ p }}</p>
        <ul v-if="asList(block.bullets).length" class="bullets">
          <li v-for="item in asList(block.bullets)" :key="item">{{ item }}</li>
        </ul>
      </section>

      <p class="back">
        <router-link to="/">Volver al inicio</router-link>
        <template v-for="link in content.related" :key="link.href">
          · <router-link :to="link.href">{{ link.label }}</router-link>
        </template>
      </p>
    </article>
  </main>
  <SiteFooter :footer="footer" />
</template>

<script setup>
import { onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import fallback from '@/data/fallback.json'
import { loadHomeSections, loadLegalPage } from '@/lib/cms'
import { asList, asParagraphs, emphasize } from '@/lib/legalText'
import SiteNav from '@/components/SiteNav.vue'
import SiteFooter from '@/components/SiteFooter.vue'

const route = useRoute()
const nav = ref(structuredClone(fallback.nav))
const footer = ref(structuredClone(fallback.footer))
const content = ref({})

async function load() {
  const slug = route.meta.slug
  const [home, legal] = await Promise.all([loadHomeSections(), loadLegalPage(slug)])
  nav.value = home.sections.nav
  footer.value = home.sections.footer
  content.value = legal.content
  const title = legal.content.title || 'Terra Liam'
  document.title = `${title} — Terra Liam`
}

onMounted(load)
watch(() => route.meta.slug, load)
</script>

<style scoped>
.page {
  padding: 2rem 1.4rem 2.2rem;
  max-width: 760px;
}

.reviewer {
  color: var(--muted);
  font-size: 0.92rem;
  font-weight: 700;
  margin-bottom: 0.35rem;
}

.updated {
  color: var(--teal-deep);
  font-weight: 800;
  font-size: 0.88rem;
  margin-bottom: 0.8rem;
}

h1 {
  color: var(--ink);
}

h2 {
  font-size: 1.35rem;
  margin: 1.4rem 0 0.45rem;
  color: var(--teal-deep);
}

.page p,
.page li {
  color: var(--ink);
}

.statements {
  list-style: none;
  margin: 1.1rem 0 0.4rem;
  padding: 0;
  display: grid;
  gap: 0.7rem;
}

.statements li {
  background: var(--cream);
  border: 3px solid var(--sand);
  border-radius: 22px;
  padding: 0.9rem 1rem;
  font-size: 1.12rem;
  font-weight: 800;
}

.statements :deep(strong) {
  color: var(--teal-deep);
}

.steps {
  margin: 1.1rem 0 0.4rem;
  padding-left: 1.2rem;
  display: grid;
  gap: 0.85rem;
}

.steps p {
  margin: 0.25rem 0 0;
}

.block .bullets {
  margin: 0.2rem 0 0.8rem;
  padding-left: 1.15rem;
}

.back {
  margin-top: 1.6rem;
}
</style>
