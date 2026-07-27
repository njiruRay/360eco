<script setup>
import { RouterLink } from 'vue-router'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl">
    <div class="text-center mb-lg">
      <h1 class="font-headline-md text-headline-md mb-xs">Our Services</h1>
      <p class="text-on-surface-variant font-body-lg max-w-2xl mx-auto">
        Two ways to join the circular economy with 360 Econovations.
      </p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-md">
      <!-- Buy From Us -->
      <RouterLink
        to="/buy"
        class="group bg-surface-container-lowest rounded-xl p-lg shadow-low shadow-hover transition-all flex flex-col"
      >
        <div class="w-16 h-16 rounded-full bg-primary text-on-primary flex items-center justify-center mb-md">
          <MaterialIcon name="shopping_bag" />
        </div>
        <h2 class="font-headline-sm text-headline-sm mb-xs">Buy From Us</h2>
        <p class="text-on-surface-variant font-body-md flex-grow mb-md">
          Shop recycled glass cullet, high-density briquettes and sterilized bottles — delivered across the region.
        </p>
        <span class="text-primary font-label-sm text-label-sm flex items-center gap-xs">
          Browse products <MaterialIcon name="arrow_forward" class="transition-transform group-hover:translate-x-1" />
        </span>
      </RouterLink>

      <!-- Sell To Us -->
      <RouterLink
        to="/sell"
        class="group bg-surface-container-lowest rounded-xl p-lg shadow-low shadow-hover transition-all flex flex-col"
      >
        <div class="w-16 h-16 rounded-full bg-tertiary text-on-tertiary flex items-center justify-center mb-md">
          <MaterialIcon name="sell" />
        </div>
        <h2 class="font-headline-sm text-headline-sm mb-xs">Sell To Us</h2>
        <p class="text-on-surface-variant font-body-md flex-grow mb-md">
          Earn from your used bottles. See our buying prices for the bottle types we collect — organic waste coming soon.
        </p>
        <span class="text-primary font-label-sm text-label-sm flex items-center gap-xs">
          See buying prices <MaterialIcon name="arrow_forward" class="transition-transform group-hover:translate-x-1" />
        </span>
      </RouterLink>
    </div>
  </section>
</template>
