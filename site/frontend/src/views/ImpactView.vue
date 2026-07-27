<script setup>
import { ref, onMounted } from 'vue'
import { fetchImpact } from '@/api/content'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const impact = ref(null)
const loading = ref(true)

onMounted(async () => {
  try {
    impact.value = await fetchImpact()
  } finally {
    loading.value = false
  }
})

const stats = () => [
  { icon: 'recycling', label: 'Tonnes Glass Diverted', value: impact.value?.glassTonnesDiverted ?? '—' },
  { icon: 'home', label: 'Households Reached', value: impact.value?.householdsReached ?? '—' },
  { icon: 'work', label: 'Jobs Created', value: impact.value?.jobsCreated ?? '—' },
  { icon: 'diversity_3', label: 'Active Partner Clubs', value: impact.value?.partnerClubs ?? '—' },
  { icon: 'scale', label: 'Total Waste Collected (kg)', value: impact.value?.totalWasteKg ?? '—' },
]
</script>

<template>
  <section class="bg-gradient-to-br from-primary to-primary-container">
    <div class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl text-surface">
      <h1 class="font-display-lg-mobile md:font-display-lg text-display-lg-mobile md:text-display-lg mb-md">Our Impact</h1>
      <p class="font-body-lg text-body-lg text-surface/90 max-w-2xl">
        Real numbers behind our circular economy — waste diverted from the environment and value created
        for local communities across Kenya.
      </p>
    </div>
  </section>

  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl">
    <p v-if="loading" class="text-on-surface-variant">Loading impact data…</p>
    <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-md">
      <div
        v-for="s in stats()"
        :key="s.label"
        class="bg-surface-container-lowest rounded-xl p-lg shadow-low flex items-center gap-md"
      >
        <span class="w-14 h-14 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
          <MaterialIcon :name="s.icon" />
        </span>
        <div>
          <div class="font-display-lg-mobile text-display-lg-mobile font-bold text-primary leading-none">{{ s.value }}</div>
          <div class="font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wide mt-1">{{ s.label }}</div>
        </div>
      </div>
    </div>
  </section>
</template>
