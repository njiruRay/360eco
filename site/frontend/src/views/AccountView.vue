<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { fetchMyOrders, confirmOrderWhatsApp } from '@/api/orders'
import { orderWhatsAppLink } from '@/utils/whatsapp'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const auth = useAuthStore()
const router = useRouter()
const orders = ref([])
const loading = ref(true)

function money(n) {
  return `KES ${Number(n).toLocaleString('en-KE', { maximumFractionDigits: 0 })}`
}

// A new order only counts as confirmed once it has been sent on WhatsApp.
const awaitingWhatsApp = (o) => o.status === 'received' && !o.whatsappSentAt

const statusStyle = (o) =>
  awaitingWhatsApp(o)
    ? 'bg-accent/15 text-accent-dark'
    : {
        received: 'bg-secondary-container text-on-secondary-container',
        processing: 'bg-tertiary-fixed text-on-tertiary-fixed-variant',
        out_for_delivery: 'bg-primary/10 text-primary',
        delivered: 'bg-primary text-on-primary',
        cancelled: 'bg-error-container text-on-error-container',
      }[o.status] || 'bg-surface-container text-on-surface-variant'

const statusLabel = (o) =>
  o.status === 'received' ? (o.whatsappSentAt ? 'confirmed' : 'not confirmed') : o.status.replace(/_/g, ' ')

// The link opens WhatsApp; this records that it was opened.
async function confirmOnWhatsApp(o) {
  o.whatsappSentAt ??= new Date().toISOString() // update the badge straight away
  try {
    o.whatsappSentAt = (await confirmOrderWhatsApp(o.reference)).whatsappSentAt
  } catch {
    // WhatsApp still opened, and the order is saved either way.
  }
}

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
            <span class="px-3 py-1 rounded-full text-[12px] font-bold capitalize" :class="statusStyle(o)">{{ statusLabel(o) }}</span>
            <RouterLink
              :to="{ path: '/contact', query: { ref: o.reference } }"
              class="px-3 py-1 rounded-full text-[12px] font-bold bg-accent text-white hover:bg-accent-dark transition-colors"
            >
              Follow Up
            </RouterLink>
          </div>
        </div>
        <div v-if="awaitingWhatsApp(o)" class="flex flex-wrap items-center justify-between gap-sm bg-[#25D366]/10 border border-[#25D366]/30 rounded-lg p-sm mb-sm">
          <span class="font-body-md text-[13px] text-on-surface">Send this order on WhatsApp to confirm it.</span>
          <a
            :href="orderWhatsAppLink(o)"
            target="_blank"
            rel="noopener"
            class="inline-flex items-center gap-xs bg-[#25D366] text-white px-3 py-1 rounded-full text-[12px] font-bold hover:brightness-95 transition-all"
            @click="confirmOnWhatsApp(o)"
          >
            <MaterialIcon name="chat" /> Confirm on WhatsApp
          </a>
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
