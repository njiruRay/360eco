<script setup>
/**
 * Eco-Dino Runner — ported from the UI-UX prototype's cart.js canvas game.
 *
 * Differences from the prototype, all deliberate:
 *  - Physics run on delta-time, so the game plays identically at 60Hz and
 *    144Hz. The prototype advanced per frame, which made it literally twice
 *    as fast on a 120Hz screen.
 *  - Score counts obstacles cleared rather than frames survived.
 *  - The canvas backing store is sized to devicePixelRatio and the element's
 *    real width, so it stays sharp on phones instead of being CSS-stretched.
 *  - Speed is capped and obstacles keep a jumpable minimum gap, so runs end
 *    on a mistake rather than on an unavoidable wall.
 *  - Collision boxes are inset a few pixels, so grazing a bottle cap no
 *    longer counts as a hit.
 *
 * Everything the loop touches each frame is a plain variable, not a ref —
 * driving Vue's reactivity at 60fps would be pure overhead, and the running
 * score is painted onto the canvas rather than into the DOM.
 */
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const emit = defineEmits(['close'])

// ---- World (logical drawing units; the canvas scales to fit) ----
const WORLD_W = 600
const WORLD_H = 150
const ASPECT = WORLD_W / WORLD_H
const GROUND_Y = 130
const PLAYER_FLOOR = 110

// ---- Physics, in units per second ----
// Converted from the prototype's per-frame values at its assumed 60fps:
// gravity 0.6/frame² -> 0.6*60*60, jump -9/frame -> -9*60, speed 4/frame -> 4*60.
const GRAVITY = 2160
const JUMP_VELOCITY = -540
const START_SPEED = 240
const SPEED_STEP = 30
const SPEEDUP_EVERY_S = 5
// Cap speed so the ramp cannot outrun what a jump can clear.
const MAX_SPEED = 540

// ---- Spawning ----
const SPAWN_MIN_S = 0.9
const SPAWN_MAX_S = 1.8
// A jump lasts 2*|JUMP_VELOCITY|/GRAVITY = 0.5s. Requiring 0.75s of travel
// between obstacles leaves margin to land and take off again at any speed.
const MIN_GAP_S = 0.75
const CLOUD_MIN_S = 2.5
const CLOUD_MAX_S = 4

// ---- Collision forgiveness (visuals unchanged, hitboxes shrunk) ----
const PLAYER_INSET = 3
const OBSTACLE_INSET = 2

// A long frame (tab backgrounded, GC pause) must not teleport the player
// through an obstacle — clamp rather than tunnel.
const MAX_DT = 0.05

// Scores are obstacles cleared now, not frames survived, so the old key's
// values (hundreds) would be unbeatable on the new scale. New key, fresh start.
const HIGH_SCORE_KEY = 'eco_dino_highscore_v2'
const FACT_ROTATE_MS = 5000

const FACTS = [
  'Recycling 1 ton of glass saves 1.2 tons of sand & limestone.',
  'Biomass briquettes burn longer and generate 90% less smoke than charcoal.',
  'Returnable glass bottles are returned up to 25 times under the Rudisha program.',
  'Recycling glass reduces manufacturing energy consumption by 30%.',
  'Every returnable glass bottle returned prevents forest clearing for firewood.',
  'Clean color sorting increases cullet value for glass manufacturers by 50%.',
  'Sourcing glass via local micro-warehouses saves up to 40% in logistics costs.',
]

// ---- Reactive state (DOM-facing only) ----
const canvasEl = ref(null)
const playBtn = ref(null)
const isRunning = ref(false)
const isOver = ref(false)
const finalScore = ref(0)
const highScore = ref(0)
const fact = ref(FACTS[0])

// ---- Per-frame state (deliberately not reactive) ----
let ctx = null
let rafId = null
let factTimer = null
let resizeObserver = null
let lastTs = 0
let cleared = 0
let speed = START_SPEED
let speedTimer = 0
let spawnTimer = 0
let cloudTimer = 0
let legTimer = 0
let legUp = false
let player = null
let obstacles = []
let clouds = []

