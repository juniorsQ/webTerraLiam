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
        <span><strong>TerraLiam</strong><small>OPS CONTROL</small></span>
      </router-link>
      <div class="side-label">Control room</div>
      <nav class="side-nav" aria-label="Navegacion Ops">
        <router-link class="side-link" :class="{ active: current === 'overview' }" to="/ops" @click="open = false">
          <span class="nav-mark">+</span>Overview
        </router-link>
        <router-link
          v-for="resource in resources"
          :key="resource.key"
          class="side-link"
          :class="{ active: current === resource.key }"
          :to="`/ops/${resource.key}`"
          @click="open = false"
        >
          <span class="nav-mark">{{ resource.mark }}</span>{{ resource.label }}
        </router-link>
      </nav>
      <div class="sidebar-spacer" />
      <div class="operator-card"><span class="live-dot" /><div><strong>Platform admin</strong><small>Sesión protegida</small></div></div>
      <button class="signout" type="button" @click="onSignOut">Cerrar sesión <span>↗</span></button>
    </aside>

    <section class="ops-content">
      <slot />
    </section>
  </main>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { opsResources } from '@/ops/opsUi'
import { useOpsSession } from '@/ops/useOpsSession'

const route = useRoute()
const router = useRouter()
const { signOut } = useOpsSession()
const open = ref(false)
const resources = opsResources
const current = computed(() => (route.name === 'ops-dashboard' ? 'overview' : String(route.params.resource || '')))

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
.ops-sidebar { width: 244px; display: flex; flex-direction: column; padding: 1.6rem 1rem; border-right: 1px solid var(--ops-line); background: rgba(8,12,25,.94); }
.brand { display: flex; align-items: center; gap: .7rem; padding: 0 .55rem 2.4rem; color: var(--ops-text); text-decoration: none; }
.brand img { width: 38px; height: 38px; border-radius: 12px; object-fit: cover; }
.brand span { display: grid; gap: .12rem; }
.brand strong { font-family: var(--font-display); font-size: 1.15rem; }
.brand small, .operator-card small { color: var(--ops-muted); font-size: .62rem; letter-spacing: .13em; }
.side-label { padding: 0 .65rem .65rem; color: var(--ops-muted); font-size: .64rem; font-weight: 900; letter-spacing: .13em; text-transform: uppercase; }
.side-nav { display: grid; gap: .2rem; }
.side-link { display: flex; align-items: center; gap: .7rem; min-height: 42px; padding: .55rem .65rem; border-radius: 9px; color: var(--ops-muted); font-size: .9rem; text-decoration: none; }
.side-link:hover, .side-link.active { background: var(--ops-panel-2); color: var(--ops-text); text-decoration: none; }
.side-link.active { box-shadow: inset 2px 0 var(--ops-cyan); }
.nav-mark { display: inline-grid; place-items: center; width: 23px; color: var(--ops-cyan); }
.sidebar-spacer { flex: 1; }
.operator-card { display: flex; align-items: center; gap: .65rem; padding: .8rem; border: 1px solid var(--ops-line); border-radius: 10px; background: var(--ops-panel); }
.operator-card div { display: grid; gap: .15rem; }
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
