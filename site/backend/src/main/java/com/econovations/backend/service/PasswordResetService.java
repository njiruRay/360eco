package com.econovations.backend.service;

import com.econovations.backend.domain.PasswordResetToken;
import com.econovations.backend.domain.User;
import com.econovations.backend.repository.PasswordResetTokenRepository;
import com.econovations.backend.repository.UserRepository;
import com.econovations.backend.web.error.BadRequestException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PasswordResetService {

    private final SecureRandom random = new SecureRandom();

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final MailService mailService;
    private final String frontendUrl;
    private final long ttlMinutes;

    public PasswordResetService(
            UserRepository userRepository,
            PasswordResetTokenRepository tokenRepository,
            PasswordEncoder passwordEncoder,
            MailService mailService,
            @Value("${app.frontend-url:http://localhost:5174}") String frontendUrl,
            @Value("${app.reset.token-ttl-minutes:60}") long ttlMinutes) {
        this.userRepository = userRepository;
        this.tokenRepository = tokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.mailService = mailService;
        this.frontendUrl = frontendUrl.replaceAll("/+$", "");
        this.ttlMinutes = ttlMinutes;
    }

    /**
     * Issue a reset token and email it. Always returns silently — the caller
     * responds with a generic message so an attacker can't probe which emails
     * are registered (no user enumeration).
     */
    @Transactional
    public void requestReset(String email) {
        String normalized = email.trim().toLowerCase();
        userRepository.findByEmail(normalized).ifPresent(user -> {
            tokenRepository.deleteByUser_Id(user.getId()); // invalidate any prior tokens

            byte[] raw = new byte[32];
            random.nextBytes(raw);
            String token = Base64.getUrlEncoder().withoutPadding().encodeToString(raw);

            PasswordResetToken entity = new PasswordResetToken();
            entity.setUser(user);
            entity.setTokenHash(sha256Hex(token));
            entity.setExpiresAt(Instant.now().plus(Duration.ofMinutes(ttlMinutes)));
            tokenRepository.save(entity);

            String link = frontendUrl + "/reset-password?token=" + token;
            mailService.sendPasswordReset(user.getEmail(), link, ttlMinutes);
        });
    }

    /** Consume a valid token and set the new password. */
    @Transactional
    public void reset(String token, String newPassword) {
        PasswordResetToken entity = tokenRepository
                .findByTokenHash(sha256Hex(token))
                .filter(t -> t.getUsedAt() == null && t.getExpiresAt().isAfter(Instant.now()))
                .orElseThrow(() -> new BadRequestException(
                        "This reset link is invalid or has expired. Please request a new one."));

        User user = entity.getUser();
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        entity.setUsedAt(Instant.now()); // single-use; persisted via dirty checking
    }

    private static String sha256Hex(String value) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