const rand = (min, max) => min + Math.random() * (max - min)

function resetState() {
  player = { x: 50, y: PLAYER_FLOOR, w: 20, h: 20, vy: 0, isJumping: false }
  obstacles = []
  clouds = []
  cleared = 0
  speed = START_SPEED
  speedTimer = 0
  spawnTimer = rand(SPAWN_MIN_S, SPAWN_MAX_S)
  cloudTimer = 0
  legTimer = 0
  legUp = false
  lastTs = 0
}

// ---- Canvas sizing: sharp on any display, undistorted at any width ----
function setupCanvas() {
  const el = canvasEl.value
  if (!el) return
  const cssW = el.clientWidth || WORLD_W
  const cssH = cssW / ASPECT
  const dpr = window.devicePixelRatio || 1

  el.width = Math.max(1, Math.round(cssW * dpr))
  el.height = Math.max(1, Math.round(cssH * dpr))

  ctx = el.getContext('2d')
  // Draw in world units; this maps them onto the real pixel grid.
  const scale = (cssW / WORLD_W) * dpr
  ctx.setTransform(scale, 0, 0, scale, 0, 0)
}

// ---- Drawing ----
function drawPlayer() {
  ctx.fillStyle = '#15803D' // brand primary green
  ctx.fillRect(player.x, player.y, player.w, player.h)

  ctx.fillStyle = '#FFFFFF' // recycle stripe
  ctx.fillRect(player.x + 4, player.y + 4, player.w - 8, 3)

  const legLen = legUp ? 5 : 2
  ctx.fillStyle = '#15803D'
  ctx.fillRect(player.x + 3, player.y + player.h, 4, legLen)
  ctx.fillRect(player.x + 13, player.y + player.h, 4, 7 - legLen)
}

function drawObstacle(obs) {
  if (obs.type === 0) {
    ctx.fillStyle = '#7f7f7f' // plastic grey
    ctx.fillRect(obs.x, obs.y, obs.w, obs.h)
    ctx.fillStyle = '#0000ff' // bottle cap
    ctx.fillRect(obs.x + 2, obs.y - 3, obs.w - 4, 3)
  } else {
    ctx.fillStyle = '#3f493f' // soot charcoal
    ctx.fillRect(obs.x, obs.y, obs.w, obs.h)
    ctx.fillRect(obs.x + 3, obs.y - 3, obs.w - 6, 3)
    ctx.fillRect(obs.x - 3, obs.y + 3, obs.w + 6, obs.h - 6)
  }
}

function drawClouds() {
  for (const cloud of clouds) {
    ctx.fillStyle = '#e4eae1'
    ctx.fillRect(cloud.x, cloud.y, cloud.w, cloud.h)
    ctx.fillRect(cloud.x + 5, cloud.y - 4, cloud.w - 10, 4)
  }
}

function drawGround() {
  ctx.strokeStyle = '#6f7a6e'
  ctx.lineWidth = 2
  ctx.beginPath()
  ctx.moveTo(0, GROUND_Y)
  ctx.lineTo(WORLD_W, GROUND_Y)
  ctx.stroke()
}

/** Static frame shown behind the start overlay, before the first run. */
function drawIdleFrame() {
  if (!ctx) return
  ctx.clearRect(0, 0, WORLD_W, WORLD_H)
  drawGround()
  drawPlayer()
}

// ---- Simulation ----
function spawnObstacle() {
  const type = Math.random() > 0.5 ? 0 : 1
  const h = type === 0 ? 24 : 18
  obstacles.push({
    x: WORLD_W + 10,
    y: GROUND_Y - h,
    w: type === 0 ? 10 : 20,
    h,
    type,
    scored: false,
  })
}

/** True only if the last obstacle is far enough ahead to leave a jumpable gap. */
function gapIsClear() {
  if (!obstacles.length) return true
  const last = obstacles[obstacles.length - 1]
  return WORLD_W + 10 - last.x >= speed * MIN_GAP_S
}

