package com.econovations.backend.web;

import com.econovations.backend.domain.OrderStatus;
import com.econovations.backend.dto.admin.UpdateOrderStatusRequest;
import com.econovations.backend.dto.order.OrderResponse;
import com.econovations.backend.service.OrderService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Staff order management. All routes require an admin token; the status update
 * additionally requires SUPER_ADMIN or MANAGER (enforced in SecurityConfig).
 */
@RestController
@RequestMapping("/admin/orders")
public class AdminOrderController {

    private final OrderService orderService;

    public AdminOrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    /** List all orders (newest first), optionally filtered by status. */
    @GetMapping
    public List<OrderResponse> list(@RequestParam(name = "status", required = false) OrderStatus status) {
        return orderService.listAll(status);
    }

    /** Single order by reference. */
    @GetMapping("/{reference}")
    public OrderResponse get(@PathVariable String reference) {
        return orderService.getByReference(reference);
    }

    /** Advance/set an order's status. */
    @PatchMapping("/{reference}/status")
    public OrderResponse updateStatus(
            @PathVariable String reference, @Valid @RequestBody UpdateOrderStatusRequest request) {
        return orderService.updateStatus(reference, request.status());
    }
}
