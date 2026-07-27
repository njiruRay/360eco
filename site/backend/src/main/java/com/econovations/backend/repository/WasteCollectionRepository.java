package com.econovations.backend.repository;

import com.econovations.backend.domain.MaterialType;
import com.econovations.backend.domain.WasteCollection;
import java.math.BigDecimal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface WasteCollectionRepository extends JpaRepository<WasteCollection, Long> {

    @Query("SELECT COALESCE(SUM(w.weightKg), 0) FROM WasteCollection w")
    BigDecimal totalWeightKg();

    @Query("SELECT COALESCE(SUM(w.weightKg), 0) FROM WasteCollection w WHERE w.materialType = :type")
    BigDecimal totalWeightKgByMaterial(@Param("type") MaterialType type);
}
