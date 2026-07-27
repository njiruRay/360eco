package com.econovations.backend.config;

import com.econovations.backend.domain.AdminUser;
import com.econovations.backend.domain.Role;
import com.econovations.backend.repository.AdminUserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Seeds a default super_admin the first time the app boots against an empty
 * admin_users table, so the admin dashboard can be logged into during
 * development. Credentials are overridable via ADMIN_EMAIL / ADMIN_PASSWORD.
 */
@Configuration
public class AdminBootstrap {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrap.class);

    @Bean
    CommandLineRunner seedDefaultAdmin(
            AdminUserRepository adminUsers,
            PasswordEncoder passwordEncoder,
            @Value("${app.admin.bootstrap-email}") String email,
            @Value("${app.admin.bootstrap-password}") String password) {
        return args -> {
            if (adminUsers.count() > 0) {
                return;
            }
            AdminUser admin = new AdminUser();
            admin.setName("Administrator");
            admin.setEmail(email.trim().toLowerCase());
            admin.setPasswordHash(passwordEncoder.encode(password));
            admin.setRole(Role.super_admin);
            adminUsers.save(admin);
            log.warn("Seeded default super_admin '{}'. Change the password before any real deployment "
                    + "(set ADMIN_PASSWORD / add a proper admin-management flow).", admin.getEmail());
        };
    }
}
