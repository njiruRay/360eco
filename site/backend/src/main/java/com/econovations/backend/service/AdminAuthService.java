package com.econovations.backend.service;

import com.econovations.backend.domain.AdminUser;
import com.econovations.backend.dto.admin.AdminAuthResponse;
import com.econovations.backend.dto.auth.LoginRequest;
import com.econovations.backend.repository.AdminUserRepository;
import com.econovations.backend.security.JwtService;
import java.time.Instant;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminAuthService {

    private final AdminUserRepository adminUserRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AdminAuthService(
            AdminUserRepository adminUserRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService) {
        this.adminUserRepository = adminUserRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AdminAuthResponse login(LoginRequest request) {
        String email = request.email().trim().toLowerCase();
        AdminUser admin = adminUserRepository
                .findByEmail(email)
                .filter(a -> passwordEncoder.matches(request.password(), a.getPasswordHash()))
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        admin.setLastLogin(Instant.now()); // persisted via dirty checking
        String token = jwtService.generateAdminToken(admin.getId(), admin.getEmail(), admin.getRole().name());
        return new AdminAuthResponse(
                token, admin.getId(), admin.getName(), admin.getEmail(), admin.getRole().name());
    }
}
