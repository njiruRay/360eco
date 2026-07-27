package com.econovations.backend.dto.catalog;

import com.econovations.backend.domain.Product;
import java.math.BigDecimal;
import java.util.List;

public record ProductResponse(
        Long id,
        String name,
        String slug,
        String description,
        BigDecimal price,
        String unit,
        String categoryName,
        String categorySlug,
        BigDecimal stockQuantity,
        BigDecimal minOrderQty,
        boolean inStock,
        String primaryImageUrl,
        List<ImageResponse> images) {

    public record ImageResponse(String url, boolean isPrimary, int sortOrder) {}

    public static ProductResponse from(Product p) {
        List<ImageResponse> imgs = p.getImages().stream()
                .map(i -> new ImageResponse(i.getUrl(), i.isPrimary(), i.getSortOrder()))
                .toList();
        String primary = imgs.stream()
                .filter(ImageResponse::isPrimary)
                .map(ImageResponse::url)
                .findFirst()
                .orElseGet(() -> imgs.isEmpty() ? null : imgs.get(0).url());
        boolean inStock = p.getStockQuantity() != null
                && p.getStockQuantity().compareTo(BigDecimal.ZERO) > 0;
        return new ProductResponse(
                p.getId(),
                p.getName(),
                p.getSlug(),
                p.getDescription(),
                p.getPrice(),
                p.getUnit(),
                p.getCategory() != null ? p.getCategory().getName() : null,
                p.getCategory() != null ? p.getCategory().getSlug() : null,
                p.getStockQuantity(),
                p.getMinOrderQty(),
                inStock,
                primary,
                imgs);
    }
}
