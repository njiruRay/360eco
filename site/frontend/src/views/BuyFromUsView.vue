<script setup>
import { ref, onMounted, computed } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchProducts, fetchCategories } from '@/api/catalog'
import ProductCard from '@/components/product/ProductCard.vue'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const products = ref([])
const categories = ref([])
const activeCategory = ref('')
const sort = ref('newest')
const loading = ref(true)
const error = ref(false)

const filtered = computed(() => {
  let list = activeCategory.value
    ? products.value.filter((p) => p.categorySlug === activeCategory.value)
    : products.value
  if (sort.value === 'price-asc') list = [...list].sort((a, b) => a.price - b.price)
  else if (sort.value === 'price-desc') list = [...list].sort((a, b) => b.price - a.price)
  return list
})

const load = async () => {
  loading.value = true
  error.value = false
  try {
    ;[products.value, categories.value] = await Promise.all([fetchProducts(), fetchCategories()])
  } catch (e) {
    error.value = true
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-lg">
    <!-- Breadcrumb -->
    <nav class="flex items-center gap-xs mb-md font-label-sm text-label-sm text-on-surface-variant">
      <RouterLink to="/services" class="hover:text-primary">Services</RouterLink>
      <MaterialIcon name="chevron_right" />
      <span class="text-on-surface font-bold">Buy From Us</span>
    </nav>

    <!-- Header -->
    <div class="mb-xl">
      <h1 class="font-display-lg text-display-lg-mobile md:text-display-lg text-primary mb-2">Buy From Us</h1>
      <p class="font-body-lg text-body-lg text-on-surface-variant max-w-2xl">
        Premium recycled materials engineered for a circular economy. Browse our selection of
        sustainable glass cullet and eco-friendly briquettes.
      </p>
    </div>

    <div class="flex flex-col md:flex-row gap-lg">
      <!-- Sidebar filters -->
      <aside class="w-full md:w-64 flex-shrink-0 flex flex-col gap-md">
        <div class="bg-surface-container-low rounded-xl p-md">
          <h3 class="font-headline-sm text-headline-sm mb-4">Categories</h3>
          <ul class="flex flex-col gap-2">
            <li>
              <button
                class="w-full text-left font-label-sm text-label-sm py-2 px-3 rounded-lg transition-colors"
                :class="activeCategory === '' ? 'bg-primary text-on-primary' : 'text-on-surface-variant hover:bg-surface-variant'"
                @click="activeCategory = ''"
              >
                All Products
              </button>
            </li>
            <li v-for="c in categories" :key="c.id">
              <button
                class="w-full text-left font-label-sm text-label-sm py-2 px-3 rounded-lg transition-colors"
                :class="activeCategory === c.slug ? 'bg-primary text-on-primary' : 'text-on-surface-variant hover:bg-surface-variant'"
                @click="activeCategory = c.slug"
              >
                {{ c.name }}
              </button>
            </li>
          </ul>
        </div>

        <div class="bg-surface-container-low rounded-xl p-md">
          <h3 class="font-headline-sm text-headline-sm mb-4">Sort By</h3>
          <select
            v-model="sort"
            class="w-full bg-surface-bright border-outline-variant rounded-lg font-body-md py-2 px-3 focus:ring-primary focus:border-primary"
          >
            <option value="newest">Newest Arrivals</option>
            <option value="price-asc">Price: Low to High</option>
            <option value="price-desc">Price: High to Low</option>
          </select>
        </div>

        <!-- Sell To Us cross-link -->
        <div class="bg-tertiary-fixed rounded-xl p-md">
          <h3 class="font-headline-sm text-headline-sm mb-xs text-on-tertiary-fixed-variant">Have waste to sell?</h3>
          <p class="font-body-md text-on-tertiary-fixed-variant/80 mb-md text-sm">
            We also buy used bottles and organic waste from clubs and individuals.
          </p>
          <RouterLink
            to="/sell"
            class="flex items-center gap-xs font-label-sm text-label-sm text-on-tertiary-fixed-variant font-bold hover:underline"
          >
            Sell To Us <MaterialIcon name="arrow_forward" />
          </RouterLink>
        </div>
      </aside>

      <!-- Product grid -->
      <section class="flex-grow">
        <p v-if="loading" class="text-on-surface-variant">Loading products…</p>
        <div v-else-if="error" class="bg-error-container text-on-error-container rounded-xl p-lg">
          <p class="font-headline-sm text-headline-sm mb-xs">Couldn't load products</p>
          <p class="font-body-md mb-md">We couldn't reach our catalogue just now. Please check your connection and try again.</p>
          <div class="flex flex-wrap items-center gap-md">
            <button
              type="button"
              @click="load"
              class="bg-primary text-on-primary font-label-sm text-label-sm px-lg py-3 rounded-full"
            >
              Try again
            </button>
            <RouterLink to="/contact" class="font-label-sm text-label-sm font-bold hover:underline">
              Contact us
            </RouterLink>
          </div>
        </div>
        <div v-else-if="filtered.length" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-md">
          <ProductCard v-for="p in filtered" :key="p.id" :product="p" />
        </div>
        <p v-else class="text-on-surface-variant">No products in this category yet.</p>
      </section>
    </div>
  </section>
</template>
