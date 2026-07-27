package com.econovations.backend.repository;

import com.econovations.backend.domain.Address;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AddressRepository extends JpaRepository<Address, Long> {
    List<Address> findByUser_IdOrderByIsDefaultDescIdAsc(Long userId);

    Optional<Address> findByIdAndUser_Id(Long id, Long userId);
}
