import { createRouter, createWebHistory } from 'vue-router'

// Route-level code splitting: each storefront page is lazy-loaded.
const routes = [
  { path: '/', name: 'home', component: () => import('@/views/HomeView.vue') },
  { path: '/about', name: 'about', component: () => import('@/views/AboutView.vue') },
  { path: '/impact', name: 'impact', component: () => import('@/views/ImpactView.vue') },
  { path: '/contact', name: 'contact', component: () => import('@/views/ContactView.vue') },
  { path: '/services', name: 'services', component: () => import('@/views/ServicesView.vue') },
  { path: '/buy', name: 'buy', component: () => import('@/views/BuyFromUsView.vue') },
  { path: '/sell', name: 'sell', component: () => import('@/views/SellToUsView.vue') },
  {
    path: '/product/:slug',
    name: 'product',
    component: () => import('@/views/ProductDetailView.vue'),
  },
  { path: '/cart', name: 'cart', component: () => import('@/views/CartView.vue') },
  {
    path: '/checkout/sign-in',
    name: 'checkout-sign-in',
    component: () => import('@/views/checkout/SignInGateView.vue'),
  },
  {
    path: '/reset-password',
    name: 'reset-password',
    component: () => import('@/views/ResetPasswordView.vue'),
  },
  {
    path: '/checkout/delivery',
    name: 'checkout-delivery',
    component: () => import('@/views/checkout/DeliveryPaymentView.vue'),
  },
  {
    path: '/checkout/confirmation',
    name: 'checkout-confirmation',
    component: () => import('@/views/checkout/OrderConfirmationView.vue'),
  },
  {
    path: '/account',
    name: 'account',
    component: () => import('@/views/AccountView.vue'),
    meta: { requiresAuth: true },
  },
  { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/views/NotFoundView.vue') },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 }),
})

// Redirect unauthenticated users away from protected routes to the sign-in gate.
router.beforeEach((to) => {
  if (to.meta.requiresAuth) {
    const token = localStorage.getItem('auth_token')
    if (!token) {
      return { name: 'checkout-sign-in', query: { redirect: to.fullPath } }
    }
  }
  return true
})

export default router
