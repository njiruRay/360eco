<script setup>
import { reactive, ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { resetPassword } from '@/api/auth'
import { useAuthStore } from '@/stores/auth'
import MaterialIcon from '@/components/ui/MaterialIcon.vue'

const auth = useAuthStore()
// Opening the emailed link signs the user in with a short-lived recovery
// session (Supabase reads it from the URL); without one there's nothing to reset.
const canReset = ref(false)
const form = reactive({ password: '', confirmPassword: '' })
const showPw = ref(false)
const showConfirm = ref(false)
const busy = ref(false)
const error = ref('')
const done = ref(false)

onMounted(async () => {
  await auth.ready
  canReset.value = auth.isAuthenticated
  if (!canReset.value) error.value = 'This reset link is invalid or has expired. Please request a new one from the sign-in page.'
})

async function submit() {
  error.value = ''
  if (!canReset.value) return
  if (form.password.length < 6) {
    error.value = 'Password must be at least 6 characters.'
    return
  }
  if (form.password !== form.confirmPassword) {
    error.value = 'Passwords do not match.'
    return
  }
  busy.value = true
  try {
    await resetPassword(form.password)
    // End the recovery session so the "sign in with your new password" step is real.
    await auth.logout()
    done.value = true
  } catch (e) {
    error.value = e?.response?.data?.message || 'Could not reset your password. The link may have expired.'
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <section class="max-w-md mx-auto px-margin-mobile py-xl">
    <div class="bg-surface-container-lowest rounded-xl p-lg shadow-low">
      <h1 class="font-headline-sm text-headline-sm mb-md text-center">Set a new password</h1>

      <div v-if="done" class="text-center flex flex-col gap-md">
        <span class="w-16 h-16 rounded-full bg-primary/10 text-primary flex items-center justify-center mx-auto">
          <MaterialIcon name="check_circle" filled />
        </span>
        <p class="text-on-surface-variant font-body-md">Your password has been reset. You can now sign in with your new password.</p>
        <RouterLink to="/checkout/sign-in" class="bg-primary text-on-primary font-label-sm text-label-sm py-3 rounded-full">Go to sign in</RouterLink>
      </div>

      <form v-else class="flex flex-col gap-md" @submit.prevent="submit">
        <div class="relative">
          <input v-model="form.password" :type="showPw ? 'text' : 'password'" required placeholder="New password (min 6 chars)" class="w-full rounded-lg border-outline-variant focus:border-primary focus:ring-primary pr-11" />
          <button type="button" :aria-label="showPw ? 'Hide password' : 'Show password'" class="absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary" @click="showPw = !showPw">
            <MaterialIcon :name="showPw ? 'visibility_off' : 'visibility'" />
          </button>
        </div>
        <div class="relative">
          <input v-model="form.confirmPassword" :type="showConfirm ? 'text' : 'password'" required placeholder="Confirm new password" class="w-full rounded-lg border-outline-variant focus:border-primary focus:ring-primary pr-11" />
          <button type="button" :aria-label="showConfirm ? 'Hide password' : 'Show password'" class="absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary" @click="showConfirm = !showConfirm">
            <MaterialIcon :name="showConfirm ? 'visibility_off' : 'visibility'" />
          </button>
        </div>
        <p v-if="error" class="text-error font-body-md">{{ error }}</p>
        <button type="submit" :disabled="busy || !canReset" class="bg-primary text-on-primary font-label-sm text-label-sm py-3 rounded-full disabled:opacity-50">{{ busy ? 'Resetting…' : 'Reset password' }}</button>
        <RouterLink to="/checkout/sign-in" class="text-center text-primary font-label-sm text-label-sm hover:underline">Back to sign in</RouterLink>
      </form>
    </div>
  </section>
</template>
