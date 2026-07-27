<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import iconUrl from 'leaflet/dist/images/marker-icon.png'
import iconRetinaUrl from 'leaflet/dist/images/marker-icon-2x.png'
import shadowUrl from 'leaflet/dist/images/marker-shadow.png'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

// Fix Leaflet's default marker icon paths under Vite bundling.
// _getIconUrl must be removed or it overrides mergeOptions and the pin 404s.
delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({ iconUrl, iconRetinaUrl, shadowUrl })

const props = defineProps({ modelValue: { type: Object, default: () => ({}) } })
const emit = defineEmits(['update:modelValue'])

// Whole of Kenya (centroid) at a country-level zoom.
const DEFAULT = { lat: 0.0236, lng: 37.9062, zoom: 6 }

const mapEl = ref(null)
const address = ref(props.modelValue?.address || '')
const lat = ref(props.modelValue?.lat ?? null)
const lng = ref(props.modelValue?.lng ?? null)
const locating = ref(false)
const geoError = ref('')

const searchQuery = ref('')
const searchResults = ref([])
const searching = ref(false)
const searchError = ref('')

let map = null
let marker = null

function emitValue() {
  emit('update:modelValue', { lat: lat.value, lng: lng.value, address: address.value })
}

function placeMarker(latlng) {
  if (!marker) {
    marker = L.marker(latlng, { draggable: true }).addTo(map)
    marker.on('dragend', () => setFrom(marker.getLatLng()))
  } else {
    marker.setLatLng(latlng)
  }
}

function applyLocation(la, ln, addr, zoom) {
  lat.value = +Number(la).toFixed(6)
  lng.value = +Number(ln).toFixed(6)
  placeMarker([lat.value, lng.value])
  if (zoom) map.setView([lat.value, lng.value], zoom)
  else map.panTo([lat.value, lng.value])
  if (addr != null) address.value = addr
  emitValue()
}

async function setFrom(latlng) {
  applyLocation(latlng.lat, latlng.lng)
  await reverseGeocode(lat.value, lng.value)
}

async function reverseGeocode(la, ln) {
  try {
    const r = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${la}&lon=${ln}&zoom=16&addressdetails=1`,
      { headers: { Accept: 'application/json' } },
    )
    const j = await r.json()
    if (j?.display_name) {
      address.value = j.display_name
      emitValue()
    }
  } catch (e) {
    /* keep whatever address the user typed */
  }
}

async function doSearch() {
  const q = searchQuery.value.trim()
  searchError.value = ''
  searchResults.value = []
  if (!q) return
  searching.value = true
  try {
    // countrycodes=ke restricts the search to Kenya.
    const r = await fetch(
      `https://nominatim.openstreetmap.org/search?format=json&countrycodes=ke&limit=6&addressdetails=1&q=${encodeURIComponent(q)}`,
      { headers: { Accept: 'application/json' } },
    )
    const j = await r.json()
    if (Array.isArray(j) && j.length) searchResults.value = j
    else searchError.value = 'No matches in Kenya. Try another search, or tap the map to drop a pin.'
  } catch (e) {
    searchError.value = 'Search failed. Tap the map to drop your pin instead.'
  } finally {
    searching.value = false
  }
}

function chooseResult(r) {
  // Centre the map on the search hit and drop the pin there; the user can still
  // click/drag to fine-tune the exact spot.
  applyLocation(r.lat, r.lon, r.display_name, 16)
  searchResults.value = []
  searchQuery.value = r.display_name
}

function useMyLocation() {
  geoError.value = ''
  if (!navigator.geolocation) {
    geoError.value = 'Geolocation is not supported by this browser. Tap the map to drop a pin.'
    return
  }
  locating.value = true
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      locating.value = false
      applyLocation(pos.coords.latitude, pos.coords.longitude, null, 16)
      reverseGeocode(lat.value, lng.value)
    },
    (err) => {
      locating.value = false
      geoError.value =
        err.code === 1
          ? 'Location access is blocked. Turn on location permission for this site in your browser, then tap “Use my current location” again — or search / tap the map to drop your pin.'
          : 'Could not get your location. Search for it or tap the map to drop your pin manually.'
    },
    { enableHighAccuracy: true, timeout: 10000 },
  )
}

onMounted(() => {
  const hasVal = lat.value != null && lng.value != null
  const start = hasVal ? { lat: lat.value, lng: lng.value, zoom: 16 } : DEFAULT
  map = L.map(mapEl.value).setView([start.lat, start.lng], start.zoom)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap contributors',
  }).addTo(map)
  if (hasVal) placeMarker([lat.value, lng.value])
  map.on('click', (e) => setFrom(e.latlng))
  // Leaflet needs a size recalculation once the container has laid out.
  setTimeout(() => map && map.invalidateSize(), 200)
})

onBeforeUnmount(() => {
  if (map) {
    map.remove()
    map = null
  }
})
</script>

<template>
  <div class="flex flex-col gap-sm">
    <!-- Search a place anywhere in Kenya -->
    <div class="flex gap-sm">
      <input
        v-model="searchQuery"
        placeholder="Search a town, estate or landmark in Kenya…"
        class="flex-1 rounded-lg border-outline-variant focus:border-primary focus:ring-primary"
        @keyup.enter.prevent="doSearch"
      />
      <button
        type="button"
        class="bg-primary text-on-primary px-4 rounded-lg flex items-center justify-center disabled:opacity-50"
        :disabled="searching"
        @click="doSearch"
      >
        <MaterialIcon :name="searching ? 'hourglass_empty' : 'search'" />
      </button>
    </div>
    <ul
      v-if="searchResults.length"
      class="bg-surface-container-lowest border border-outline-variant rounded-lg max-h-56 overflow-auto divide-y divide-outline-variant/40"
    >
      <li v-for="(r, i) in searchResults" :key="i">
        <button
          type="button"
          class="w-full text-left px-3 py-2 hover:bg-surface-container font-body-md text-[13px]"
          @click="chooseResult(r)"
        >
          {{ r.display_name }}
        </button>
      </li>
    </ul>
    <p v-if="searchError" class="text-error font-body-md text-[12px]">{{ searchError }}</p>

    <div class="flex flex-wrap items-center gap-sm">
      <button
        type="button"
        class="flex items-center gap-xs bg-primary text-on-primary font-label-sm text-label-sm px-4 py-2 rounded-full disabled:opacity-50"
        :disabled="locating"
        @click="useMyLocation"
      >
        <MaterialIcon name="my_location" />
        {{ locating ? 'Locating…' : 'Use my current location' }}
      </button>
      <span class="text-on-surface-variant font-body-md text-[13px]">or tap the map to drop a pin</span>
    </div>

    <div ref="mapEl" class="h-64 w-full rounded-lg overflow-hidden border border-outline-variant z-0"></div>

    <p v-if="geoError" class="text-error font-body-md text-[13px]">{{ geoError }}</p>

    <label class="flex flex-col gap-xs">
      <span class="font-label-sm text-label-sm text-on-surface-variant">Delivery address / landmark</span>
      <input
        v-model="address"
        placeholder="Auto-filled from the pin — you can refine it"
        class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary"
        @input="emitValue"
      />
    </label>
    <p v-if="lat != null" class="text-on-surface-variant font-body-md text-[12px]">
      Pinned at {{ lat }}, {{ lng }}
    </p>
  </div>
</template>
