package com.econovations.backend.dto.auth;

public record AuthResponse(String token, Long userId, String fullName, String email) {}
