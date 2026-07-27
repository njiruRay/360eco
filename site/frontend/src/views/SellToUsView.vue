<script setup>
import { ref, onMounted } from 'vue'
import { fetchContent } from '@/api/content'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const data = ref(null)
const loading = ref(true)

onMounted(async () => {
  try {
    data.value = await fetchContent('sell_to_us', 'buying_prices')
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl">
    <div class="mb-lg">
      <span class="inline-block px-3 py-1 bg-tertiary-fixed text-on-tertiary-fixed-variant rounded-full text-[12px] font-bold mb-xs">SELL TO US</span>
      <h1 class="font-headline-md text-headline-md">{{ data?.title || 'We Buy Your Used Bottles' }}</h1>
      <p class="text-on-surface-variant font-body-lg mt-xs">
        Bring us your used glass bottles and earn. Below are our current buying prices per bottle.
      </p>
    </div>

    <p v-if="loading" class="text-on-surface-variant">Loading prices…</p>

    <div v-else-if="data" class="grid md:grid-cols-2 gap-md">
      <div class="bg-surface-container-lowest rounded-xl shadow-low overflow-hidden">
        <table class="w-full text-left">
          <thead class="bg-surface-container">
            <tr>
              <th class="px-md py-3 font-label-sm text-label-sm text-on-surface-variant uppercase">Bottle Type</th>
              <th class="px-md py-3 font-label-sm text-label-sm text-on-surface-variant uppercase text-right">Price</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(item, i) in data.items" :key="i" class="border-t border-outline-variant/40">
              <td class="px-md py-3 font-body-md">{{ item.type }}</td>
              <td class="px-md py-3 font-bold text-primary text-right whitespace-nowrap">
                {{ data.currency || 'KES' }} {{ item.price }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="flex flex-col gap-md">
        <div class="bg-primary text-on-primary rounded-xl p-lg">
          <h3 class="font-headline-sm text-headline-sm mb-xs">How it works</h3>
          <ol class="flex flex-col gap-sm mt-md">
            <li class="flex items-start gap-sm"><MaterialIcon name="looks_one" /> Collect and sort your used glass bottles.</li>
            <li class="flex items-start gap-sm"><MaterialIcon name="looks_two" /> Bring them to our nearest collection point.</li>
            <li class="flex items-start gap-sm"><MaterialIcon name="looks_3" /> Get paid on the spot at the prices listed.</li>
          </ol>
        </div>

        <div v-if="data.organic_waste" class="bg-tertiary-fixed text-on-tertiary-fixed-variant rounded-xl p-lg flex items-center gap-md">
          <MaterialIcon name="compost" />
          <div>
            <h4 class="font-headline-sm text-headline-sm">Organic Waste</h4>
            <p class="font-body-md">{{ data.organic_waste.note || 'Coming soon' }}</p>
          </div>
        </div>
      </div>
    </div>

    <p v-else class="text-on-surface-variant">Buying prices are not available right now.</p>
  </section>
</template>
