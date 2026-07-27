package com.econovations.backend.dto.address;

import jakarta.validation.constraints.NotBlank;

public record AddressRequest(
        String label,
        @NotBlank String subCounty,
        String town,
        String street,
        boolean isDefault) {}
