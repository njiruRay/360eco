package com.econovations.backend.web;

import com.econovations.backend.dto.order.CreateOrderRequest;
import com.econovations.backend.dto.order.OrderResponse;
import com.econovations.backend.security.AppUserPrincipal;
import com.econovations.backend.service.OrderService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    /** Create an order. Works for guests (principal null) and logged-in customers. */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public OrderResponse create(
            @AuthenticationPrincipal AppUserPrincipal user,
            @Valid @RequestBody CreateOrderRequest request) {
        Long userId = user != null ? user.getId() : null;
        return orderService.create(userId, request);
    }

    /** List the authenticated customer's orders. */
    @GetMapping
    public List<OrderResponse> myOrders(@AuthenticationPrincipal AppUserPrincipal user) {
        return orderService.listForUser(user.getId());
    }

    /** Track a single order by its reference (public). */
    @GetMapping("/{reference}")
    public OrderResponse getByReference(@PathVariable String reference) {
        return orderService.getByReference(reference);
    }
}
