<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { fetchMyOrders } from '@/api/orders'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const auth = useAuthStore()
const router = useRouter()
const orders = ref([])
const loading = ref(true)

function money(n) {
  return `KES ${Number(n).toLocaleString('en-KE', { maximumFractionDigits: 0 })}`
}

const statusStyle = (s) =>
  ({
    received: 'bg-secondary-container text-on-secondary-container',
    processing: 'bg-tertiary-fixed text-on-tertiary-fixed-variant',
    out_for_delivery: 'bg-primary/10 text-primary',
    delivered: 'bg-primary text-on-primary',
    cancelled: 'bg-error-container text-on-error-container',
  })[s] || 'bg-surface-container text-on-surface-variant'

const statusLabel = (s) => s.replace(/_/g, ' ')

function fmtDate(iso) {
  return new Date(iso).toLocaleDateString('en-KE', { year: 'numeric', month: 'short', day: 'numeric' })
}

function logout() {
  auth.logout()
  router.push('/')
}

onMounted(async () => {
  try {
    orders.value = await fetchMyOrders()
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl">
    <!-- Profile header -->
    <div class="bg-surface-container-lowest rounded-xl p-lg shadow-low flex items-center justify-between mb-lg">
      <div class="flex items-center gap-md">
        <span class="w-14 h-14 rounded-full bg-primary text-on-primary flex items-center justify-center"><MaterialIcon name="person" /></span>
        <div>
          <h1 class="font-headline-sm text-headline-sm">{{ auth.user?.fullName || 'My Account' }}</h1>
          <p class="text-on-surface-variant font-body-md">{{ auth.user?.email }}</p>
        </div>
      </div>
      <button class="text-on-surface-variant hover:text-error font-label-sm text-label-sm flex items-center gap-xs" @click="logout">
        <MaterialIcon name="logout" /> <span class="hidden sm:inline">Sign Out</span>
      </button>
    </div>

    <h2 class="font-headline-sm text-headline-sm mb-md">My Orders</h2>
    <p v-if="loading" class="text-on-surface-variant">Loading orders…</p>

    <div v-else-if="!orders.length" class="text-center py-xl bg-surface-container-lowest rounded-xl">
      <p class="text-on-surface-variant mb-md">You haven't placed any orders yet.</p>
      <RouterLink to="/buy" class="inline-block bg-primary text-on-primary font-label-sm text-label-sm px-lg py-3 rounded-full">Start shopping</RouterLink>
    </div>

    <div v-else class="flex flex-col gap-md">
      <div v-for="o in orders" :key="o.reference" class="bg-surface-container-lowest rounded-xl p-md shadow-low">
        <div class="flex flex-wrap items-center justify-between gap-sm mb-sm">
          <div class="flex items-center gap-md">
            <span class="font-bold text-primary tracking-wide">{{ o.reference }}</span>
            <span class="font-body-md text-on-surface-variant text-[13px]">{{ fmtDate(o.createdAt) }}</span>
          </div>
          <div class="flex items-center gap-sm">
            <span class="px-3 py-1 rounded-full text-[12px] font-bold capitalize" :class="statusStyle(o.status)">{{ statusLabel(o.status) }}</span>
            <RouterLink
              :to="{ path: '/contact', query: { ref: o.reference } }"
              class="px-3 py-1 rounded-full text-[12px] font-bold bg-accent text-white hover:bg-accent-dark transition-colors"
            >
              Follow Up
            </RouterLink>
          </div>
        </div>
        <div class="flex flex-col gap-1 border-t border-outline-variant/40 pt-sm">
          <div v-for="item in o.items" :key="item.productName" class="flex justify-between font-body-md text-[14px]">
            <span class="text-on-surface-variant">{{ item.productName }} × {{ item.quantity }}</span>
            <span>{{ money(item.subtotal) }}</span>
          </div>
        </div>
        <div class="flex justify-between font-headline-sm text-headline-sm text-primary mt-sm pt-sm border-t border-outline-variant/40">
          <span>Total</span><span>{{ money(o.totalAmount) }}</span>
        </div>
      </div>
    </div>
  </section>
</template>