function hitsPlayer(obs) {
  const px = player.x + PLAYER_INSET
  const pw = player.w - PLAYER_INSET * 2
  const py = player.y + PLAYER_INSET
  const ph = player.h - PLAYER_INSET * 2
  const ox = obs.x + OBSTACLE_INSET
  const ow = obs.w - OBSTACLE_INSET * 2
  const oy = obs.y + OBSTACLE_INSET
  const oh = obs.h - OBSTACLE_INSET * 2
  return px < ox + ow && px + pw > ox && py < oy + oh && py + ph > oy
}

/** Advances the world by dt seconds. Returns true if the player crashed. */
function update(dt) {
  // Player
  player.vy += GRAVITY * dt
  player.y += player.vy * dt
  if (player.y >= PLAYER_FLOOR) {
    player.y = PLAYER_FLOOR
    player.vy = 0
    player.isJumping = false
  }

  legTimer += dt
  if (legTimer >= 0.1) {
    legTimer = 0
    legUp = !legUp
  }

  // Difficulty ramp, capped
  speedTimer += dt
  if (speedTimer >= SPEEDUP_EVERY_S) {
    speedTimer -= SPEEDUP_EVERY_S
    speed = Math.min(MAX_SPEED, speed + SPEED_STEP)
  }

  // Obstacles
  let crashed = false
  for (const obs of obstacles) {
    obs.x -= speed * dt
    if (!obs.scored && obs.x + obs.w < player.x) {
      obs.scored = true
      cleared++
    }
    // Check every obstacle but report once, so one crash cannot run the
    // game-over path several times in a single frame.
    if (hitsPlayer(obs)) crashed = true
  }
  obstacles = obstacles.filter((obs) => obs.x > -50)

  spawnTimer -= dt
  if (spawnTimer <= 0) {
    if (gapIsClear()) {
      spawnObstacle()
      spawnTimer = rand(SPAWN_MIN_S, SPAWN_MAX_S)
    } else {
      spawnTimer = 0.1 // too close — look again shortly
    }
  }

  // Clouds
  cloudTimer -= dt
  if (cloudTimer <= 0) {
    clouds.push({ x: WORLD_W + 10, y: rand(15, 55), w: 30, h: 10, speed: rand(30, 60) })
    cloudTimer = rand(CLOUD_MIN_S, CLOUD_MAX_S)
  }
  for (const cloud of clouds) cloud.x -= cloud.speed * dt
  clouds = clouds.filter((c) => c.x > -50)

  return crashed
}

function render() {
  ctx.clearRect(0, 0, WORLD_W, WORLD_H)
  drawGround()
  drawClouds()
  for (const obs of obstacles) drawObstacle(obs)
  drawPlayer()

  ctx.fillStyle = '#181d17'
  ctx.font = 'bold 12px monospace'
  ctx.fillText(`SCORE: ${cleared}`, 10, 20)
}

// ---- Game flow ----
function jump() {
  if (!isRunning.value) {
    startGame()
    return
  }
  if (!player.isJumping) {
    player.vy = JUMP_VELOCITY
    player.isJumping = true
  }
}

function startGame() {
  if (isRunning.value) return // Space and the Play button can both fire
  resetState()
  isOver.value = false
  isRunning.value = true
  rafId = requestAnimationFrame(loop)
}

function gameOver() {
  isRunning.value = false
  isOver.value = true
  finalScore.value = cleared

  if (cleared > highScore.value) {
    highScore.value = cleared
    try {
      localStorage.setItem(HIGH_SCORE_KEY, String(cleared))
    } catch {
      // Private browsing / blocked storage — the score just won't persist.
    }
  }
}

function loop(ts) {
  if (!isRunning.value) return

  // First frame establishes the clock; dt of 0 advances nothing.
  const dt = lastTs ? Math.min((ts - lastTs) / 1000, MAX_DT) : 0
  lastTs = ts

  const crashed = update(dt)
  render()

  if (crashed) {
    gameOver()
    return
  }
  rafId = requestAnimationFrame(loop)
}

// ---- Input ----
function onKeydown(e) {
  if (e.code === 'Space' || e.code === 'ArrowUp') {
    e.preventDefault()
    jump()
  } else if (e.code === 'Escape') {
    emit('close')
  }
}

