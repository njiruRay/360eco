<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { fetchOrder } from '@/api/orders'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const route = useRoute()
const order = ref(null)
const loading = ref(true)

function money(n) {
  return `KES ${Number(n).toLocaleString('en-KE', { maximumFractionDigits: 0 })}`
}

const paymentLabel = (m) =>
  ({ cash_on_delivery: 'Cash on Delivery', cash_in_person: 'Cash in Person', bitcoin: 'Bitcoin' })[m] || m

onMounted(async () => {
  const ref_ = route.query.ref
  if (!ref_) {
    loading.value = false
    return
  }
  try {
    order.value = await fetchOrder(ref_)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <section class="max-w-2xl mx-auto px-margin-mobile py-xl">
    <p v-if="loading" class="text-on-surface-variant text-center">Loading your order…</p>

    <div v-else-if="order" class="bg-surface-container-lowest rounded-xl p-lg shadow-low text-center">
      <span class="w-20 h-20 rounded-full bg-primary/10 text-primary flex items-center justify-center mx-auto mb-md">
        <MaterialIcon name="check_circle" filled />
      </span>
      <h1 class="font-headline-md text-headline-md mb-xs">Order Received!</h1>
      <p class="text-on-surface-variant mb-md">Thank you, {{ order.customerName }}. We'll contact you to arrange delivery.</p>

      <div class="inline-block bg-primary/5 border border-primary/20 rounded-lg px-lg py-md mb-lg">
        <div class="font-label-sm text-label-sm text-on-surface-variant uppercase">Order Reference</div>
        <div class="font-display-lg-mobile text-display-lg-mobile font-bold text-primary tracking-wider">{{ order.reference }}</div>
      </div>

      <div class="text-left border-t border-outline-variant pt-md">
        <div v-for="item in order.items" :key="item.productName" class="flex justify-between font-body-md py-1">
          <span class="text-on-surface-variant">{{ item.productName }} × {{ item.quantity }}</span>
          <span class="font-semibold">{{ money(item.subtotal) }}</span>
        </div>
        <div class="flex justify-between font-body-md py-1 mt-xs border-t border-outline-variant/40">
          <span class="text-on-surface-variant">Subtotal</span><span>{{ money(order.subtotal) }}</span>
        </div>
        <div class="flex justify-between font-body-md py-1">
          <span class="text-on-surface-variant">Delivery fee</span><span>{{ money(order.deliveryFee) }}</span>
        </div>
        <div class="flex justify-between font-headline-sm text-headline-sm py-1 text-primary">
          <span>Total</span><span>{{ money(order.totalAmount) }}</span>
        </div>
        <p class="text-on-surface-variant font-body-md mt-md">Payment: <strong>{{ paymentLabel(order.paymentMethod) }}</strong></p>
      </div>

      <div class="flex flex-col sm:flex-row gap-md justify-center mt-lg">
        <RouterLink to="/buy" class="bg-primary text-on-primary font-label-sm text-label-sm px-lg py-3 rounded-full">Continue Shopping</RouterLink>
        <RouterLink to="/account" class="border-2 border-primary text-primary font-label-sm text-label-sm px-lg py-3 rounded-full">View My Orders</RouterLink>
      </div>
    </div>

    <div v-else class="text-center py-xl">
      <h1 class="font-headline-sm text-headline-sm mb-xs">No order to show</h1>
      <RouterLink to="/buy" class="text-primary font-label-sm">Go to products</RouterLink>
    </div>
  </section>
</template>
