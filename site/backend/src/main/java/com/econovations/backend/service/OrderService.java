package com.econovations.backend.service;

import com.econovations.backend.domain.Order;
import com.econovations.backend.domain.OrderItem;
import com.econovations.backend.domain.OrderStatus;
import com.econovations.backend.domain.Product;
import com.econovations.backend.dto.order.CreateOrderRequest;
import com.econovations.backend.dto.order.OrderResponse;
import com.econovations.backend.repository.OrderRepository;
import com.econovations.backend.repository.ProductRepository;
import com.econovations.backend.repository.SiteSettingRepository;
import com.econovations.backend.repository.UserRepository;
import com.econovations.backend.web.error.BadRequestException;
import com.econovations.backend.web.error.NotFoundException;
import java.math.BigDecimal;
import java.security.SecureRandom;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {

    private static final String REF_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private final SecureRandom random = new SecureRandom();

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final SiteSettingRepository siteSettingRepository;

    public OrderService(
            OrderRepository orderRepository,
            ProductRepository productRepository,
            UserRepository userRepository,
            SiteSettingRepository siteSettingRepository) {
        this.orderRepository = orderRepository;
        this.productRepository = productRepository;
        this.userRepository = userRepository;
        this.siteSettingRepository = siteSettingRepository;
    }

    /** Create an order. userId may be null for guest checkout. */
    @Transactional
    public OrderResponse create(Long userId, CreateOrderRequest request) {
        Order order = new Order();
        order.setCustomerName(request.customerName().trim());
        order.setCustomerPhone(request.customerPhone().trim());
        order.setDeliverySubCounty(request.deliverySubCounty());
        order.setDeliveryAddress(request.deliveryAddress());
        order.setDeliveryLat(request.deliveryLat());
        order.setDeliveryLng(request.deliveryLng());
        order.setPaymentMethod(request.paymentMethod());
        order.setStatus(OrderStatus.received);
        order.setReference(generateUniqueReference());

        if (userId != null) {
            userRepository.findById(userId).ifPresent(order::setUser);
        }

        BigDecimal subtotal = BigDecimal.ZERO;
        for (CreateOrderRequest.Item line : request.items()) {
            Product product = productRepository
                    .findById(line.productId())
                    .orElseThrow(() -> new NotFoundException("Product not found: " + line.productId()));
            if (!product.isVisible()) {
                throw new BadRequestException("Product is not available: " + product.getName());
            }
            if (line.quantity().compareTo(product.getMinOrderQty()) < 0) {
                throw new BadRequestException(
                        "Minimum order for " + product.getName() + " is " + product.getMinOrderQty()
                                + " " + product.getUnit());
            }

            BigDecimal lineSubtotal = product.getPrice().multiply(line.quantity());
            OrderItem item = new OrderItem();
            item.setProduct(product);
            item.setProductName(product.getName()); // snapshot
            item.setUnitPrice(product.getPrice()); // snapshot
            item.setUnit(product.getUnit()); // snapshot
            item.setQuantity(line.quantity());
            item.setSubtotal(lineSubtotal);
            order.addItem(item);

            subtotal = subtotal.add(lineSubtotal);
        }

        BigDecimal deliveryFee = deliveryFee();
        order.setSubtotal(subtotal);
        order.setDeliveryFee(deliveryFee);
        order.setTotalAmount(subtotal.add(deliveryFee));

        return OrderResponse.from(orderRepository.save(order));
    }

    @Transactional(readOnly = true)
    public OrderResponse getByReference(String reference) {
        return orderRepository
                .findByReference(reference)
                .map(OrderResponse::from)
                .orElseThrow(() -> new NotFoundException("Order not found: " + reference));
    }

    @Transactional(readOnly = true)
    public List<OrderResponse> listForUser(Long userId) {
        return orderRepository.findByUser_IdOrderByCreatedAtDesc(userId).stream()
                .map(OrderResponse::from)
                .toList();
    }

    /** Admin: all orders newest-first, optionally filtered by status. */
    @Transactional(readOnly = true)
    public List<OrderResponse> listAll(OrderStatus status) {
        List<Order> orders = status == null
                ? orderRepository.findAllByOrderByCreatedAtDesc()
                : orderRepository.findByStatusOrderByCreatedAtDesc(status);
        return orders.stream().map(OrderResponse::from).toList();
    }

    /** Admin: advance/set an order's status. */
    @Transactional
    public OrderResponse updateStatus(String reference, OrderStatus status) {
        Order order = orderRepository
                .findByReference(reference)
                .orElseThrow(() -> new NotFoundException("Order not found: " + reference));
        order.setStatus(status);
        return OrderResponse.from(orderRepository.save(order));
    }

    private BigDecimal deliveryFee() {
        return siteSettingRepository
                .findByKey("delivery_fee_default")
                .map(s -> {
                    try {
                        return new BigDecimal(s.getValue().trim());
                    } catch (RuntimeException e) {
                        return BigDecimal.ZERO;
                    }
                })
                .orElse(BigDecimal.ZERO);
    }

    private String generateUniqueReference() {
        for (int attempt = 0; attempt < 10; attempt++) {
            StringBuilder sb = new StringBuilder("ECN-");
            for (int i = 0; i < 6; i++) {
                sb.append(REF_ALPHABET.charAt(random.nextInt(REF_ALPHABET.length())));
            }
            String ref = sb.toString();
            if (!orderRepository.existsByReference(ref)) {
                return ref;
            }
        }
        throw new IllegalStateException("Could not generate a unique order reference");
    }
}
