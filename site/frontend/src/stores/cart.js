import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'

// Shopping cart. Client-side only, persisted to localStorage so it survives
// reloads and app restarts. Items snapshot product info at add-time.
export const useCartStore = defineStore('cart', () => {
  const items = ref(JSON.parse(localStorage.getItem('cart_items') || '[]'))

  watch(items, (val) => localStorage.setItem('cart_items', JSON.stringify(val)), { deep: true })

  const count = computed(() => items.value.reduce((n, i) => n + i.quantity, 0))
  const subtotal = computed(() =>
    items.value.reduce((sum, i) => sum + i.unitPrice * i.quantity, 0),
  )

  function add(product, quantity = 1) {
    // Mirror the backend's min_order_qty rule client-side so a line can never
    // be added below the product minimum (the API rejects such orders at checkout).
    const min = Number(product.minOrderQty) || 1
    const existing = items.value.find((i) => i.productId === product.id)
    if (existing) {
      existing.quantity += quantity
    } else {
      items.value.push({
        productId: product.id,
        name: product.name,
        slug: product.slug,
        unitPrice: product.price,
        unit: product.unit,
        minOrderQty: min,
        quantity: Math.max(Number(quantity) || min, min),
      })
    }
  }

  function remove(productId) {
    items.value = items.value.filter((i) => i.productId !== productId)
  }

  function updateQuantity(productId, quantity) {
    const item = items.value.find((i) => i.productId === productId)
    // Never let a line drop below its product minimum (falls back to 1 for
    // legacy cart items persisted before minOrderQty was tracked).
    if (item) item.quantity = Math.max(item.minOrderQty || 1, quantity)
  }

  function clear() {
    items.value = []
  }

  return { items, count, subtotal, add, remove, updateQuantity, clear }
})
