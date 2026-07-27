package com.econovations.backend.domain;

/**
 * Order lifecycle status. Constant names are lowercase on purpose so
 * {@code @Enumerated(EnumType.STRING)} persists values that match the DB
 * CHECK constraint on orders.status.
 */
public enum OrderStatus {
    received,
    processing,
    out_for_delivery,
    delivered,
    cancelled
}
