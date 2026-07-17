package com.example.urgs_api.config;

import java.util.Arrays;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final AuthenticationInterceptor authenticationInterceptor;
    private final AuthorizationInterceptor authorizationInterceptor;

    @Value("${urgs.cors.allowed-origins:http://localhost:3000,http://127.0.0.1:3000,http://tauri.localhost,https://tauri.localhost}")
    private String allowedOrigins;

    public WebConfig(AuthenticationInterceptor authenticationInterceptor,
            AuthorizationInterceptor authorizationInterceptor) {
        this.authenticationInterceptor = authenticationInterceptor;
        this.authorizationInterceptor = authorizationInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(authenticationInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns("/api/auth/login", "/api/auth/register", "/api/auth/sso/**", "/profile/**",
                        "/api/internal/**", "/api/webhook/**", "/api/online-documents/*/onlyoffice/callback");

        registry.addInterceptor(authorizationInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns("/api/im/**", "/api/internal/**", "/api/webhook/**",
                        "/api/online-documents/*/onlyoffice/callback");
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        String[] origins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .toArray(String[]::new);

        registerDesktopCors(registry, "/api/**", origins);
        registerDesktopCors(registry, "/uploads/**", origins);
        registerDesktopCors(registry, "/profile/**", origins);
    }

    private void registerDesktopCors(CorsRegistry registry, String pathPattern, String[] origins) {
        registry.addMapping(pathPattern)
                .allowedOrigins(origins)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS")
                .allowedHeaders("*")
                .exposedHeaders("Content-Disposition")
                .allowCredentials(false)
                .maxAge(3600);
    }

    @Value("${urgs.profile:./uploads}")
    private String profile;

    @Override
    public void addResourceHandlers(
            org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry registry) {
        String absolutePath = new java.io.File(profile).getAbsolutePath();
        registry.addResourceHandler("/profile/**")
                .addResourceLocations("file:" + absolutePath + "/");
    }
}
