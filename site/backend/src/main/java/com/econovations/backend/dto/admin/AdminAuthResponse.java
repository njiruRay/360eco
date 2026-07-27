package com.econovations.backend.dto.admin;

public record AdminAuthResponse(String token, Long adminId, String name, String email, String role) {}
