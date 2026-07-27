import http from './http'

export function createOrder(payload) {
  return http.post('/orders', payload).then((r) => r.data)
}

export function fetchMyOrders() {
  return http.get('/orders').then((r) => r.data)
}

export function fetchOrder(reference) {
  return http.get(`/orders/${reference}`).then((r) => r.data)
}
