package com.econovations.backend.repository;

import com.econovations.backend.domain.Order;
import com.econovations.backend.domain.OrderStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<Order, Long> {

    @EntityGraph(attributePaths = "items")
    Optional<Order> findByReference(String reference);

    List<Order> findByUser_IdOrderByCreatedAtDesc(Long userId);

    boolean existsByReference(String reference);

    // Admin listings — items fetched eagerly so mapping works with open-in-view=false.
    @EntityGraph(attributePaths = "items")
    List<Order> findAllByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = "items")
    List<Order> findByStatusOrderByCreatedAtDesc(OrderStatus status);
}
