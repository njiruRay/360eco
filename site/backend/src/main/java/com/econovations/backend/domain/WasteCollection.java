package com.econovations.backend.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** An inbound batch of waste material collected from a club. */
@Entity
@Table(name = "waste_collections")
@Getter
@Setter
@NoArgsConstructor
public class WasteCollection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "club_id", nullable = false)
    private Club club;

    @Column(name = "collection_date", nullable = false)
    private LocalDate collectionDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "material_type", nullable = false)
    private MaterialType materialType;

    @Column(name = "weight_kg", nullable = false)
    private BigDecimal weightKg;

    @Column(name = "sub_county")
    private String subCounty;

    @Column(columnDefinition = "text")
    private String notes;
}
