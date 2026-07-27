import http from './http'

export function fetchProducts(category) {
  return http
    .get('/products', { params: category ? { category } : {} })
    .then((r) => r.data)
}

export function fetchProduct(slug) {
  return http.get(`/products/${slug}`).then((r) => r.data)
}

export function fetchCategories() {
  return http.get('/categories').then((r) => r.data)
}
