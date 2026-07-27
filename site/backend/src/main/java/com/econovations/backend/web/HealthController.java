package com.econovations.backend.web;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Simple liveness endpoint to confirm the API is up. Reachable at
 * GET /api/health (context-path /api + mapping /health).
 */
@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "ok", "service", "360-econovations-api");
    }
}
