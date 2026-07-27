package com.econovations.backend.security;

import com.econovations.backend.domain.AdminUser;
import com.econovations.backend.domain.Role;
import java.util.Collection;
import java.util.List;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

/**
 * Security principal for an authenticated admin/staff user. The granted
 * authority is derived from the DB role (e.g. super_admin -> ROLE_SUPER_ADMIN)
 * so route-level {@code hasRole(...)} checks work.
 */
public class AdminPrincipal {

    private final Long id;
    private final String email;
    private final Role role;

    public AdminPrincipal(AdminUser admin) {
        this.id = admin.getId();
        this.email = admin.getEmail();
        this.role = admin.getRole();
    }

    public Long getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public Role getRole() {
        return role;
    }

    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.name().toUpperCase()));
    }
}
