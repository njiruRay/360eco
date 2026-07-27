package com.econovations.backend.service;

import com.econovations.backend.dto.catalog.CategoryResponse;
import com.econovations.backend.dto.catalog.ProductResponse;
import com.econovations.backend.repository.CategoryRepository;
import com.econovations.backend.repository.ProductRepository;
import com.econovations.backend.web.error.NotFoundException;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class CatalogService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;

    public CatalogService(ProductRepository productRepository, CategoryRepository categoryRepository) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
    }

    /** Visible products, optionally filtered by category slug. */
    public List<ProductResponse> listProducts(String categorySlug) {
        var products = (categorySlug == null || categorySlug.isBlank())
                ? productRepository.findByIsVisibleTrueOrderByNameAsc()
                : productRepository.findByIsVisibleTrueAndCategory_SlugOrderByNameAsc(categorySlug);
        return products.stream().map(ProductResponse::from).toList();
    }

    public ProductResponse getProductBySlug(String slug) {
        return productRepository
                .findBySlug(slug)
                .filter(p -> p.isVisible())
                .map(ProductResponse::from)
                .orElseThrow(() -> new NotFoundException("Product not found: " + slug));
    }

    public List<CategoryResponse> listCategories() {
        return categoryRepository.findAllByOrderByNameAsc().stream()
                .map(CategoryResponse::from)
                .toList();
    }
}
