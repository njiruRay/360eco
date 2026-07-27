package com.econovations.backend.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Partner organisation that supplies waste material. */
@Entity
@Table(name = "clubs")
@Getter
@Setter
@NoArgsConstructor
public class Club {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(name = "sub_county")
    private String subCounty;

    @Column(name = "contact_person")
    private String contactPerson;

    private String phone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ClubStatus status = ClubStatus.onboarding;

    @Column(name = "joined_at", nullable = false)
    private LocalDate joinedAt;
}
