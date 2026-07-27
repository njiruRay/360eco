<script setup>
import { onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import AppHeader from '@/components/layout/AppHeader.vue'
import AppFooter from '@/components/layout/AppFooter.vue'
import MobileBottomNav from '@/components/layout/MobileBottomNav.vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const route = useRoute()

// Footer is hidden on the home/landing page, shown everywhere else.
const showFooter = computed(() => route.name !== 'home')

onMounted(() => {
  // Validate any stored token and refresh the profile.
  auth.refreshMe()
})
</script>

<template>
  <div class="flex min-h-screen flex-col bg-background text-on-background font-body-md">
    <AppHeader />
    <main class="flex-1">
      <RouterView />
    </main>
    <AppFooter v-if="showFooter" />
    <MobileBottomNav />
  </div>
</template>