// ---- Lifecycle: this is what keeps the port leak-free ----
onMounted(async () => {
  try {
    highScore.value = parseInt(localStorage.getItem(HIGH_SCORE_KEY) || '0', 10) || 0
  } catch {
    highScore.value = 0
  }

  resetState()
  setupCanvas()
  drawIdleFrame()

  // Keep the backing store correct across rotation and window resizes.
  resizeObserver = new ResizeObserver(() => {
    setupCanvas()
    if (!isRunning.value) drawIdleFrame()
  })
  resizeObserver.observe(canvasEl.value)

  window.addEventListener('keydown', onKeydown)
  factTimer = setInterval(() => {
    fact.value = FACTS[Math.floor(Math.random() * FACTS.length)]
  }, FACT_ROTATE_MS)

  await nextTick()
  playBtn.value?.focus()
})

onUnmounted(() => {
  if (rafId !== null) cancelAnimationFrame(rafId)
  if (factTimer !== null) clearInterval(factTimer)
  resizeObserver?.disconnect()
  window.removeEventListener('keydown', onKeydown)
  rafId = null
  factTimer = null
  resizeObserver = null
  isRunning.value = false
})
</script>

<template>
  <div
    class="fixed inset-0 z-[100] bg-black/80 backdrop-blur-md flex items-center justify-center p-4 select-none"
    role="dialog"
    aria-modal="true"
    aria-label="Eco-Dino Runner"
  >
    <div
      class="bg-background border-2 border-primary-container w-full max-w-2xl rounded-2xl p-6 flex flex-col gap-4 text-on-surface shadow-2xl"
    >
      <!-- Header -->
      <div class="flex justify-between items-center border-b border-outline-variant/30 pb-3">
        <div>
          <h2 class="font-headline-sm text-headline-sm font-bold text-primary flex items-center gap-2">
            <span aria-hidden="true">🦖</span> Eco-Dino Runner
          </h2>
          <p class="text-xs text-on-surface-variant/80 mt-1">Play &amp; learn circular economics!</p>
        </div>
        <button
          type="button"
          class="text-on-surface-variant hover:text-primary transition-colors"
          aria-label="Close game"
          @click="emit('close')"
        >
          <MaterialIcon name="close" class="text-3xl" />
        </button>
      </div>

      <!-- Eco-facts ticker -->
      <div
        class="bg-surface-container-low border border-outline-variant/20 p-3 rounded-lg text-center font-bold text-sm min-h-[50px] flex items-center justify-center text-primary"
        aria-live="polite"
      >
        "{{ fact }}"
      </div>

      <!-- Canvas -->
      <div
        class="relative bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden p-2 flex justify-center items-center"
      >
        <canvas
          ref="canvasEl"
          class="w-full max-w-[600px] aspect-[4/1] cursor-pointer"
          @click="jump"
          @touchstart.prevent="jump"
        ></canvas>

        <!-- Start / game-over overlay -->
        <div
          v-if="!isRunning"
          class="absolute inset-0 bg-black/60 flex flex-col items-center justify-center text-white text-center gap-3 px-4"
        >
          <h3 class="font-headline-sm text-headline-sm font-bold">
            {{ isOver ? 'GAME OVER' : 'PRESS SPACEBAR OR TAP TO PLAY' }}
          </h3>
          <p class="text-xs opacity-80">
            {{
              isOver
                ? `Obstacles cleared: ${finalScore} • Eco-Tip: check the ticker above!`
                : 'Avoid plastic bottles & pollution clouds!'
            }}
          </p>
          <button
            ref="playBtn"
            type="button"
            class="bg-accent hover:bg-accent-dark px-6 py-2 rounded-full text-white font-bold transition-all"
            @click="startGame"
          >
            {{ isOver ? 'Restart' : 'Play' }}
          </button>
        </div>
      </div>

      <div class="flex justify-between items-center text-xs opacity-75 font-semibold gap-2">
        <span>Jump: Spacebar / Arrow Up / Tap screen</span>
        <span>Best: {{ highScore }} cleared</span>
      </div>
    </div>
  </div>
</template>
