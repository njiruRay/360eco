package com.econovations.backend.service;

import com.econovations.backend.domain.ClubStatus;
import com.econovations.backend.dto.impact.ImpactResponse;
import com.econovations.backend.repository.ClubRepository;
import com.econovations.backend.repository.SiteSettingRepository;
import com.econovations.backend.repository.WasteCollectionRepository;
import java.math.BigDecimal;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Impact stats. Human-curated figures (glass tonnes, households, jobs) come from
 * site_settings; partner-club count and total waste are computed live from the DB.
 */
@Service
@Transactional(readOnly = true)
public class ImpactService {

    private final SiteSettingRepository siteSettingRepository;
    private final WasteCollectionRepository wasteCollectionRepository;
    private final ClubRepository clubRepository;

    public ImpactService(
            SiteSettingRepository siteSettingRepository,
            WasteCollectionRepository wasteCollectionRepository,
            ClubRepository clubRepository) {
        this.siteSettingRepository = siteSettingRepository;
        this.wasteCollectionRepository = wasteCollectionRepository;
        this.clubRepository = clubRepository;
    }

    public ImpactResponse getImpact() {
        BigDecimal glassTonnes = settingDecimal("impact_glass_tonnes", BigDecimal.ZERO);
        long households = settingLong("impact_households", 0);
        long jobs = settingLong("impact_jobs_created", 0);
        long activeClubs = clubRepository.countByStatus(ClubStatus.active);
        BigDecimal totalWaste = wasteCollectionRepository.totalWeightKg();

        return new ImpactResponse(glassTonnes, households, jobs, activeClubs, totalWaste);
    }

    private BigDecimal settingDecimal(String key, BigDecimal fallback) {
        return siteSettingRepository
                .findByKey(key)
                .map(s -> {
                    try {
                        return new BigDecimal(s.getValue());
                    } catch (RuntimeException e) {
                        return fallback;
                    }
                })
                .orElse(fallback);
    }

    private long settingLong(String key, long fallback) {
        return siteSettingRepository
                .findByKey(key)
                .map(s -> {
                    try {
                        return Long.parseLong(s.getValue().trim());
                    } catch (RuntimeException e) {
                        return fallback;
                    }
                })
                .orElse(fallback);
    }
}
