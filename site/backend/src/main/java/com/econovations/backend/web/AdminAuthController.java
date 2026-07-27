package com.econovations.backend.web;

import com.econovations.backend.dto.admin.AdminAuthResponse;
import com.econovations.backend.dto.auth.LoginRequest;
import com.econovations.backend.service.AdminAuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin/auth")
public class AdminAuthController {

    private final AdminAuthService adminAuthService;

    public AdminAuthController(AdminAuthService adminAuthService) {
        this.adminAuthService = adminAuthService;
    }

    @PostMapping("/login")
    public AdminAuthResponse login(@Valid @RequestBody LoginRequest request) {
        return adminAuthService.login(request);
    }
}
