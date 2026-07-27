package com.econovations.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

/** CMS content for a page section, stored as JSONB. */
@Entity
@Table(name = "page_content")
@Getter
@Setter
@NoArgsConstructor
public class PageContent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "page_slug", nullable = false)
    private String pageSlug;

    @Column(name = "section_key", nullable = false)
    private String sectionKey;

    // Raw JSON string; mapped to the jsonb column.
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false, columnDefinition = "jsonb")
    private String content = "{}";

    @Column(name = "updated_by")
    private Long updatedBy;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
