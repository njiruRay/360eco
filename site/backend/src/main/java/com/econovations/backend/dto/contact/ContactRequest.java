package com.econovations.backend.dto.contact;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ContactRequest(
        @NotBlank String name,
        @Email String email,
        String phone,
        @NotBlank @Size(max = 4000) String message) {}
