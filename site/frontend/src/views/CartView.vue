<script setup>
import { RouterLink } from 'vue-router'
import { useCartStore } from '@/stores/cart'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const cart = useCartStore()

function money(n) {
  return `KES ${Number(n).toLocaleString('en-KE', { maximumFractionDigits: 0 })}`
}
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl">
    <h1 class="font-headline-md text-headline-md mb-lg">Your Cart</h1>

    <div v-if="!cart.items.length" class="text-center py-xl bg-surface-container-lowest rounded-xl">
      <span class="w-16 h-16 rounded-full bg-surface-container text-outline flex items-center justify-center mx-auto mb-md"><MaterialIcon name="shopping_cart" /></span>
      <p class="text-on-surface-variant mb-md">Your cart is empty.</p>
      <RouterLink to="/buy" class="inline-block bg-primary text-on-primary font-label-sm text-label-sm px-lg py-3 rounded-full">Browse products</RouterLink>
    </div>

    <div v-else class="grid lg:grid-cols-3 gap-lg">
      <!-- Items -->
      <div class="lg:col-span-2 flex flex-col gap-md">
        <div
          v-for="item in cart.items"
          :key="item.productId"
          class="bg-surface-container-lowest rounded-xl p-md shadow-low flex flex-wrap items-center gap-sm sm:gap-md"
        >
          <div class="flex-1 min-w-[8rem]">
            <RouterLink :to="`/product/${item.slug}`" class="font-headline-sm text-headline-sm hover:text-primary">{{ item.name }}</RouterLink>
            <p class="text-on-surface-variant font-body-md">{{ money(item.unitPrice) }} / {{ item.unit }}</p>
            <p v-if="(item.minOrderQty || 1) > 1" class="text-on-surface-variant font-body-md text-[12px]">Min order: {{ item.minOrderQty }} {{ item.unit }}</p>
          </div>
          <div class="flex items-center border border-outline-variant rounded-full">
            <button
              class="w-9 h-9 flex items-center justify-center text-primary disabled:opacity-40 disabled:cursor-not-allowed"
              :disabled="item.quantity <= (item.minOrderQty || 1)"
              @click="cart.updateQuantity(item.productId, item.quantity - 1)"
            ><MaterialIcon name="remove" /></button>
            <span class="w-10 text-center font-body-md">{{ item.quantity }}</span>
            <button class="w-9 h-9 flex items-center justify-center text-primary" @click="cart.updateQuantity(item.productId, item.quantity + 1)"><MaterialIcon name="add" /></button>
          </div>
          <div class="text-right font-bold text-primary whitespace-nowrap ml-auto sm:ml-0 sm:w-24">{{ money(item.unitPrice * item.quantity) }}</div>
          <button class="text-on-surface-variant hover:text-error shrink-0" @click="cart.remove(item.productId)"><MaterialIcon name="delete" /></button>
        </div>
      </div>

      <!-- Summary -->
      <div class="bg-surface-container-lowest rounded-xl p-lg shadow-low h-fit">
        <h2 class="font-headline-sm text-headline-sm mb-md">Order Summary</h2>
        <div class="flex justify-between font-body-md mb-xs">
          <span class="text-on-surface-variant">Subtotal</span>
          <span class="font-bold">{{ money(cart.subtotal) }}</span>
        </div>
        <p class="text-on-surface-variant font-body-md text-[13px] mb-md">Delivery fee calculated at checkout.</p>
        <RouterLink to="/checkout/sign-in" class="block text-center bg-accent text-white font-label-sm text-label-sm py-3 rounded-full hover:bg-accent-dark transition-colors">
          Proceed to Checkout
        </RouterLink>
        <RouterLink to="/buy" class="block text-center text-primary font-label-sm text-label-sm mt-md">Continue shopping</RouterLink>
      </div>
    </div>
  </section>
</template>
