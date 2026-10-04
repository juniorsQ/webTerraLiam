<template>
  <main class="ops-shell">
    <header class="mobile-bar">
      <router-link class="brand compact" to="/ops" aria-label="TerraLiam Ops">
        <img src="/brand/app_icon.png" alt="" />
        <span><strong>TerraLiam</strong><small>OPS</small></span>
      </router-link>
      <button class="menu-toggle" type="button" :aria-expanded="open ? 'true' : 'false'" @click="open = !open">
        {{ open ? 'Cerrar' : 'Menú' }}
      </button>
    </header>

    <div v-if="open" class="nav-backdrop" @click="open = false" />

    <aside class="ops-sidebar" :class="{ open }">
      <router-link class="brand" to="/ops" aria-label="TerraLiam Ops" @click="open = false">
        <img src="/brand/app_icon.png" alt="" />
        <span><strong>TerraLiam</strong><small>BACKOFFICE</small></span>
      </router-link>
      <div class="side-label">General</div>
      <nav class="side-nav" aria-label="Navegacion Ops">
        <router-link class="side-link" :class="{ active: current === 'overview' }" to="/ops" @click="open = false">
          <span class="nav-mark">+</span>Centro de control
        </router-link>
        <router-link class="side-link" :class="{ active: current === 'settings' }" to="/ops/settings" @click="open = false">
          <span class="nav-mark">⚙</span>Ajustes
        </router-link>
        <template v-for="group in groups" :key="group">
          <div class="side-label nested">{{ group }}</div>
          <router-link
            v-for="resource in resources.filter((item) => item.group === group)"
            :key="resource.key"
            class="side-link"
            :class="{ active: current === resource.key }"
            :to="`/ops/${resource.key}`"
            @click="open = false"
          >
            <span class="nav-mark">{{ resource.mark }}</span>{{ resource.label }}
          </router-link>
        </template>
      </nav>
      <div class="sidebar-spacer" />
      <div class="operator-card"><span class="live-dot" /><div><strong>{{ operatorEmail }}</strong><small>PLATFORM ADMIN</small></div></div>
      <button class="signout" type="button" @click="onSignOut">Cerrar sesión <span>↗</span></button>
    </aside>

    <section class="ops-content">
      <slot />
    </section>
    <OpsFeedback />
  </main>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import OpsFeedback from '@/ops/OpsFeedback.vue'
import { opsNavGroups, opsResources } from '@/ops/opsUi'
import { useOpsSession } from '@/ops/useOpsSession'

const route = useRoute()
const router = useRouter()
const { signOut, session } = useOpsSession()
const operatorEmail = computed(() => session.value?.user?.email ?? 'Platform admin')
const open = ref(false)
const resources = opsResources
const groups = opsNavGroups
const current = computed(() => {
  if (route.name === 'ops-dashboard') return 'overview'
  if (route.name === 'ops-settings') return 'settings'
  return String(route.params.resource || '')
})

watch(() => route.fullPath, () => { open.value = false })

async function onSignOut() {
  await signOut()
  router.replace('/ops/login')
}
</script>

