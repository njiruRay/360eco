package com.econovations.backend.web;

import com.econovations.backend.domain.User;
import com.econovations.backend.repository.UserRepository;
import com.econovations.backend.security.AppUserPrincipal;
import com.econovations.backend.web.error.NotFoundException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** Current authenticated customer's profile. */
@RestController
public class AccountController {

    private final UserRepository userRepository;

    public AccountController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public record MeResponse(Long id, String fullName, String email, String phone) {}

    @GetMapping("/me")
    public MeResponse me(@AuthenticationPrincipal AppUserPrincipal principal) {
        User user = userRepository
                .findById(principal.getId())
                .orElseThrow(() -> new NotFoundException("User not found"));
        return new MeResponse(user.getId(), user.getFullName(), user.getEmail(), user.getPhone());
    }
}
