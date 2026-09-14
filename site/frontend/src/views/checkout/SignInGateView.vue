<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { forgotPassword } from '@/api/auth'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

const mode = ref('login') // login | register | forgot
const loginForm = reactive({ email: '', password: '' })
const registerForm = reactive({ fullName: '', email: '', phone: '', password: '', confirmPassword: '' })
const forgotForm = reactive({ email: '' })
const busy = ref(false)
const error = ref('')
const info = ref('')

// Password visibility toggles
const showLoginPw = ref(false)
const showRegPw = ref(false)
const showRegConfirm = ref(false)

const next = () => route.query.redirect || '/checkout/delivery'

function switchMode(m) {
  mode.value = m
  error.value = ''
  info.value = ''
}

onMounted(() => {
  if (auth.isAuthenticated) router.replace(next())
})

async function doLogin() {
  busy.value = true
  error.value = ''
  try {
    await auth.login({ email: loginForm.email, password: loginForm.password })
    // Eco Message splash covers the redirect and the lazy-loaded next view.
    window.__ecoLoaderShow?.()
    await router.replace(next())
  } catch (e) {
    error.value = e?.response?.data?.message || 'Login failed. Check your details.'
  } finally {
    busy.value = false
    window.__ecoLoaderDone?.() // no-op if the splash was never shown
  }
}

async function doRegister() {
  error.value = ''
  if (registerForm.password.length < 6) {
    error.value = 'Password must be at least 6 characters.'
    return
  }
  if (registerForm.password !== registerForm.confirmPassword) {
    error.value = 'Passwords do not match.'
    return
  }
  busy.value = true
  try {
    await auth.register({
      fullName: registerForm.fullName,
      email: registerForm.email,
      phone: registerForm.phone,
      password: registerForm.password,
    })
    // A successful registration signs the user in, so show the splash here too.
    window.__ecoLoaderShow?.()
    await router.replace(next())
  } catch (e) {
    error.value = e?.response?.data?.message || 'Registration failed.'
  } finally {
    busy.value = false
    window.__ecoLoaderDone?.() // no-op if the splash was never shown
  }
}

