package com.econovations.backend.web;

import com.econovations.backend.dto.auth.AuthResponse;
import com.econovations.backend.dto.auth.ForgotPasswordRequest;
import com.econovations.backend.dto.auth.LoginRequest;
import com.econovations.backend.dto.auth.RegisterRequest;
import com.econovations.backend.dto.auth.ResetPasswordRequest;
import com.econovations.backend.service.AuthService;
import com.econovations.backend.service.PasswordResetService;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;
    private final PasswordResetService passwordResetService;

    public AuthController(AuthService authService, PasswordResetService passwordResetService) {
        this.authService = authService;
        this.passwordResetService = passwordResetService;
    }

    @PostMapping("/register")
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    /** Request a reset link. Always 200 with a generic message (no user enumeration). */
    @PostMapping("/forgot-password")
    public Map<String, String> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        passwordResetService.requestReset(request.email());
        return Map.of("message", "If an account exists for that email, a password reset link has been sent.");
    }

    /** Complete the reset with the token from the emailed link. */
    @PostMapping("/reset-password")
    public Map<String, String> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        passwordResetService.reset(request.token(), request.newPassword());
        return Map.of("message", "Your password has been reset. You can now sign in.");
    }
}
