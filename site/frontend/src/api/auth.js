import http from './http'

export function register(payload) {
  return http.post('/auth/register', payload).then((r) => r.data)
}

export function login(payload) {
  return http.post('/auth/login', payload).then((r) => r.data)
}

export function fetchMe() {
  return http.get('/me').then((r) => r.data)
}

export function forgotPassword(email) {
  return http.post('/auth/forgot-password', { email }).then((r) => r.data)
}

export function resetPassword(token, newPassword) {
  return http.post('/auth/reset-password', { token, newPassword }).then((r) => r.data)
}
