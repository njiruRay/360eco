<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useCartStore } from '@/stores/cart'
import { useAuthStore } from '@/stores/auth'
import { createOrder } from '@/api/orders'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'
import LocationPicker from '@/components/LocationPicker.vue'

const cart = useCartStore()
const auth = useAuthStore()
const router = useRouter()

const form = reactive({
  customerName: auth.user?.fullName || '',
  customerPhone: auth.user?.phone || '',
  location: { lat: null, lng: null, address: '' },
  paymentMethod: 'cash_on_delivery',
})

const fieldErrors = reactive({ customerName: '', customerPhone: '', location: '' })
const nameInput = ref(null)
const phoneInput = ref(null)
const locationSection = ref(null)

const paymentOptions = [
  { value: 'cash_on_delivery', label: 'Cash on Delivery', icon: 'local_shipping' },
  { value: 'cash_in_person', label: 'Cash in Person', icon: 'storefront' },
  { value: 'bitcoin', label: 'Bitcoin', icon: 'currency_bitcoin' },
]

const busy = ref(false)
const error = ref('')

function money(n) {
  return `KES ${Number(n).toLocaleString('en-KE', { maximumFractionDigits: 0 })}`
}

onMounted(() => {
  if (!cart.items.length) router.replace('/cart')
})

function validate() {
  fieldErrors.customerName = form.customerName.trim() ? '' : 'Please enter your full name.'
  fieldErrors.customerPhone = form.customerPhone.trim() ? '' : 'Please enter your phone number.'
  const hasLocation = form.location.lat != null || (form.location.address || '').trim() !== ''
  fieldErrors.location = hasLocation ? '' : 'Please set your delivery location — use the map pin.'

  if (fieldErrors.customerName) {
    nameInput.value?.focus()
    return false
  }
  if (fieldErrors.customerPhone) {
    phoneInput.value?.focus()
    return false
  }
  if (fieldErrors.location) {
    locationSection.value?.scrollIntoView({ behavior: 'smooth', block: 'center' })
    return false
  }
  return true
}

async function placeOrder() {
  error.value = ''
  if (!validate()) {
    error.value = 'Please fill in the highlighted fields before placing your order.'
    return
  }
  busy.value = true
  try {
    const payload = {
      customerName: form.customerName.trim(),
      customerPhone: form.customerPhone.trim(),
      deliveryAddress: (form.location.address || '').trim(),
      deliveryLat: form.location.lat,
      deliveryLng: form.location.lng,
      paymentMethod: form.paymentMethod,
      items: cart.items.map((i) => ({ productId: i.productId, quantity: i.quantity })),
    }
    const order = await createOrder(payload)
    cart.clear()
    router.replace({ name: 'checkout-confirmation', query: { ref: order.reference } })
  } catch (e) {
    error.value = e?.response?.data?.message || 'Could not place your order. Please try again.'
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl grid lg:grid-cols-3 gap-lg">
    <!-- Form -->
    <form class="lg:col-span-2 flex flex-col gap-lg" @submit.prevent="placeOrder">
      <div class="bg-surface-container-lowest rounded-xl p-lg shadow-low">
        <h2 class="font-headline-sm text-headline-sm mb-md">Delivery Details</h2>
        <div class="grid sm:grid-cols-2 gap-md">
          <label class="flex flex-col gap-xs">
            <span class="font-label-sm text-label-sm text-on-surface-variant">Full name</span>
            <input
              ref="nameInput"
              v-model="form.customerName"
              class="rounded-lg focus:border-primary focus:ring-primary"
              :class="fieldErrors.customerName ? 'border-error' : 'border-outline-variant'"
            />
            <span v-if="fieldErrors.customerName" class="text-error font-body-md text-[12px]">{{ fieldErrors.customerName }}</span>
          </label>
          <label class="flex flex-col gap-xs">
            <span class="font-label-sm text-label-sm text-on-surface-variant">Phone</span>
            <input
              ref="phoneInput"
              v-model="form.customerPhone"
              inputmode="tel"
              class="rounded-lg focus:border-primary focus:ring-primary"
              :class="fieldErrors.customerPhone ? 'border-error' : 'border-outline-variant'"
            />
            <span v-if="fieldErrors.customerPhone" class="text-error font-body-md text-[12px]">{{ fieldErrors.customerPhone }}</span>
          </label>
        </div>

        <!-- Map location picker -->
        <div ref="locationSection" class="mt-md">
          <span class="font-label-sm text-label-sm text-on-surface-variant">Delivery location</span>
          <div class="mt-xs" :class="fieldErrors.location ? 'ring-2 ring-error rounded-lg p-2' : ''">
            <LocationPicker v-model="form.location" />
          </div>
          <span v-if="fieldErrors.location" class="text-error font-body-md text-[12px]">{{ fieldErrors.location }}</span>
        </div>
      </div>

      <div class="bg-surface-container-lowest rounded-xl p-lg shadow-low">
        <h2 class="font-headline-sm text-headline-sm mb-md">Payment Method</h2>
        <div class="flex flex-col gap-sm">
          <label
            v-for="opt in paymentOptions"
            :key="opt.value"
            class="flex items-center gap-md p-md rounded-lg border cursor-pointer transition-colors"
            :class="form.paymentMethod === opt.value ? 'border-primary bg-primary/5' : 'border-outline-variant'"
          >
            <input v-model="form.paymentMethod" type="radio" :value="opt.value" class="text-primary focus:ring-primary" />
            <MaterialIcon :name="opt.icon" />
            <span class="font-body-md">{{ opt.label }}</span>
          </label>
        </div>
        <p class="text-on-surface-variant font-body-md text-[13px] mt-md">No online payment — pay with cash on delivery / in person, or Bitcoin by arrangement.</p>
      </div>

      <p v-if="error" class="text-error font-body-md">{{ error }}</p>
    </form>

    <!-- Summary -->
    <div class="bg-surface-container-lowest rounded-xl p-lg shadow-low h-fit">
      <h2 class="font-headline-sm text-headline-sm mb-md">Review Order</h2>
      <div class="flex flex-col gap-sm mb-md">
        <div v-for="item in cart.items" :key="item.productId" class="flex justify-between font-body-md">
          <span class="text-on-surface-variant">{{ item.name }} × {{ item.quantity }}</span>
          <span class="font-semibold whitespace-nowrap">{{ money(item.unitPrice * item.quantity) }}</span>
        </div>
      </div>
      <div class="flex justify-between border-t border-outline-variant pt-md font-body-md">
        <span class="text-on-surface-variant">Subtotal</span>
        <span class="font-bold">{{ money(cart.subtotal) }}</span>
      </div>
      <p class="text-on-surface-variant font-body-md text-[13px] mt-xs mb-md">+ delivery fee, added on confirmation.</p>
      <button
        type="button"
        :disabled="busy || !cart.items.length"
        class="w-full bg-accent text-white font-label-sm text-label-sm py-3 rounded-full hover:bg-accent-dark transition-colors disabled:opacity-50"
        @click="placeOrder"
      >
        {{ busy ? 'Placing order…' : 'Place Order' }}
      </button>
      <RouterLink to="/cart" class="block text-center text-primary font-label-sm text-label-sm mt-md">Back to cart</RouterLink>
    </div>
  </section>
</template>
