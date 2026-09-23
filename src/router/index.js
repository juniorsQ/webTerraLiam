import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '@/views/HomeView.vue'
import LegalPageView from '@/views/LegalPageView.vue'
import AdminLoginView from '@/views/AdminLoginView.vue'
import AdminHomeView from '@/views/AdminHomeView.vue'
import AdminSectionView from '@/views/AdminSectionView.vue'
import AdminLegalView from '@/views/AdminLegalView.vue'
import RecoverPasswordView from '@/views/RecoverPasswordView.vue'
import OpsLoginView from '@/views/OpsLoginView.vue'
import OpsDashboardView from '@/views/OpsDashboardView.vue'
import OpsResourceView from '@/views/OpsResourceView.vue'
import OpsSettingsView from '@/views/OpsSettingsView.vue'
import { supabase } from '@/lib/supabase'

const legal = (path, name, slug) => ({
  path,
  name,
  component: LegalPageView,
  meta: { slug },
})

const router = createRouter({
  history: createWebHistory(),
  scrollBehavior(to) {
    if (to.hash && !to.hash.includes('access_token') && !to.hash.includes('type=recovery')) {
      return { el: to.hash, behavior: 'smooth' }
    }
    return { top: 0 }
  },
  routes: [
    { path: '/', name: 'home', component: HomeView },
    legal('/privacidad', 'privacy', 'privacidad'),
    legal('/terminos', 'terms', 'terminos'),
    legal('/familias', 'families', 'familias'),
    legal('/eliminar-cuenta', 'delete-account', 'eliminar-cuenta'),
    { path: '/admin/login', name: 'admin-login', component: AdminLoginView },
    {
      path: '/recuperar',
      name: 'recover-password',
      component: RecoverPasswordView,
    },
    { path: '/admin', name: 'admin', component: AdminHomeView },
    { path: '/ops/login', name: 'ops-login', component: OpsLoginView },
    { path: '/ops', name: 'ops-dashboard', component: OpsDashboardView, meta: { ops: true } },
    { path: '/ops/settings', name: 'ops-settings', component: OpsSettingsView, meta: { ops: true } },
    { path: '/ops/:resource', name: 'ops-resource', component: OpsResourceView, props: true, meta: { ops: true } },
    {
      path: '/admin/secciones/:sectionKey',
      name: 'admin-section',
      component: AdminSectionView,
      props: true,
    },
    {
      path: '/admin/paginas/:slug',
      name: 'admin-legal',
      component: AdminLegalView,
      props: true,
    },
  ],
})

router.beforeEach(async (to) => {
  if (!to.meta.ops || to.path === '/ops/login') return true
  if (!supabase) return '/ops/login'
  const { data } = await supabase.auth.getSession()
  if (data.session?.user?.app_metadata?.platform_admin === true) return true
  return '/ops/login'
})

export default router
