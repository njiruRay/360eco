package com.econovations.backend.dto.admin;

import com.econovations.backend.domain.OrderStatus;
import jakarta.validation.constraints.NotNull;

/** Body for advancing an order's status. Invalid enum values yield a 400. */
public record UpdateOrderStatusRequest(@NotNull OrderStatus status) {}