async function doForgot() {
  error.value = ''
  info.value = ''
  busy.value = true
  try {
    const res = await forgotPassword(forgotForm.email)
    info.value = res?.message || 'If an account exists for that email, a reset link has been sent.'
  } catch (e) {
    error.value = e?.response?.data?.message || 'Please enter a valid email address.'
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <section class="max-w-md mx-auto px-margin-mobile py-xl">
    <div class="bg-surface-container-lowest rounded-xl p-lg shadow-low">
      <h1 class="font-headline-sm text-headline-sm mb-md text-center">
        {{ mode === 'forgot' ? 'Reset your password' : 'Sign in to continue' }}
      </h1>

      <div v-if="mode !== 'forgot'" class="flex bg-surface-container rounded-full p-1 mb-lg">
        <button class="flex-1 py-2 rounded-full font-label-sm text-label-sm transition-colors" :class="mode === 'login' ? 'bg-primary text-on-primary' : 'text-on-surface-variant'" @click="switchMode('login')">Sign In</button>
        <button class="flex-1 py-2 rounded-full font-label-sm text-label-sm transition-colors" :class="mode === 'register' ? 'bg-primary text-on-primary' : 'text-on-surface-variant'" @click="switchMode('register')">Register</button>
      </div>

      <!-- LOGIN -->
      <form v-if="mode === 'login'" class="flex flex-col gap-md" @submit.prevent="doLogin">
        <input v-model="loginForm.email" type="email" required placeholder="Email" class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary" />
        <div class="relative">
          <input v-model="loginForm.password" :type="showLoginPw ? 'text' : 'password'" required placeholder="Password" class="w-full rounded-lg border-outline-variant focus:border-primary focus:ring-primary pr-11" />
          <button type="button" :aria-label="showLoginPw ? 'Hide password' : 'Show password'" class="absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary" @click="showLoginPw = !showLoginPw">
            <MaterialIcon :name="showLoginPw ? 'visibility_off' : 'visibility'" />
          </button>
        </div>
        <div class="flex justify-end -mt-xs">
          <button type="button" class="text-primary font-label-sm text-[13px] hover:underline" @click="switchMode('forgot')">Forgot password?</button>
        </div>
        <p v-if="error" class="text-error font-body-md">{{ error }}</p>
        <button type="submit" :disabled="busy" class="bg-primary text-on-primary font-label-sm text-label-sm py-3 rounded-full disabled:opacity-50">{{ busy ? 'Signing in…' : 'Sign In' }}</button>
      </form>

      <!-- REGISTER -->
      <form v-else-if="mode === 'register'" class="flex flex-col gap-md" @submit.prevent="doRegister">
        <input v-model="registerForm.fullName" required placeholder="Full name" class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary" />
        <input v-model="registerForm.email" type="email" required placeholder="Email" class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary" />
        <input v-model="registerForm.phone" placeholder="Phone (optional)" class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary" />
        <div class="relative">
          <input v-model="registerForm.password" :type="showRegPw ? 'text' : 'password'" required placeholder="Password (min 6 chars)" class="w-full rounded-lg border-outline-variant focus:border-primary focus:ring-primary pr-11" />
          <button type="button" :aria-label="showRegPw ? 'Hide password' : 'Show password'" class="absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary" @click="showRegPw = !showRegPw">
            <MaterialIcon :name="showRegPw ? 'visibility_off' : 'visibility'" />
          </button>
        </div>
        <div class="relative">
          <input v-model="registerForm.confirmPassword" :type="showRegConfirm ? 'text' : 'password'" required placeholder="Confirm password" class="w-full rounded-lg border-outline-variant focus:border-primary focus:ring-primary pr-11" />
          <button type="button" :aria-label="showRegConfirm ? 'Hide password' : 'Show password'" class="absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary" @click="showRegConfirm = !showRegConfirm">
            <MaterialIcon :name="showRegConfirm ? 'visibility_off' : 'visibility'" />
          </button>
        </div>
        <p v-if="error" class="text-error font-body-md">{{ error }}</p>
        <button type="submit" :disabled="busy" class="bg-primary text-on-primary font-label-sm text-label-sm py-3 rounded-full disabled:opacity-50">{{ busy ? 'Creating…' : 'Create Account' }}</button>
      </form>

      <!-- FORGOT PASSWORD -->
      <form v-else class="flex flex-col gap-md" @submit.prevent="doForgot">
        <p class="text-on-surface-variant font-body-md text-[14px]">Enter your account email and we'll send you a link to reset your password.</p>
        <input v-model="forgotForm.email" type="email" required placeholder="Email" class="rounded-lg border-outline-variant focus:border-primary focus:ring-primary" />
        <p v-if="info" class="text-primary font-body-md bg-primary/5 border border-primary/20 rounded-lg p-md">{{ info }}</p>
        <p v-if="error" class="text-error font-body-md">{{ error }}</p>
        <button type="submit" :disabled="busy" class="bg-primary text-on-primary font-label-sm text-label-sm py-3 rounded-full disabled:opacity-50">{{ busy ? 'Sending…' : 'Send reset link' }}</button>
        <button type="button" class="text-primary font-label-sm text-label-sm hover:underline" @click="switchMode('login')">Back to sign in</button>
      </form>

      <template v-if="mode !== 'forgot'">
        <div class="flex items-center gap-md my-lg">
          <div class="flex-1 h-px bg-outline-variant"></div>
          <span class="text-on-surface-variant font-label-sm text-[12px]">OR</span>
          <div class="flex-1 h-px bg-outline-variant"></div>
        </div>

        <RouterLink to="/checkout/delivery" class="flex items-center justify-center gap-xs border-2 border-primary text-primary font-label-sm text-label-sm py-3 rounded-full hover:bg-primary hover:text-on-primary transition-all">
          <MaterialIcon name="person_off" /> Continue as Guest
        </RouterLink>
      </template>
    </div>
  </section>
</template>
