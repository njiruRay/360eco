package com.econovations.backend.repository;

import com.econovations.backend.domain.Category;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    List<Category> findAllByOrderByNameAsc();

    Optional<Category> findBySlug(String slug);
}
