package com.example.urgs_api.config;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.handler.MappedInterceptor;
import org.springframework.web.util.ServletRequestPathUtils;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

@ExtendWith(MockitoExtension.class)
class WebConfigTest {

    @Mock
    private AuthenticationInterceptor authenticationInterceptor;

    @Mock
    private AuthorizationInterceptor authorizationInterceptor;

    private MappedInterceptor authenticationMapping;

    @BeforeEach
    void setUp() {
        ExposedInterceptorRegistry registry = new ExposedInterceptorRegistry();
        new WebConfig(authenticationInterceptor, authorizationInterceptor).addInterceptors(registry);

        authenticationMapping = registry.interceptors().stream()
                .map(MappedInterceptor.class::cast)
                .filter(mapped -> mapped.getInterceptor() == authenticationInterceptor)
                .findFirst()
                .orElseThrow();
        assertSame(authenticationInterceptor, authenticationMapping.getInterceptor());
    }

    @Test
    void aiEndpointsRequireAuthentication() {
        assertTrue(matches("/api/ai/config"));
        assertTrue(matches("/api/ai/chat/stream"));
        assertTrue(matches("/api/ai/knowledge/files/upload"));
    }

    @Test
    void explicitlyPublicAndServiceEndpointsRemainExcluded() {
        assertFalse(matches("/api/auth/login"));
        assertFalse(matches("/api/internal/datasource/config/1/resolved"));
        assertFalse(matches("/api/webhook/github/1"));
    }

    private boolean matches(String path) {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", path);
        ServletRequestPathUtils.parseAndCache(request);
        return authenticationMapping.matches(request);
    }

    private static final class ExposedInterceptorRegistry extends InterceptorRegistry {

        private List<Object> interceptors() {
            return getInterceptors();
        }
    }
}
