<template>
  <section class="intro" aria-labelledby="intro-title">
    <template v-if="intro.videoSrc">
      <!-- Blurred copy fills the widescreen gap left by the portrait video. -->
      <video
        class="media backdrop"
        :src="intro.videoSrc"
        :poster="posterSrc"
        autoplay
        muted
        loop
        playsinline
        preload="metadata"
        aria-hidden="true"
      ></video>
      <video
        ref="video"
        class="media main"
        :src="intro.videoSrc"
        :poster="posterSrc"
        autoplay
        muted
        loop
        playsinline
        preload="metadata"
        aria-hidden="true"
      ></video>
    </template>
    <div v-else class="media poster" :style="posterStyle" aria-hidden="true"></div>

    <div class="veil" aria-hidden="true"></div>

    <div class="wrap content">
      <p class="badge">
        <span class="pulse" aria-hidden="true"></span>
        {{ intro.badge }}
      </p>
      <h2 id="intro-title">{{ intro.title }}</h2>
      <p class="sub">{{ intro.sub }}</p>
    </div>

    <a class="cue" :href="`#${scrollTarget}`" @click.prevent="scrollDown">
      <span class="mouse" aria-hidden="true">
        <span class="wheel"></span>
      </span>
      <span class="cue-label">{{ intro.scrollLabel }}</span>
    </a>
  </section>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'

const props = defineProps({
  intro: { type: Object, required: true },
  scrollTarget: { type: String, default: 'inicio' },
})

const video = ref(null)
const posterSrc = computed(() => props.intro.poster || '/og-image.svg')

const videoType = computed(() =>
  props.intro.videoSrc?.endsWith('.webm') ? 'video/webm' : 'video/mp4',
)

const posterStyle = computed(() =>
  { backgroundImage: `url(${posterSrc.value})` },
)

function scrollDown() {
  const el = document.getElementById(props.scrollTarget)
  el?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

onMounted(() => {
  const still = window.matchMedia('(prefers-reduced-motion: reduce)')
  if (still.matches) video.value?.pause()
})
</script>

<style scoped>
.intro {
  position: relative;
  min-height: 100svh;
  display: flex;
  align-items: flex-end;
  overflow: hidden;
  background: var(--night-sky);
}

.media {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center 28%;
}

.backdrop {
  filter: blur(28px) saturate(1.15);
  transform: scale(1.08);
}

.poster {
  background-position: center;
  background-size: cover;
}

.veil {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    180deg,
    rgba(27, 42, 74, 0.28) 0%,
    rgba(27, 42, 74, 0.12) 38%,
    rgba(27, 42, 74, 0.72) 100%
  );
}

.content {
  position: relative;
  /* Room for the scroll mouse pinned at the bottom. */
  padding-bottom: 7.5rem;
  padding-top: 4rem;
  color: var(--on-night);
}

.badge {
  display: inline-flex;
  align-items: center;
  gap: 0.55rem;
  margin: 0 0 0.9rem;
  padding: 0.45rem 1rem;
  border: 3px solid var(--white);
  border-radius: 999px;
  background: var(--coral);
  color: var(--white);
  font-family: var(--font-display);
  font-weight: 700;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.pulse {
  width: 11px;
  height: 11px;
  border-radius: 50%;
  background: var(--white);
  animation: blink 1.4s ease-in-out infinite;
}

h2 {
  margin: 0;
  color: var(--white);
  font-size: clamp(2.2rem, 6vw, 4rem);
  line-height: 1.05;
}

.sub {
  max-width: 34rem;
  margin: 0.7rem 0 1.6rem;
  color: var(--on-night);
  font-size: 1.1rem;
  font-weight: 600;
}

.cue {
  position: absolute;
  left: 50%;
  bottom: 1.8rem;
  transform: translateX(-50%);
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  gap: 0.55rem;
  color: var(--white);
  text-decoration: none;
}

.mouse {
  display: block;
  width: 30px;
  height: 48px;
  border: 3px solid var(--white);
  border-radius: 999px;
  position: relative;
}

.wheel {
  position: absolute;
  left: 50%;
  top: 8px;
  width: 4px;
  height: 9px;
  margin-left: -2px;
  border-radius: 999px;
  background: var(--white);
  animation: wheel 1.9s cubic-bezier(0.3, 0, 0.2, 1) infinite;
}

.cue-label {
  font-size: 0.8rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

@keyframes blink {
  50% {
    opacity: 0.25;
  }
}

@keyframes wheel {
  0% {
    transform: translateY(0);
    opacity: 0;
  }
  25% {
    opacity: 1;
  }
  75% {
    transform: translateY(16px);
    opacity: 0;
  }
  100% {
    transform: translateY(16px);
    opacity: 0;
  }
}

@media (prefers-reduced-motion: reduce) {
  .pulse,
  .wheel {
    animation: none;
  }
}
</style>
