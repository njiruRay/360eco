package com.econovations.backend.web;

import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Liveness + database check at GET /api/health (context-path /api + mapping
 * /health). Runs a real query on every call so the uptime pinger also counts
 * as database activity (keeps the free Supabase project from pausing), and
 * returns 503 when the database is unreachable so the pinger can alert.
 */
@RestController
public class HealthController {

    private final JdbcTemplate jdbcTemplate;

    public HealthController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        try {
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            return ResponseEntity.ok(Map.of(
                    "status", "ok", "database", "up", "service", "360-econovations-api"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of(
                    "status", "error", "database", "down", "service", "360-econovations-api"));
        }
    }
}
