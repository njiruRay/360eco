<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import EcoDinoGame from '@/components/game/EcoDinoGame.vue'

const route = useRoute()
const playing = ref(false)

onMounted(() => {
  // ?play=true opens the game straight away, mirroring the prototype's
  // ?play_game=true footer link.
  if (route.query.play === 'true') playing.value = true
})
</script>

<template>
  <section class="w-full px-margin-mobile md:px-margin-desktop py-xl max-w-content mx-auto">
    <div class="max-w-2xl mx-auto text-center flex flex-col gap-md items-center">
      <span
        class="inline-block px-3 py-1 bg-secondary-container text-on-secondary-container rounded-full text-[12px] font-bold uppercase tracking-wider"
      >
        Play &amp; learn
      </span>

      <h1 class="font-headline-md text-headline-md text-primary">🦖 Eco-Dino Runner</h1>

      <p class="font-body-lg text-body-lg text-on-surface-variant">
        Jump the plastic bottles and pollution clouds, and pick up a circular-economy fact
        between runs. Your high score is kept on this device.
      </p>

      <button
        type="button"
        class="bg-accent hover:bg-accent-dark text-white font-label-sm text-label-sm px-lg py-4 rounded-full shadow-low hover:scale-105 transition-all"
        @click="playing = true"
      >
        Play Eco-Dino
      </button>

      <p class="text-xs text-on-surface-variant/70">
        Controls: Spacebar / Arrow Up / tap the canvas. Press Esc to close.
      </p>
    </div>

    <EcoDinoGame v-if="playing" @close="playing = false" />
  </section>
</template>
