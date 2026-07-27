package com.econovations.backend.dto.order;

import com.econovations.backend.domain.PaymentMethod;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.List;

public record CreateOrderRequest(
        @NotBlank String customerName,
        @NotBlank String customerPhone,
        String deliverySubCounty,
        String deliveryAddress,
        BigDecimal deliveryLat,
        BigDecimal deliveryLng,
        @NotNull PaymentMethod paymentMethod,
        @NotEmpty @Valid List<Item> items) {

    public record Item(
            @NotNull Long productId,
            @NotNull @DecimalMin(value = "0.01") BigDecimal quantity) {}
}