<style scoped>
.ops-shell {
  --ops-bg: #0b1020;
  --ops-panel: #121a2d;
  --ops-panel-2: #17223a;
  --ops-line: rgba(151,168,204,.16);
  --ops-text: #eef3ff;
  --ops-muted: #8e9bb7;
  --ops-cyan: #56d7ed;
  --ops-violet: #9e8cff;
  --ops-lime: #b8e85c;
  --ops-coral: #ff7c78;
  min-height: 100vh;
  display: flex;
  background: radial-gradient(circle at 75% 0%, rgba(72,93,174,.2), transparent 35%), var(--ops-bg);
  color: var(--ops-text);
  font-family: var(--font-body);
}
.mobile-bar { display: none; }
.ops-sidebar { width: 244px; display: flex; flex-direction: column; padding: 1.6rem 1rem; border-right: 1px solid var(--ops-line); background: rgba(8,12,25,.94); overflow: auto; }
.brand { display: flex; align-items: center; gap: .7rem; padding: 0 .55rem 2.4rem; color: var(--ops-text); text-decoration: none; }
.brand img { width: 38px; height: 38px; border-radius: 12px; object-fit: cover; }
.brand span { display: grid; gap: .12rem; }
.brand strong { font-family: var(--font-display); font-size: 1.15rem; }
.brand small, .operator-card small { color: var(--ops-muted); font-size: .62rem; letter-spacing: .13em; }
.side-label { padding: 0 .65rem .65rem; color: var(--ops-muted); font-size: .64rem; font-weight: 900; letter-spacing: .13em; text-transform: uppercase; }
.side-label.nested { padding: .85rem .65rem .4rem; }
.side-nav { display: grid; gap: .2rem; }
.side-link { display: flex; align-items: center; gap: .7rem; min-height: 42px; padding: .55rem .65rem; border-radius: 9px; color: var(--ops-muted); font-size: .9rem; text-decoration: none; }
.side-link:hover, .side-link.active { background: var(--ops-panel-2); color: var(--ops-text); text-decoration: none; }
.side-link.active { box-shadow: inset 2px 0 var(--ops-cyan); }
.nav-mark { display: inline-grid; place-items: center; width: 23px; color: var(--ops-cyan); }
.sidebar-spacer { flex: 1; }
.operator-card { display: flex; align-items: center; gap: .65rem; padding: .8rem; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }
.operator-card div { display: grid; gap: .15rem; min-width: 0; }
.operator-card strong { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.operator-card strong { font-size: .78rem; }
.live-dot { width: 7px; height: 7px; border-radius: 50%; background: var(--ops-lime); box-shadow: 0 0 0 4px rgba(184,232,92,.12); }
.signout { margin-top: .65rem; padding: .85rem .65rem; border: 0; background: transparent; color: var(--ops-muted); text-align: left; font: inherit; font-size: .78rem; cursor: pointer; }
.signout span { float: right; color: var(--ops-coral); }
.ops-content { width: min(100%, 1450px); min-width: 0; padding: 2.2rem clamp(1.2rem, 4vw, 3.8rem) 4rem; }
@media (max-width: 1100px) {
  .ops-sidebar { width: 220px; }
}
@media (max-width: 900px) {
  .ops-shell { display: block; }
  .mobile-bar { position: sticky; top: 0; z-index: 30; display: flex; align-items: center; justify-content: space-between; gap: .75rem; padding: .85rem 1rem; border-bottom: 1px solid var(--ops-line); background: #080c19; }
  .brand.compact { padding: 0; }
  .brand.compact small { letter-spacing: .1em; }
  .menu-toggle { min-height: 40px; padding: .45rem .75rem; border: 1px solid var(--ops-line); border-radius: 8px; background: var(--ops-panel); color: var(--ops-text); font: inherit; font-size: .78rem; }
  .nav-backdrop { position: fixed; inset: 0; z-index: 35; background: rgba(4,8,18,.55); }
  .ops-sidebar { position: fixed; top: 0; bottom: 0; left: 0; z-index: 40; width: min(86vw, 300px); transform: translateX(-110%); transition: transform .2s ease; }
  .ops-sidebar.open { transform: none; }
  .ops-content { padding: 1.2rem 1rem 2.5rem; }
}
</style>

<style>
/* Shared Ops primitives (badges, buttons, panels) used across views. */
.ops-shell .ops-badge { display: inline-flex; align-items: center; padding: .18rem .5rem; border-radius: 99px; font-size: .66rem; font-weight: 800; letter-spacing: .03em; white-space: nowrap; background: rgba(255,255,255,.06); color: var(--ops-muted); }
.ops-shell .tone-good { background: rgba(184,232,92,.13); color: var(--ops-lime); }
.ops-shell .tone-warn { background: rgba(255,196,87,.14); color: #ffc457; }
.ops-shell .tone-bad { background: rgba(255,124,120,.14); color: var(--ops-coral); }
.ops-shell .tone-info { background: rgba(86,215,237,.13); color: var(--ops-cyan); }
.ops-shell .tone-common { background: rgba(114,160,42,.2); color: #b8e85c; }
.ops-shell .tone-rare { background: rgba(42,158,192,.22); color: #7fd8ef; }
.ops-shell .tone-epic { background: rgba(143,122,240,.22); color: #c4b8ff; }
.ops-shell .ops-btn { display: inline-flex; align-items: center; justify-content: center; gap: .4rem; min-height: 34px; padding: 0 .75rem; border: 1px solid var(--ops-line); border-radius: 8px; background: var(--ops-panel-2); color: var(--ops-text); font: inherit; font-size: .74rem; font-weight: 700; text-decoration: none; cursor: pointer; white-space: nowrap; }
.ops-shell .ops-btn:hover { border-color: rgba(86,215,237,.45); }
.ops-shell .ops-btn:disabled { opacity: .5; cursor: wait; }
.ops-shell .ops-btn.primary { border-color: transparent; background: var(--ops-cyan); color: #081018; }
.ops-shell .ops-btn.good { color: var(--ops-lime); }
.ops-shell .ops-btn.danger { color: var(--ops-coral); }
.ops-shell .ops-btn.danger:hover { border-color: rgba(255,124,120,.5); }
.ops-shell .ops-panel { min-width: 0; padding: clamp(.9rem, 2vw, 1.25rem); border: 1px solid var(--ops-line); border-radius: 12px; background: var(--ops-panel); }
.ops-shell .ops-panel-head { display: flex; align-items: center; justify-content: space-between; gap: .7rem; margin-bottom: 1rem; }
.ops-shell .ops-panel-head h3 { margin: 0; color: var(--ops-text); font-size: .98rem; }
.ops-shell .ops-panel-head p { margin: .2rem 0 0; color: var(--ops-muted); font-size: .72rem; }
.ops-shell .ops-panel-link { color: var(--ops-cyan); font-size: .72rem; text-decoration: none; white-space: nowrap; }
.ops-shell .ops-panel-link:hover { text-decoration: underline; }
.ops-shell .ops-error { padding: .8rem 1rem; border: 1px solid rgba(255,124,120,.35); border-radius: 8px; color: var(--ops-coral); background: rgba(255,124,120,.08); }
.ops-shell .ops-muted { color: var(--ops-muted); }
.ops-shell .crumb { margin: 0 0 .45rem; color: var(--ops-muted); font-size: .75rem; }
.ops-shell .crumb a { color: var(--ops-muted); text-decoration: none; }
.ops-shell .crumb a:hover { color: var(--ops-cyan); }
.ops-shell .crumb span { color: var(--ops-cyan); padding: 0 .35rem; }
</style>
