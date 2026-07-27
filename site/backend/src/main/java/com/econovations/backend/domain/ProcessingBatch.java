package com.econovations.backend.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** A production run turning collected material into product. */
@Entity
@Table(name = "processing_batches")
@Getter
@Setter
@NoArgsConstructor
public class ProcessingBatch {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "collection_id")
    private WasteCollection collection;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @Column(name = "input_weight", nullable = false)
    private BigDecimal inputWeight;

    @Column(name = "output_weight", nullable = false)
    private BigDecimal outputWeight;

    // Computed by the database (GENERATED ALWAYS) — read-only in the app.
    @Column(name = "yield_pct", insertable = false, updatable = false)
    private BigDecimal yieldPct;

    @Column(name = "processed_date", nullable = false)
    private LocalDate processedDate;
}
