import axios from 'axios'

// Absolute API base URL. The Android / iOS Capacitor WebView cannot reach
// `localhost`, so every production build must set VITE_API_URL to the public API
// (see .env.example). The localhost fallback is deliberately dev-only: baking it
// into a production bundle would make every call fail as blocked mixed content
// (HTTPS page -> HTTP request), which is confusing to diagnose.
const baseURL =
  import.meta.env.VITE_API_URL || (import.meta.env.DEV ? 'http://localhost:8080/api' : '/api')

const http = axios.create({
  baseURL,
  headers: { 'Content-Type': 'application/json' },
})

// Attach JWT (once auth is built in Phase 2) to every request.
http.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

export default http
