package com.econovations.backend.config;

import com.econovations.backend.security.JwtAuthenticationFilter;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.http.HttpStatus;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

/**
 * Stateless JWT security. Public endpoints (catalog, auth, contact, impact,
 * content, guest order creation, order tracking) are open; the rest require a
 * valid Bearer token.
 */
@Configuration
public class SecurityConfig {

    @Value("${app.cors.allowed-origins}")
    private List<String> allowedOrigins;

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                // Permit the error dispatch so sendError(403/404/...) isn't re-secured
                // into a 401 on the ERROR forward.
                .requestMatchers("/error").permitAll()
                .requestMatchers("/health").permitAll()
                .requestMatchers("/auth/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/products", "/products/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/categories", "/categories/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/content/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/impact").permitAll()
                .requestMatchers(HttpMethod.POST, "/contact").permitAll()
                // Order creation allows guests; listing "my orders" requires auth;
                // tracking a single order by reference is public.
                .requestMatchers(HttpMethod.POST, "/orders").permitAll()
                .requestMatchers(HttpMethod.GET, "/orders").authenticated()
                .requestMatchers(HttpMethod.GET, "/orders/*").permitAll()
                // Admin: login public; status changes need manager+, viewing needs any admin role.
                .requestMatchers("/admin/auth/**").permitAll()
                .requestMatchers(HttpMethod.PATCH, "/admin/orders/*/status").hasAnyRole("SUPER_ADMIN", "MANAGER")
                .requestMatchers("/admin/**").hasAnyRole("SUPER_ADMIN", "MANAGER", "VIEWER")
                .anyRequest().authenticated())
            .exceptionHandling(ex -> ex
                // 401 when no/invalid credentials; 403 when authenticated but lacking the role.
                .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED))
                .accessDeniedHandler((req, res, denied) -> res.sendError(HttpStatus.FORBIDDEN.value())))
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config)
            throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        // Patterns (not exact origins) so any localhost / 127.0.0.1 / LAN-IP dev
        // origin on any port is accepted (Vite may use 5173/5174, phones use LAN IP).
        config.setAllowedOriginPatterns(allowedOrigins);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
