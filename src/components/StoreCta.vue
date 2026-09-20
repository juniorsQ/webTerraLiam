<template>
  <section id="descargar" class="night">
    <span class="moon" aria-hidden="true"></span>
    <span class="star a" aria-hidden="true"></span>
    <span class="star b" aria-hidden="true"></span>
    <span class="star c" aria-hidden="true"></span>
    <div class="wrap inner fade-up">
      <p class="bubble">{{ cta.bubble }}</p>
      <img class="buck" src="/brand/buck.png" width="180" height="200" alt="Buck, el robot guía de una rueda" />
      <p class="kicker">{{ cta.kicker }}</p>
      <h2>{{ cta.title }}</h2>
      <p class="body">{{ cta.body }}</p>
      <button class="btn btn-lime apk-button" type="button" @click="emit('download')">
        Descargar APK para Android
      </button>
      <p class="badge">{{ cta.badge }}</p>
      <div class="stores">
        <span class="btn btn-lime disabled">{{ cta.appStore }}</span>
        <span class="btn btn-ghost-night disabled">{{ cta.playStore }}</span>
      </div>
    </div>
    <HillsScene variant="night" />
  </section>
</template>

<script setup>
import HillsScene from '@/components/HillsScene.vue'

defineProps({
  cta: { type: Object, required: true },
})

const emit = defineEmits(['download'])
</script>

<style scoped>
.night {
  position: relative;
  overflow: hidden;
  background: var(--night-sky);
  color: var(--on-night);
  padding-top: 4.2rem;
}

.inner {
  position: relative;
  z-index: 1;
  text-align: center;
  padding-bottom: 1rem;
}

.bubble {
  display: inline-block;
  background: var(--white);
  color: var(--ink);
  border-radius: 999px;
  padding: 0.55rem 1.1rem;
  margin-bottom: 0.8rem;
  font-weight: 800;
}

.buck {
  width: 160px;
  height: auto;
  margin: 0 auto 1rem;
  mix-blend-mode: screen;
}

.kicker {
  color: var(--sky);
  font-weight: 800;
  margin-bottom: 0.35rem;
}

.night h2 {
  color: var(--on-night);
}

.body {
  max-width: 36rem;
  margin: 0 auto 1rem;
  color: var(--on-night);
}

.badge {
  display: inline-block;
  border: 2px solid var(--gold);
  color: var(--gold);
  border-radius: 999px;
  padding: 0.2rem 0.8rem;
  margin-bottom: 1.1rem;
}

.apk-button {
  margin-bottom: 1rem;
}

.stores {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  justify-content: center;
}

.disabled {
  opacity: 0.92;
  cursor: default;
  pointer-events: none;
}

.moon {
  position: absolute;
  top: 28px;
  right: 10%;
  width: 54px;
  height: 54px;
  border-radius: 50%;
  background: #f5f0d8;
  box-shadow: inset -16px -6px 0 0 var(--night-sky);
}

.star {
  position: absolute;
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: #fff;
}

.a {
  top: 70px;
  left: 18%;
}

.b {
  top: 120px;
  left: 72%;
}

.c {
  top: 48px;
  left: 42%;
}
</style>
