<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchImpact, fetchContent } from '@/api/content'

const impact = ref(null)
// Hero video URL comes from the DB (page_content home/hero) via the content API;
// falls back to the bundled asset if the backend is unreachable.
const heroVideo = ref('/glass-hero.mp4')

onMounted(async () => {
  try {
    impact.value = await fetchImpact()
  } catch (e) {
    impact.value = null
  }
  try {
    const hero = await fetchContent('home', 'hero')
    if (hero?.videoUrl) heroVideo.value = hero.videoUrl
  } catch (e) {
    // keep the bundled fallback
  }
})
</script>

<template>
  <!-- Hero -->
  <section class="relative flex items-center overflow-hidden bg-gradient-to-br from-primary to-primary-container min-h-[560px] md:min-h-[680px]">
    <!-- Background video (decorative); gradient above shows while it loads / if it fails -->
    <video
      class="absolute inset-0 h-full w-full object-cover"
      :src="heroVideo"
      autoplay
      muted
      loop
      playsinline
      preload="auto"
      aria-hidden="true"
    ></video>
    <!-- Overlay: darker on the left (behind the text) fading right so the video stays visible -->
    <div class="absolute inset-0 bg-gradient-to-r from-primary/90 via-primary/55 to-primary/20"></div>

    <div class="relative z-10 w-full max-w-content mx-auto px-margin-mobile md:px-margin-desktop py-xl">
      <div class="max-w-2xl">
        <h1 class="font-display-lg text-display-lg-mobile md:text-display-lg text-surface mb-md">
          Turning Waste <br /><span class="text-secondary-fixed">Into Value.</span>
        </h1>
        <p class="font-body-lg text-body-lg text-surface/90 mb-lg">
          We partner with local clubs and manage waste across Kenya to transform discarded glass and
          biomass into premium cullet and eco-friendly briquettes.
        </p>
        <div class="flex flex-col sm:flex-row gap-md">
          <RouterLink to="/services" class="bg-accent text-white text-center font-label-sm text-label-sm px-lg py-4 rounded-full shadow-low hover:bg-accent-dark hover:scale-105 transition-all">
            Explore Services
          </RouterLink>
          <RouterLink to="/about" class="border-2 border-surface/60 text-surface text-center font-label-sm text-label-sm px-lg py-4 rounded-full hover:bg-surface/10 transition-all">
            Learn More
          </RouterLink>
        </div>
      </div>
    </div>
  </section>

  <!-- Impact stats bar -->
  <section class="bg-primary text-on-primary-container py-lg px-margin-mobile md:px-margin-desktop">
    <div class="max-w-content mx-auto grid grid-cols-2 md:grid-cols-4 gap-lg text-center">
      <div>
        <div class="font-display-lg-mobile text-display-lg-mobile font-bold mb-xs">{{ impact ? impact.glassTonnesDiverted : '—' }}</div>
        <div class="font-label-sm text-label-sm opacity-80 uppercase tracking-wider">Tonnes Glass Diverted</div>
      </div>
      <div>
        <div class="font-display-lg-mobile text-display-lg-mobile font-bold mb-xs">{{ impact ? impact.householdsReached : '—' }}</div>
        <div class="font-label-sm text-label-sm opacity-80 uppercase tracking-wider">Households Reached</div>
      </div>
      <div>
        <div class="font-display-lg-mobile text-display-lg-mobile font-bold mb-xs">{{ impact ? impact.jobsCreated : '—' }}</div>
        <div class="font-label-sm text-label-sm opacity-80 uppercase tracking-wider">Jobs Created</div>
      </div>
      <div>
        <div class="font-display-lg-mobile text-display-lg-mobile font-bold mb-xs">{{ impact ? impact.partnerClubs : '—' }}+</div>
        <div class="font-label-sm text-label-sm opacity-80 uppercase tracking-wider">Partner Clubs</div>
      </div>
    </div>
  </section>
</template>
