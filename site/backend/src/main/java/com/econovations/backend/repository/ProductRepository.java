package com.econovations.backend.repository;

import com.econovations.backend.domain.Product;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<Product, Long> {

    @EntityGraph(attributePaths = {"images", "category"})
    List<Product> findByIsVisibleTrueOrderByNameAsc();

    @EntityGraph(attributePaths = {"images", "category"})
    List<Product> findByIsVisibleTrueAndCategory_SlugOrderByNameAsc(String categorySlug);

    @EntityGraph(attributePaths = {"images", "category"})
    Optional<Product> findBySlug(String slug);
}
