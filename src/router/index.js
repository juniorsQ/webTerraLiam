import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '@/views/HomeView.vue'
import LegalPageView from '@/views/LegalPageView.vue'
import AdminLoginView from '@/views/AdminLoginView.vue'
import AdminHomeView from '@/views/AdminHomeView.vue'
import AdminSectionView from '@/views/AdminSectionView.vue'
import AdminLegalView from '@/views/AdminLegalView.vue'

const legal = (path, name, slug) => ({
  path,
  name,
  component: LegalPageView,
  meta: { slug },
})

const router = createRouter({
  history: createWebHistory(),
  scrollBehavior(to) {
    if (to.hash) {
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
    { path: '/admin', name: 'admin', component: AdminHomeView },
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

export default router
