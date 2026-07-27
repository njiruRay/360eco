package com.econovations.backend.dto.impact;

import java.math.BigDecimal;

public record ImpactResponse(
        BigDecimal glassTonnesDiverted,
        long householdsReached,
        long jobsCreated,
        long partnerClubs,
        BigDecimal totalWasteKg) {}
