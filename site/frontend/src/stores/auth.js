import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/api/client'
import * as authApi from '@/api/auth'

export const useAuthStore = defineStore('auth', () => {
  // Supabase persists and refreshes the session itself; this store mirrors it.
  const session = ref(null)
  const user = ref(null) // { id, fullName, email, phone }

  const isAuthenticated = computed(() => !!session.value)

  // Leftovers from the old Spring Boot JWT login.
  localStorage.removeItem('auth_token')
  localStorage.removeItem('auth_user')

  function setSession(s) {
    const previousId = session.value?.user?.id
    session.value = s
    if (!s) {
      user.value = null
      return
    }
    if (s.user.id !== previousId) {
      // Show something immediately, then replace it with the stored profile.
      user.value = {
        id: s.user.id,
        fullName: s.user.user_metadata?.full_name || '',
        email: s.user.email,
        phone: s.user.user_metadata?.phone || null,
      }
      refreshMe()
    }
  }

  async function refreshMe() {
    if (!session.value) return
    try {
      user.value = await authApi.fetchMe()
    } catch {
      // Keep the fallback built from the session.
    }
  }

  // Resolves once the stored session (or one from an email link) is restored.
  // Route guards await this before deciding whether the user is signed in.
  const ready = supabase.auth.getSession().then(({ data }) => setSession(data.session))

  supabase.auth.onAuthStateChange((_event, s) => {
    // Defer: Supabase calls made inside this callback can deadlock its auth lock.
    setTimeout(() => setSession(s), 0)
  })

  async function login(payload) {
    setSession((await authApi.login(payload)).session)
  }

  /** Returns false when Supabase requires email confirmation before sign-in. */
  async function register(payload) {
    const { session: s } = await authApi.register(payload)
    if (!s) return false
    setSession(s)
    return true
  }

  async function logout() {
    setSession(null)
    try {
      await authApi.logout()
    } catch {
      // Already signed out locally; nothing else to do.
    }
  }

  return { session, user, isAuthenticated, ready, login, register, refreshMe, logout }
})
