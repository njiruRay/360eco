import { supabase, unwrap, apiError } from './client'

const PRODUCT_COLUMNS =
  '*, category:categories(name, slug), images:product_images(url, is_primary, sort_order)'

// Same shape as the old API's ProductResponse, so cards and detail pages are unchanged.
function toProduct(p) {
  const images = [...(p.images || [])]
    .sort((a, b) => a.sort_order - b.sort_order)
    .map((i) => ({ url: i.url, isPrimary: i.is_primary, sortOrder: i.sort_order }))
  const primary = images.find((i) => i.isPrimary) || images[0]
  return {
    id: p.id,
    name: p.name,
    slug: p.slug,
    description: p.description,
    price: p.price,
    unit: p.unit,
    categoryName: p.category?.name ?? null,
    categorySlug: p.category?.slug ?? null,
    stockQuantity: p.stock_quantity,
    minOrderQty: p.min_order_qty,
    inStock: p.stock_quantity > 0,
    primaryImageUrl: primary?.url ?? null,
    images,
  }
}

// Only visible products come back — hidden ones are filtered out by RLS.
export async function fetchProducts(category) {
  const rows = unwrap(await supabase.from('products').select(PRODUCT_COLUMNS).order('name'))
  const products = rows.map(toProduct)
  return category ? products.filter((p) => p.categorySlug === category) : products
}

export async function fetchProduct(slug) {
  const row = unwrap(
    await supabase.from('products').select(PRODUCT_COLUMNS).eq('slug', slug).maybeSingle(),
  )
  if (!row) throw apiError(`Product not found: ${slug}`, 404)
  return toProduct(row)
}

export async function fetchCategories() {
  return unwrap(await supabase.from('categories').select('id, name, slug').order('name'))
}
