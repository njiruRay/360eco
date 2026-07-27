package com.econovations.backend.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** A customer's saved delivery location. */
@Entity
@Table(name = "addresses")
@Getter
@Setter
@NoArgsConstructor
public class Address {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private String label;

    @Column(name = "sub_county", nullable = false)
    private String subCounty;

    private String town;

    private String street;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault = false;
}
