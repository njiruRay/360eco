package com.econovations.backend.domain;

/** Admin staff roles. Lowercase names match the DB CHECK on admin_users.role. */
public enum Role {
    super_admin,
    manager,
    viewer
}
