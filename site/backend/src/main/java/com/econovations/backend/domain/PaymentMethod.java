package com.econovations.backend.domain;

/**
 * Accepted payment methods — cash only, plus bitcoin. No payment gateway,
 * no M-Pesa. Lowercase names match the DB CHECK on orders.payment_method.
 */
public enum PaymentMethod {
    cash_on_delivery,
    cash_in_person,
    bitcoin
}
