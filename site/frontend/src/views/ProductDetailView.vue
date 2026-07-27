<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { fetchProduct } from '@/api/catalog'
import { useCartStore } from '@/stores/cart'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const route = useRoute()
const router = useRouter()
const cart = useCartStore()

const product = ref(null)
const loading = ref(true)
const notFound = ref(false)
const qty = ref(1)
const activeTab = ref('description')
const added = ref(false)

const minQty = computed(() => Number(product.value?.minOrderQty) || 1)

async function load() {
  loading.value = true
  notFound.value = false
  try {
    product.value = await fetchProduct(route.params.slug)
    qty.value = minQty.value
  } catch (e) {
    notFound.value = true
  } finally {
    loading.value = false
  }
}

function addToCart() {
  cart.add(
    {
      id: product.value.id,
      name: product.value.name,
      slug: product.value.slug,
      price: Number(product.value.price),
      unit: product.value.unit,
      minOrderQty: minQty.value,
    },
    Number(qty.value) || minQty.value,
  )
  added.value = true
  setTimeout(() => (added.value = false), 2000)
}

onMounted(load)
watch(() => route.params.slug, load)
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl">
    <p v-if="loading" class="text-on-surface-variant">Loading…</p>

    <div v-else-if="notFound" class="text-center py-xl">
      <h1 class="font-headline-sm text-headline-sm mb-xs">Product not found</h1>
      <RouterLink to="/buy" class="text-primary font-label-sm">Back to products</RouterLink>
    </div>

    <div v-else class="grid md:grid-cols-2 gap-xl">
      <!-- Image -->
      <div class="rounded-xl overflow-hidden bg-surface-container aspect-square">
        <img v-if="product.primaryImageUrl" :src="product.primaryImageUrl" :alt="product.name" class="w-full h-full object-cover" />
        <div v-else class="w-full h-full flex items-center justify-center text-outline"><MaterialIcon name="image" /></div>
      </div>

      <!-- Details -->
      <div>
        <RouterLink to="/buy" class="text-primary font-label-sm text-label-sm flex items-center gap-xs mb-md">
          <MaterialIcon name="arrow_back" /> All products
        </RouterLink>
        <span v-if="product.categoryName" class="inline-block px-3 py-1 bg-secondary-container text-on-secondary-container rounded-full text-[12px] font-bold mb-xs">{{ product.categoryName }}</span>
        <h1 class="font-headline-md text-headline-md mb-xs">{{ product.name }}</h1>
        <div class="font-display-lg-mobile text-display-lg-mobile font-bold text-primary mb-md">
          KES {{ Number(product.price).toFixed(0) }}<span class="text-body-md text-on-surface-variant font-normal">/{{ product.unit }}</span>
        </div>

        <div class="flex items-center gap-sm mb-md">
          <span
            class="px-3 py-1 rounded-full text-[12px] font-bold"
            :class="product.inStock ? 'bg-secondary-container text-on-secondary-container' : 'bg-error-container text-on-error-container'"
          >
            {{ product.inStock ? 'In stock' : 'Out of stock' }}
          </span>
          <span class="text-on-surface-variant font-body-md">Min order: {{ minQty }} {{ product.unit }}</span>
        </div>

        <!-- Quantity + add -->
        <div class="flex items-center gap-md mb-lg">
          <div class="flex items-center border border-outline-variant rounded-full">
            <button class="w-10 h-10 flex items-center justify-center text-primary" @click="qty = Math.max(minQty, Number(qty) - 1)"><MaterialIcon name="remove" /></button>
            <input v-model.number="qty" type="number" :min="minQty" class="w-16 text-center border-0 focus:ring-0 bg-transparent" />
            <button class="w-10 h-10 flex items-center justify-center text-primary" @click="qty = Number(qty) + 1"><MaterialIcon name="add" /></button>
          </div>
          <button
            class="flex-1 bg-accent text-white font-label-sm text-label-sm py-3 rounded-full flex justify-center items-center gap-xs hover:bg-accent-dark transition-colors disabled:opacity-50"
            :disabled="!product.inStock"
            @click="addToCart"
          >
            <MaterialIcon :name="added ? 'check' : 'add_shopping_cart'" />
            {{ added ? 'Added!' : 'Add to Cart' }}
          </button>
        </div>

        <!-- Tabs -->
        <div class="border-b border-outline-variant flex gap-lg mb-md">
          <button
            v-for="tab in ['description', 'specs', 'delivery']"
            :key="tab"
            class="pb-2 font-label-sm text-label-sm capitalize border-b-2 -mb-px transition-colors"
            :class="activeTab === tab ? 'border-primary text-primary' : 'border-transparent text-on-surface-variant'"
            @click="activeTab = tab"
          >
            {{ tab === 'delivery' ? 'Delivery & Payment' : tab }}
          </button>
        </div>

        <div class="text-on-surface-variant font-body-md">
          <p v-if="activeTab === 'description'">{{ product.description }}</p>
          <ul v-else-if="activeTab === 'specs'" class="flex flex-col gap-xs">
            <li><strong class="text-on-surface">Category:</strong> {{ product.categoryName || '—' }}</li>
            <li><strong class="text-on-surface">Unit:</strong> {{ product.unit }}</li>
            <li><strong class="text-on-surface">Minimum order:</strong> {{ minQty }} {{ product.unit }}</li>
            <li><strong class="text-on-surface">Availability:</strong> {{ product.inStock ? 'In stock' : 'Out of stock' }}</li>
          </ul>
          <div v-else>
            <p class="mb-xs">Delivery across Kenya. Delivery fee shown at checkout.</p>
            <p><strong class="text-on-surface">Payment:</strong> Cash on Delivery or Cash in Person. Bitcoin also accepted.</p>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
