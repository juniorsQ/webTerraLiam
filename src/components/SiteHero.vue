<template>
  <section class="hero" aria-labelledby="hero-title">
    <div class="sky">
      <span class="sun" aria-hidden="true"></span>
      <div class="wrap grid">
        <div class="copy">
          <p class="eyebrow">{{ hero.eyebrow }}</p>
          <h1 id="hero-title">{{ hero.h1 }}</h1>
          <p class="sub">{{ hero.sub }}</p>
          <div class="actions">
            <a class="btn btn-lime" :href="hero.ctaPrimaryHref">{{ hero.ctaPrimary }}</a>
            <a class="btn btn-sky" :href="hero.ctaSecondaryHref">{{ hero.ctaSecondary }}</a>
          </div>
          <p class="micro">{{ hero.micro }}</p>
        </div>

        <div class="stage">
          <div class="portrait">
            <img
              src="/brand/app_icon.png"
              width="520"
              height="520"
              :alt="hero.liamAlt"
            />
            <article class="sticker cam" aria-hidden="true">
              <svg viewBox="0 0 64 64"><rect x="10" y="20" width="44" height="30" rx="8" fill="#FFC94A"/><circle cx="32" cy="35" r="10" fill="#fff"/><circle cx="32" cy="35" r="6" fill="#4BB8F0"/><rect x="38" y="14" width="10" height="10" rx="3" fill="#FF8A65"/></svg>
            </article>
            <article class="sticker trophy" aria-hidden="true">
              <svg viewBox="0 0 64 64"><rect x="22" y="12" width="20" height="22" rx="10" fill="#FFC94A"/><rect x="18" y="36" width="28" height="8" rx="4" fill="#1A9AAB"/><rect x="26" y="44" width="12" height="8" rx="3" fill="#FFE4B8"/></svg>
            </article>
            <article class="sticker gift" aria-hidden="true">
              <svg viewBox="0 0 64 64"><rect x="14" y="26" width="36" height="26" rx="8" fill="#FF8A65"/><rect x="28" y="26" width="8" height="26" fill="#fff"/><rect x="14" y="20" width="36" height="10" rx="5" fill="#4BB8F0"/></svg>
            </article>
            <article class="sticker people" aria-hidden="true">
              <svg viewBox="0 0 64 64"><circle cx="24" cy="22" r="8" fill="#FF8A65"/><circle cx="40" cy="22" r="8" fill="#FFC94A"/><rect x="12" y="34" width="40" height="18" rx="9" fill="#7ED6FF"/></svg>
            </article>
          </div>
        </div>
      </div>
      <HillsScene />
    </div>

    <div class="wrap">
      <ul class="trust">
        <li v-for="item in hero.trust" :key="item">
          <span class="dot" aria-hidden="true"></span>
          {{ item }}
        </li>
      </ul>
      <p v-if="hero.supervision" class="supervision">{{ hero.supervision }}</p>
    </div>
  </section>
</template>

<script setup>
import HillsScene from '@/components/HillsScene.vue'

defineProps({
  hero: { type: Object, required: true },
})
</script>

<style scoped>
.hero {
  background: var(--cream);
}

.sky {
  position: relative;
  overflow: hidden;
  background: linear-gradient(180deg, var(--hero-sky) 0%, var(--cream) 78%);
}

.sun {
  position: absolute;
  top: 28px;
  right: 8%;
  width: 86px;
  height: 86px;
  border-radius: 50%;
  background: var(--gold);
}

.grid {
  display: grid;
  gap: 1.5rem;
  padding-top: 2.4rem;
  align-items: center;
}

.copy {
  max-width: 36rem;
}

.copy h1 {
  color: var(--ink);
}

.sub {
  color: var(--ink);
  font-size: 1.12rem;
  max-width: 34rem;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin: 1.3rem 0 0.7rem;
}

.micro {
  color: var(--muted);
  font-size: 0.95rem;
}

.stage {
  display: flex;
  justify-content: center;
}

.portrait {
  position: relative;
  width: min(100%, 460px);
}

.portrait img {
  width: 100%;
  border-radius: 50%;
  background: var(--sky-deep);
}

.sticker {
  position: absolute;
  width: 74px;
  height: 74px;
  background: var(--white);
  border: 3px solid var(--sand);
  border-radius: 22px;
  padding: 10px;
}

.cam {
  top: 8%;
  left: -8%;
}

.trophy {
  top: 4%;
  right: -4%;
}

.gift {
  bottom: 18%;
  right: -8%;
}

.people {
  bottom: 12%;
  left: -6%;
}

.trust {
  list-style: none;
  display: flex;
  flex-wrap: wrap;
  gap: 0.8rem 1.4rem;
  margin: 0;
  padding: 0.4rem 0 0.2rem;
  color: var(--ink);
}

.trust li {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  font-weight: 800;
}

.dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--lime);
  border: 2px solid var(--white);
  box-shadow: 0 0 0 2px var(--teal);
}

.supervision {
  margin: 0.35rem 0 0.4rem;
  color: var(--ink);
  font-weight: 800;
  max-width: 40rem;
}

@media (min-width: 900px) {
  .grid {
    grid-template-columns: 1.05fr 0.95fr;
    padding-top: 3.2rem;
    min-height: 560px;
  }
}
</style>
