package com.econovations.backend.web;

import com.econovations.backend.domain.ContactSubmission;
import com.econovations.backend.dto.contact.ContactRequest;
import com.econovations.backend.repository.ContactSubmissionRepository;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ContactController {

    private final ContactSubmissionRepository contactSubmissionRepository;

    public ContactController(ContactSubmissionRepository contactSubmissionRepository) {
        this.contactSubmissionRepository = contactSubmissionRepository;
    }

    @PostMapping("/contact")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> submit(@Valid @RequestBody ContactRequest request) {
        ContactSubmission submission = new ContactSubmission();
        submission.setName(request.name().trim());
        submission.setEmail(request.email());
        submission.setPhone(request.phone());
        submission.setMessage(request.message());
        contactSubmissionRepository.save(submission);
        return Map.of("id", submission.getId(), "message", "Thanks — we'll be in touch.");
    }
}
