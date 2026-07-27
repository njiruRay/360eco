package com.econovations.backend.repository;

import com.econovations.backend.domain.SiteSetting;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SiteSettingRepository extends JpaRepository<SiteSetting, Long> {
    Optional<SiteSetting> findByKey(String key);

    List<SiteSetting> findByKeyStartingWith(String prefix);
}
