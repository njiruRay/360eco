import http from './http'

export function fetchContent(pageSlug, sectionKey) {
  return http.get(`/content/${pageSlug}/${sectionKey}`).then((r) => r.data)
}

export function fetchImpact() {
  return http.get('/impact').then((r) => r.data)
}

export function submitContact(payload) {
  return http.post('/contact', payload).then((r) => r.data)
}
