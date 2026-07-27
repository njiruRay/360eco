package com.econovations.backend.web;

import com.econovations.backend.dto.catalog.CategoryResponse;
import com.econovations.backend.dto.catalog.ProductResponse;
import com.econovations.backend.service.CatalogService;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CatalogController {

    private final CatalogService catalogService;

    public CatalogController(CatalogService catalogService) {
        this.catalogService = catalogService;
    }

    @GetMapping("/products")
    public List<ProductResponse> listProducts(
            @RequestParam(name = "category", required = false) String category) {
        return catalogService.listProducts(category);
    }

    @GetMapping("/products/{slug}")
    public ProductResponse getProduct(@PathVariable String slug) {
        return catalogService.getProductBySlug(slug);
    }

    @GetMapping("/categories")
    public List<CategoryResponse> listCategories() {
        return catalogService.listCategories();
    }
}
