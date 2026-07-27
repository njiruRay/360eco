<script setup>
import { RouterLink } from 'vue-router'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const values = [
  { icon: 'groups', title: 'Community-led collection', text: 'We build waste-collection models around partner clubs — schools, youth groups and community organisations.' },
  { icon: 'verified', title: 'Industrial-grade quality', text: 'Our cullet and briquettes are sorted, cleaned and processed to meet manufacturer standards.' },
  { icon: 'insights', title: 'Transparent impact', text: 'Every tonne diverted and job created is tracked and reported openly.' },
]
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl">
    <span class="inline-block px-3 py-1 bg-secondary-container text-on-secondary-container rounded-full text-[12px] font-bold mb-xs">OUR MISSION</span>
    <h1 class="font-headline-md text-headline-md mb-md max-w-2xl">Solving waste through innovation</h1>
    <p class="font-body-lg text-body-lg text-on-surface-variant max-w-3xl mb-lg">
      360 Econovations is a Kenyan waste-to-value enterprise based in Embu County. We were born from a
      simple observation: massive amounts of glass and biomass waste were being discarded while
      manufacturers struggled for raw materials. We bridge that gap with a closed-loop system that
      supports both the economy and the environment.
    </p>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-md mt-lg">
      <div v-for="v in values" :key="v.title" class="bg-surface-container-lowest rounded-xl p-md shadow-low">
        <div class="w-12 h-12 rounded-full bg-primary/10 text-primary flex items-center justify-center mb-md">
          <MaterialIcon :name="v.icon" />
        </div>
        <h3 class="font-headline-sm text-headline-sm mb-xs">{{ v.title }}</h3>
        <p class="text-on-surface-variant font-body-md">{{ v.text }}</p>
      </div>
    </div>

    <div class="mt-xl bg-surface-container rounded-3xl p-lg md:p-xl flex flex-col md:flex-row items-center justify-between gap-lg">
      <div>
        <h2 class="font-headline-sm text-headline-sm mb-xs">Want to work with us?</h2>
        <p class="text-on-surface-variant">Buy recycled products or sell us your used bottles and organic waste.</p>
      </div>
      <RouterLink to="/services" class="bg-accent text-white font-label-sm text-label-sm px-lg py-4 rounded-full hover:bg-accent-dark transition-all whitespace-nowrap">
        Explore Services
      </RouterLink>
    </div>
  </section>
</template>
