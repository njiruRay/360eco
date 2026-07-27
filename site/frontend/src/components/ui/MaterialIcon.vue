<script setup>
defineProps({
  name: { type: String, required: true },
  filled: { type: Boolean, default: false },
})
</script>

<template>
  <span
    class="material-symbols-outlined"
    :style="filled ? { fontVariationSettings: `'FILL' 1` } : null"
    aria-hidden="true"
  >
    {{ name }}
  </span>
</template>
