package com.econovations.backend.service;

import com.econovations.backend.repository.PageContentRepository;
import com.econovations.backend.web.error.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class ContentService {

    private final PageContentRepository pageContentRepository;

    public ContentService(PageContentRepository pageContentRepository) {
        this.pageContentRepository = pageContentRepository;
    }

    /** Returns the stored JSONB content as a raw JSON string. */
    public String getContentJson(String pageSlug, String sectionKey) {
        return pageContentRepository
                .findByPageSlugAndSectionKey(pageSlug, sectionKey)
                .map(pc -> pc.getContent())
                .orElseThrow(() -> new NotFoundException(
                        "No content for " + pageSlug + "/" + sectionKey));
    }
}
