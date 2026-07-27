package com.econovations.backend.web;

import com.econovations.backend.dto.impact.ImpactResponse;
import com.econovations.backend.service.ImpactService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ImpactController {

    private final ImpactService impactService;

    public ImpactController(ImpactService impactService) {
        this.impactService = impactService;
    }

    @GetMapping("/impact")
    public ImpactResponse getImpact() {
        return impactService.getImpact();
    }
}
