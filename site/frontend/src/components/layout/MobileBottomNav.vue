<script setup>
import { RouterLink } from 'vue-router'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const items = [
  { to: '/', label: 'Home', icon: 'home' },
  { to: '/services', label: 'Services', icon: 'storefront' },
  { to: '/impact', label: 'Impact', icon: 'analytics' },
  { to: '/account', label: 'Account', icon: 'person' },
]
</script>

<template>
  <div
    class="md:hidden fixed bottom-0 left-0 right-0 bg-surface shadow-lg flex justify-around items-center py-3 z-50 border-t border-outline-variant/10"
  >
    <RouterLink
      v-for="item in items"
      :key="item.to"
      :to="item.to"
      class="flex flex-col items-center gap-1 text-on-surface-variant"
      active-class="!text-primary"
    >
      <MaterialIcon :name="item.icon" />
      <span class="text-[10px]">{{ item.label }}</span>
    </RouterLink>
  </div>
</template>
