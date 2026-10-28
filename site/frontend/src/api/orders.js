import { supabase, unwrap, apiError } from './client'

// Orders are written only by the place_order() database function, which looks
// up prices and computes totals itself — nothing price-related is sent from here.
export async function createOrder(payload) {
  return unwrap(
    await supabase.rpc('place_order', {
      p_customer_name: payload.customerName,
      p_customer_phone: payload.customerPhone,
      p_payment_method: payload.paymentMethod,
      p_items: payload.items.map((i) => ({ productId: i.productId, quantity: i.quantity })),
      p_delivery_sub_county: payload.deliverySubCounty ?? null,
      p_delivery_address: payload.deliveryAddress ?? null,
      p_delivery_lat: payload.deliveryLat ?? null,
      p_delivery_lng: payload.deliveryLng ?? null,
    }),
  )
}

// Same shape place_order() / track_order() return (and the old OrderResponse).
function toOrder(o) {
  return {
    id: o.id,
    reference: o.reference,
    customerName: o.customer_name,
    customerPhone: o.customer_phone,
    deliverySubCounty: o.delivery_sub_county,
    deliveryAddress: o.delivery_address,
    deliveryLat: o.delivery_lat,
    deliveryLng: o.delivery_lng,
    status: o.status,
    paymentMethod: o.payment_method,
    subtotal: o.subtotal,
    deliveryFee: o.delivery_fee,
    totalAmount: o.total_amount,
    createdAt: o.created_at,
    whatsappSentAt: o.whatsapp_sent_at,
    items: (o.order_items || []).map((i) => ({
      productName: i.product_name,
      unitPrice: i.unit_price,
      quantity: i.quantity,
      unit: i.unit,
      subtotal: i.subtotal,
    })),
  }
}

// RLS limits this to the signed-in customer's own orders.
export async function fetchMyOrders() {
  const rows = unwrap(
    await supabase
      .from('orders')
      .select('*, order_items(*)')
      .order('created_at', { ascending: false })
      .order('id', { referencedTable: 'order_items' }),
  )
  return rows.map(toOrder)
}

export async function fetchOrder(reference) {
  const order = unwrap(await supabase.rpc('track_order', { p_reference: reference }))
  if (!order) throw apiError(`Order not found: ${reference}`, 404)
  return order
}

// Called when the customer taps "Send on WhatsApp" — that's what confirms the order.
export async function confirmOrderWhatsApp(reference) {
  const order = unwrap(await supabase.rpc('confirm_order_whatsapp', { p_reference: reference }))
  if (!order) throw apiError(`Order not found: ${reference}`, 404)
  return order
}
