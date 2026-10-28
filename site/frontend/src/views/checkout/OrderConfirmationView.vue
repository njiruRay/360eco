<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { fetchOrder, confirmOrderWhatsApp } from '@/api/orders'
import { orderWhatsAppLink, PAYMENT_LABELS, WHATSAPP_DISPLAY } from '@/utils/whatsapp'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const route = useRoute()
const order = ref(null)
const loading = ref(true)

function money(n) {
  return `KES ${Number(n).toLocaleString('en-KE', { maximumFractionDigits: 0 })}`
}

const paymentLabel = (m) => PAYMENT_LABELS[m] || m

// The link itself opens WhatsApp; this only records that it was opened, which
// is what turns the order into "confirmed".
async function confirmOnWhatsApp() {
  order.value.whatsappSentAt ??= new Date().toISOString() // flip the page straight away
  try {
    order.value = await confirmOrderWhatsApp(order.value.reference)
  } catch {
    // WhatsApp still opened, and the order is saved either way.
  }
}

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
      <template v-if="order.whatsappSentAt">
        <span class="w-20 h-20 rounded-full bg-primary/10 text-primary flex items-center justify-center mx-auto mb-md">
          <MaterialIcon name="check_circle" filled />
        </span>
        <h1 class="font-headline-md text-headline-md mb-xs">Order Confirmed!</h1>
        <p class="text-on-surface-variant mb-md">Thank you, {{ order.customerName }}. We'll reply on WhatsApp to arrange delivery.</p>
      </template>
      <template v-else>
        <span class="w-20 h-20 rounded-full bg-[#25D366]/15 text-[#128C7E] flex items-center justify-center mx-auto mb-md">
          <MaterialIcon name="chat" filled />
        </span>
        <h1 class="font-headline-md text-headline-md mb-xs">One last step</h1>
        <p class="text-on-surface-variant mb-md">Send your order to us on WhatsApp to confirm it. We'll reply there to arrange delivery.</p>
      </template>

      <div class="inline-block bg-primary/5 border border-primary/20 rounded-lg px-lg py-md mb-lg">
        <div class="font-label-sm text-label-sm text-on-surface-variant uppercase">Order Reference</div>
        <div class="font-display-lg-mobile text-display-lg-mobile font-bold text-primary tracking-wider">{{ order.reference }}</div>
      </div>

      <div v-if="!order.whatsappSentAt" class="mb-lg">
        <a
          :href="orderWhatsAppLink(order)"
          target="_blank"
          rel="noopener"
          class="inline-flex items-center justify-center gap-xs bg-[#25D366] text-white font-label-sm text-label-sm px-lg py-3 rounded-full hover:brightness-95 transition-all w-full sm:w-auto"
          @click="confirmOnWhatsApp"
        >
          <MaterialIcon name="chat" /> Send Order on WhatsApp
        </a>
        <p class="text-on-surface-variant font-body-md text-[13px] mt-sm">WhatsApp not opening? Message {{ WHATSAPP_DISPLAY }} with your order reference.</p>
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

      <p v-if="order.whatsappSentAt" class="text-on-surface-variant font-body-md text-[13px] mt-md">
        Didn't press Send?
        <a :href="orderWhatsAppLink(order)" target="_blank" rel="noopener" class="text-primary font-bold hover:underline">Open WhatsApp again</a>
      </p>

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
