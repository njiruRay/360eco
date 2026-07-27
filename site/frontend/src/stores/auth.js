import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import * as authApi from '@/api/auth'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('auth_token') || null)
  const user = ref(JSON.parse(localStorage.getItem('auth_user') || 'null'))

  const isAuthenticated = computed(() => !!token.value)

  function setSession(auth) {
    token.value = auth.token
    user.value = { id: auth.userId, fullName: auth.fullName, email: auth.email }
    localStorage.setItem('auth_token', auth.token)
    localStorage.setItem('auth_user', JSON.stringify(user.value))
  }

  async function login(payload) {
    setSession(await authApi.login(payload))
  }

  async function register(payload) {
    setSession(await authApi.register(payload))
  }

  async function refreshMe() {
    if (!token.value) return
    try {
      const me = await authApi.fetchMe()
      user.value = { id: me.id, fullName: me.fullName, email: me.email, phone: me.phone }
      localStorage.setItem('auth_user', JSON.stringify(user.value))
    } catch (e) {
      // Token expired or invalid — clear the stale session.
      if (e?.response?.status === 401) logout()
    }
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('auth_token')
    localStorage.removeItem('auth_user')
  }

  return { token, user, isAuthenticated, login, register, refreshMe, logout }
})
