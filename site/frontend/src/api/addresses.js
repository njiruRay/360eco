import http from './http'

export function fetchAddresses() {
  return http.get('/addresses').then((r) => r.data)
}

export function createAddress(payload) {
  return http.post('/addresses', payload).then((r) => r.data)
}

export function updateAddress(id, payload) {
  return http.put(`/addresses/${id}`, payload).then((r) => r.data)
}

export function deleteAddress(id) {
  return http.delete(`/addresses/${id}`).then((r) => r.data)
}
