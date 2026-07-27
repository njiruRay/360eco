package com.econovations.backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Sends transactional email when SMTP is configured (app.mail.enabled=true and
 * spring.mail.* set). In dev, with no SMTP, it logs the message instead so the
 * flow is fully testable without an email provider.
 */
@Service
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);

    private final ObjectProvider<JavaMailSender> mailSender;
    private final boolean enabled;
    private final String from;

    public MailService(
            ObjectProvider<JavaMailSender> mailSender,
            @Value("${app.mail.enabled:false}") boolean enabled,
            @Value("${app.mail.from:no-reply@econovations.com}") String from) {
        this.mailSender = mailSender;
        this.enabled = enabled;
        this.from = from;
    }

    public void sendPasswordReset(String to, String resetLink, long ttlMinutes) {
        String subject = "Reset your 360 Econovations password";
        String body = "Hi,\n\n"
                + "We received a request to reset your 360 Econovations password.\n"
                + "Use the link below to set a new one (valid for " + ttlMinutes + " minutes):\n\n"
                + resetLink + "\n\n"
                + "If you didn't request this, you can safely ignore this email.";

        JavaMailSender sender = mailSender.getIfAvailable();
        if (enabled && sender != null) {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom(from);
            msg.setTo(to);
            msg.setSubject(subject);
            msg.setText(body);
            sender.send(msg);
            log.info("Sent password-reset email to {}", to);
        } else {
            // Dev fallback: no SMTP configured — surface the link in the logs.
            log.warn("[DEV — no SMTP] Password-reset link for {}: {}", to, resetLink);
        }
    }
}
