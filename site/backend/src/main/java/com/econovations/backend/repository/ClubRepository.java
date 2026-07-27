package com.econovations.backend.repository;

import com.econovations.backend.domain.Club;
import com.econovations.backend.domain.ClubStatus;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClubRepository extends JpaRepository<Club, Long> {
    long countByStatus(ClubStatus status);
}
