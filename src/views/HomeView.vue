<template>
  <a class="skip-link" href="#contenido">Saltar al contenido</a>
  <SiteNav :nav="sections.nav" />
  <main id="contenido">
    <IntroVideo :intro="sections.intro" />
    <SiteHero :hero="sections.hero" />
    <Presentacion :pitch="sections.pitch" />
    <HowItWorks :how="sections.how" />
    <AudienceSplit :kids="sections.kids" :parents="sections.parents" />
    <RarityRow :rarities="sections.rarities" />
    <MiniGames :minigames="sections.minigames" />
    <Safety :safety="sections.safety" />
    <Faq :faq="sections.faq" />
    <StoreCta :cta="sections.cta" />
  </main>
  <SiteFooter :footer="sections.footer" />
</template>

<script setup>
import { onMounted, ref } from 'vue'
import fallback from '@/data/fallback.json'
import { loadHomeSections } from '@/lib/cms'
import SiteNav from '@/components/SiteNav.vue'
import IntroVideo from '@/components/IntroVideo.vue'
import SiteHero from '@/components/SiteHero.vue'
import Presentacion from '@/components/Presentacion.vue'
import HowItWorks from '@/components/HowItWorks.vue'
import AudienceSplit from '@/components/AudienceSplit.vue'
import RarityRow from '@/components/RarityRow.vue'
import MiniGames from '@/components/MiniGames.vue'
import Safety from '@/components/Safety.vue'
import Faq from '@/components/Faq.vue'
import StoreCta from '@/components/StoreCta.vue'
import SiteFooter from '@/components/SiteFooter.vue'

const sections = ref(structuredClone(fallback))

onMounted(async () => {
  document.title = 'Terra Liam — Descubre el mundo a tu alrededor'
  const result = await loadHomeSections()
  sections.value = result.sections
})
</script>
