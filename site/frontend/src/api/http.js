import axios from 'axios'

// Absolute API base URL. In the browser this can be relative, but the Android /
// iOS Capacitor WebView cannot reach `localhost`, so we always resolve to an
// absolute URL via VITE_API_URL (see .env). Falls back to the local dev server.
const baseURL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api'

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
