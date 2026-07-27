package com.econovations.backend.web.error;

/** Thrown when a request conflicts with existing state (e.g. duplicate email). Mapped to HTTP 409. */
public class ConflictException extends RuntimeException {
    public ConflictException(String message) {
        super(message);
    }
}
