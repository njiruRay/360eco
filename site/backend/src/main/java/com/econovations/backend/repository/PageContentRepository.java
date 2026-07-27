package com.econovations.backend.repository;

import com.econovations.backend.domain.PageContent;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PageContentRepository extends JpaRepository<PageContent, Long> {
    Optional<PageContent> findByPageSlugAndSectionKey(String pageSlug, String sectionKey);
}
