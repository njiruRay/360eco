package com.econovations.backend.dto.order;

import com.econovations.backend.domain.Order;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record OrderResponse(
        Long id,
        String reference,
        String customerName,
        String customerPhone,
        String deliverySubCounty,
        String deliveryAddress,
        BigDecimal deliveryLat,
        BigDecimal deliveryLng,
        String status,
        String paymentMethod,
        BigDecimal subtotal,
        BigDecimal deliveryFee,
        BigDecimal totalAmount,
        Instant createdAt,
        List<Item> items) {

    public record Item(
            String productName, BigDecimal unitPrice, BigDecimal quantity, String unit, BigDecimal subtotal) {}

    public static OrderResponse from(Order o) {
        List<Item> items = o.getItems().stream()
                .map(i -> new Item(
                        i.getProductName(), i.getUnitPrice(), i.getQuantity(), i.getUnit(), i.getSubtotal()))
                .toList();
        return new OrderResponse(
                o.getId(),
                o.getReference(),
                o.getCustomerName(),
                o.getCustomerPhone(),
                o.getDeliverySubCounty(),
                o.getDeliveryAddress(),
                o.getDeliveryLat(),
                o.getDeliveryLng(),
                o.getStatus().name(),
                o.getPaymentMethod().name(),
                o.getSubtotal(),
                o.getDeliveryFee(),
                o.getTotalAmount(),
                o.getCreatedAt(),
                items);
    }
}
