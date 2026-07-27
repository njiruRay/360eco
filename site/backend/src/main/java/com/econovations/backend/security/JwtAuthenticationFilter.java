package com.econovations.backend.security;

import com.econovations.backend.repository.AdminUserRepository;
import com.econovations.backend.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/** Reads a Bearer JWT, validates it, and populates the SecurityContext. */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserRepository userRepository;
    private final AdminUserRepository adminUserRepository;

    public JwtAuthenticationFilter(
            JwtService jwtService,
            UserRepository userRepository,
            AdminUserRepository adminUserRepository) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;
        this.adminUserRepository = adminUserRepository;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            if (jwtService.isValid(token)
                    && SecurityContextHolder.getContext().getAuthentication() == null) {
                Long id = jwtService.extractUserId(token);
                if ("admin".equals(jwtService.extractType(token))) {
                    // Authorities come from the DB role, not the token claim.
                    adminUserRepository
                            .findById(id)
                            .ifPresent(admin -> {
                                AdminPrincipal principal = new AdminPrincipal(admin);
                                authenticate(principal, principal.getAuthorities(), request);
                            });
                } else {
                    userRepository
                            .findById(id)
                            .ifPresent(user -> {
                                AppUserPrincipal principal = new AppUserPrincipal(user);
                                authenticate(principal, principal.getAuthorities(), request);
                            });
                }
            }
        }
        filterChain.doFilter(request, response);
    }

    private void authenticate(Object principal, java.util.Collection<? extends org.springframework.security.core.GrantedAuthority> authorities, HttpServletRequest request) {
        var auth = new UsernamePasswordAuthenticationToken(principal, null, authorities);
        auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }
}
