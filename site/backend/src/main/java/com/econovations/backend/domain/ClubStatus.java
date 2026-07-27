package com.econovations.backend.domain;

/** Partner club status. Lowercase names match the DB CHECK on clubs.status. */
public enum ClubStatus {
    active,
    onboarding,
    inactive
}
