<script setup>
import { ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useCartStore } from '@/stores/cart'
import { useAuthStore } from '@/stores/auth'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const cart = useCartStore()
const auth = useAuthStore()
const router = useRouter()
const mobileOpen = ref(false)

const nav = [
  { to: '/', label: 'Home' },
  { to: '/services', label: 'Services' },
  { to: '/about', label: 'About' },
  { to: '/impact', label: 'Impact' },
  { to: '/contact', label: 'Contact' },
]

function logout() {
  auth.logout()
  router.push('/')
}
</script>

<template>
  <nav
    class="sticky top-0 z-50 bg-surface shadow-sm"
  >
    <div
      class="flex justify-between items-center w-full px-margin-mobile md:px-margin-desktop py-4 max-w-content mx-auto"
    >
      <RouterLink to="/" class="flex items-center gap-xs">
        <img src="/logo.png" alt="360 Econovations logo" class="h-11 w-11 object-contain" />
        <span class="font-display-lg-mobile text-headline-sm font-bold text-primary">360 ECONOVATIONS</span>
      </RouterLink>

      <div class="hidden md:flex items-center gap-lg">
        <RouterLink
          v-for="link in nav"
          :key="link.to"
          :to="link.to"
          class="font-label-sm text-label-sm text-on-surface-variant hover:text-primary transition-colors"
          active-class="!text-primary font-bold border-b-2 border-primary pb-1"
        >
          {{ link.label }}
        </RouterLink>
      </div>

      <div class="flex items-center gap-md">
        <RouterLink to="/cart" class="relative text-on-surface-variant hover:text-primary">
          <MaterialIcon name="shopping_cart" />
          <span
            v-if="cart.count"
            class="absolute -top-2 -right-2 flex h-5 min-w-5 items-center justify-center rounded-full bg-accent px-1 text-[11px] font-bold text-white"
          >
            {{ cart.count }}
          </span>
        </RouterLink>

        <RouterLink
          v-if="!auth.isAuthenticated"
          to="/checkout/sign-in"
          class="hidden md:block font-label-sm text-label-sm px-6 py-2 rounded-full border-2 border-primary text-primary hover:bg-primary hover:text-on-primary transition-all"
        >
          Sign In
        </RouterLink>
        <template v-else>
          <RouterLink
            to="/account"
            class="hidden md:flex items-center gap-xs font-label-sm text-label-sm text-primary"
          >
            <MaterialIcon name="account_circle" />
            {{ auth.user?.fullName?.split(' ')[0] || 'Account' }}
          </RouterLink>
          <button
            class="hidden md:block font-label-sm text-label-sm text-on-surface-variant hover:text-primary"
            @click="logout"
          >
            Sign Out
          </button>
        </template>

        <button class="md:hidden text-on-surface-variant" @click="mobileOpen = !mobileOpen">
          <MaterialIcon :name="mobileOpen ? 'close' : 'menu'" />
        </button>
      </div>
    </div>

    <!-- Mobile dropdown -->
    <div v-if="mobileOpen" class="md:hidden border-t border-outline-variant/30 bg-surface">
      <div class="flex flex-col px-margin-mobile py-2">
        <RouterLink
          v-for="link in nav"
          :key="link.to"
          :to="link.to"
          class="py-3 font-label-sm text-on-surface-variant"
          active-class="!text-primary font-bold"
          @click="mobileOpen = false"
        >
          {{ link.label }}
        </RouterLink>
        <RouterLink
          v-if="!auth.isAuthenticated"
          to="/checkout/sign-in"
          class="py-3 font-label-sm text-primary font-bold"
          @click="mobileOpen = false"
        >
          Sign In
        </RouterLink>
      </div>
    </div>
  </nav>
</template>
