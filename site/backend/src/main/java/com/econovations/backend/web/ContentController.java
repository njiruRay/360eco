package com.econovations.backend.web;

import com.econovations.backend.service.ContentService;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Serves CMS/page content, e.g. Sell-To-Us buying prices. */
@RestController
@RequestMapping("/content")
public class ContentController {

    private final ContentService contentService;

    public ContentController(ContentService contentService) {
        this.contentService = contentService;
    }

    /** Returns the stored JSONB as-is (the raw string is already valid JSON). */
    @GetMapping(value = "/{pageSlug}/{sectionKey}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<String> getContent(
            @PathVariable String pageSlug, @PathVariable String sectionKey) {
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(contentService.getContentJson(pageSlug, sectionKey));
    }
}
