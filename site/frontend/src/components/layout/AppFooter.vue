<script setup>
import { RouterLink } from 'vue-router'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'
</script>

<template>
  <footer class="bg-surface-container-low">
    <div class="w-full px-margin-mobile md:px-margin-desktop pt-lg pb-28 md:pb-lg max-w-content mx-auto flex flex-col gap-md">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-xl">
        <div class="md:col-span-2">
          <div class="flex items-center gap-xs mb-md">
            <img src="/logo.png" alt="360 Econovations logo" class="h-10 w-10 object-contain" />
            <span class="font-headline-sm text-headline-sm font-bold text-primary">360 ECONOVATIONS</span>
          </div>
          <p class="text-on-surface-variant font-body-md max-w-md">
            Kenya's leading waste-to-value enterprise focused on glass and biomass recovery.
            Partnering for a cleaner, greener tomorrow — based in Embu County.
          </p>
        </div>
        <div>
          <h5 class="font-label-sm text-label-sm font-bold text-on-surface mb-md">Quick Links</h5>
          <ul class="flex flex-col gap-xs">
            <li><RouterLink class="text-on-surface-variant font-label-sm hover:text-secondary" to="/">Home</RouterLink></li>
            <li><RouterLink class="text-on-surface-variant font-label-sm hover:text-secondary" to="/services">Services</RouterLink></li>
            <li><RouterLink class="text-on-surface-variant font-label-sm hover:text-secondary" to="/about">About</RouterLink></li>
            <li><RouterLink class="text-on-surface-variant font-label-sm hover:text-secondary" to="/impact">Impact</RouterLink></li>
            <li><RouterLink class="text-secondary font-label-sm font-bold hover:text-primary flex items-center gap-1" to="/eco-dino">Play Eco-Dino 🦖</RouterLink></li>
          </ul>
        </div>
        <div>
          <h5 class="font-label-sm text-label-sm font-bold text-on-surface mb-md">Connect</h5>
          <ul class="flex flex-col gap-xs">
            <li>
              <a class="text-on-surface-variant font-label-sm hover:text-secondary flex items-center gap-xs" href="mailto:hello@360econovations.com">
                <MaterialIcon name="mail" /> Email
              </a>
            </li>
            <li>
              <RouterLink class="text-on-surface-variant font-label-sm hover:text-secondary flex items-center gap-xs" to="/contact">
                <MaterialIcon name="location_on" /> Embu Location
              </RouterLink>
            </li>
          </ul>
        </div>
      </div>
      <div class="border-t border-outline-variant pt-md">
        <p class="text-on-surface-variant font-body-md text-[13px] leading-relaxed text-center md:text-left">
          © 2026 360 Econovations Enterprise.
        </p>
      </div>
    </div>
  </footer>
</template>
