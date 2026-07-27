<script setup>
import { RouterLink } from 'vue-router'
</script>

<template>
  <section class="max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl text-center">
    <div class="font-display-lg text-display-lg text-primary">404</div>
    <h1 class="font-headline-sm text-headline-sm mt-md mb-xs">Page not found</h1>
    <p class="text-on-surface-variant mb-lg">The page you're looking for doesn't exist.</p>
    <RouterLink to="/" class="inline-block bg-primary text-on-primary font-label-sm text-label-sm px-lg py-3 rounded-full">
      Back to Home
    </RouterLink>
  </section>
</template>
