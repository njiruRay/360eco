// Business WhatsApp line that receives orders (international format, digits only).
export const WHATSAPP_NUMBER = '254743049413'
export const WHATSAPP_DISPLAY = '+254 743 049 413'

const money = (n) => `KES ${Number(n).toLocaleString('en-KE', { maximumFractionDigits: 0 })}`

export const PAYMENT_LABELS = { cash_on_delivery: 'Cash on Delivery', bitcoin: 'Bitcoin' }

/**
 * wa.me link that opens WhatsApp with the order typed out, addressed to the
 * business line. The customer presses Send — nothing is sent automatically.
 * Tapping the link (see confirmOrderWhatsApp) is what marks the order confirmed.
 */
export function orderWhatsAppLink(order) {
  const lines = [
    "Hello 360 Econovations, I've just placed an order.",
    '',
    `Order: ${order.reference}`,
    `Name: ${order.customerName}`,
    `Phone: ${order.customerPhone}`,
  ]
  const delivery = [order.deliverySubCounty, order.deliveryAddress].filter(Boolean).join(' — ')
  if (delivery) lines.push(`Delivery: ${delivery}`)
  if (order.deliveryLat != null && order.deliveryLng != null) {
    lines.push(`Location: https://maps.google.com/?q=${order.deliveryLat},${order.deliveryLng}`)
  }
  lines.push('')
  for (const item of order.items) {
    lines.push(`• ${item.productName} × ${item.quantity} ${item.unit} — ${money(item.subtotal)}`)
  }
  lines.push(
    '',
    `Subtotal: ${money(order.subtotal)}`,
    `Delivery fee: ${money(order.deliveryFee)}`,
    `Total: ${money(order.totalAmount)}`,
    `Payment: ${PAYMENT_LABELS[order.paymentMethod] || order.paymentMethod}`,
  )
  return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(lines.join('\n'))}`
}
