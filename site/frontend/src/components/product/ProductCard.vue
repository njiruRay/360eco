<script setup>
import { ref, computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useCartStore } from '@/stores/cart'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const props = defineProps({
  product: { type: Object, required: true },
})

const cart = useCartStore()

const minQty = computed(() => Number(props.product.minOrderQty) || 1)
const qty = ref(minQty.value)
const added = ref(false)

function dec() {
  qty.value = Math.max(minQty.value, Number(qty.value) - 1)
}
function inc() {
  qty.value = Number(qty.value) + 1
}

function addToCart() {
  cart.add(
    {
      id: props.product.id,
      name: props.product.name,
      slug: props.product.slug,
      price: Number(props.product.price),
      unit: props.product.unit,
      minOrderQty: minQty.value,
    },
    Number(qty.value) || minQty.value,
  )
  added.value = true
  setTimeout(() => (added.value = false), 2000)
}

function money(n) {
  return `KES ${Number(n).toLocaleString('en-KE', { maximumFractionDigits: 0 })}`
}
</script>

<template>
  <div class="bg-surface-container-lowest rounded-xl shadow-low shadow-hover transition-all overflow-hidden flex flex-col">
    <!-- Blank image area (product photos to be added later) -->
    <RouterLink
      :to="`/product/${product.slug}`"
      class="relative h-48 bg-surface-container flex items-center justify-center text-outline"
    >
      <MaterialIcon name="image" />
      <span
        v-if="product.categoryName"
        class="absolute top-3 right-3 bg-secondary-container text-on-secondary-container text-[12px] font-bold px-3 py-1 rounded-full uppercase tracking-wider"
      >
        {{ product.categoryName }}
      </span>
    </RouterLink>

    <div class="p-md flex flex-col flex-grow">
      <RouterLink :to="`/product/${product.slug}`" class="font-headline-sm text-headline-sm mb-2 hover:text-primary">
        {{ product.name }}
      </RouterLink>
      <p class="font-body-md text-on-surface-variant line-clamp-2 mb-4">{{ product.description }}</p>

      <div class="mt-auto">
        <span class="font-headline-sm text-headline-sm text-primary mb-4 block">{{ money(product.price) }}/{{ product.unit }}</span>

        <div class="flex items-center gap-2 mb-4">
          <div class="flex items-center border border-outline-variant rounded-lg overflow-hidden">
            <button type="button" class="px-3 py-1 text-primary hover:bg-surface-container-high" @click="dec"><MaterialIcon name="remove" /></button>
            <input v-model.number="qty" type="number" :min="minQty" class="w-16 text-center border-none font-body-md focus:ring-0 bg-transparent" />
            <button type="button" class="px-3 py-1 text-primary hover:bg-surface-container-high" @click="inc"><MaterialIcon name="add" /></button>
          </div>
          <span class="text-on-surface-variant font-label-sm">{{ product.unit }}</span>
        </div>

        <div class="flex flex-col gap-2">
          <button
            type="button"
            class="w-full py-3 rounded-full font-label-sm text-label-sm text-white flex items-center justify-center gap-2 transition-colors disabled:opacity-50"
            :class="added ? 'bg-primary' : 'bg-accent hover:bg-accent-dark'"
            :disabled="!product.inStock"
            @click="addToCart"
          >
            <MaterialIcon :name="added ? 'check_circle' : 'add_shopping_cart'" />
            {{ added ? 'Added to Cart' : (product.inStock ? 'Add to Cart' : 'Out of Stock') }}
          </button>
          <RouterLink :to="`/product/${product.slug}`" class="text-center font-label-sm text-label-sm text-primary underline underline-offset-4 hover:opacity-80">
            View Details
          </RouterLink>
        </div>
      </div>
    </div>
  </div>
</template>
