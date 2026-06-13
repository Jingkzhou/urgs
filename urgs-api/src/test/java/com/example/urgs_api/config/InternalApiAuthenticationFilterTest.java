package com.example.urgs_api.config;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

class InternalApiAuthenticationFilterTest {

    private static final String TOKEN = "test-internal-token";

    @Test
    void acceptsConfiguredCredential() throws Exception {
        InternalApiAuthenticationFilter filter = filter(TOKEN);
        MockHttpServletRequest request = request("/api/internal/datasource/config/1/resolved");
        request.addHeader("Authorization", "Bearer " + TOKEN);
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        verify(chain).doFilter(request, response);
    }

    @Test
    void rejectsMissingOrInvalidCredential() throws Exception {
        InternalApiAuthenticationFilter filter = filter(TOKEN);

        for (String credential : new String[] { null, "Bearer wrong-token" }) {
            MockHttpServletRequest request = request("/api/internal/datasource/config/1/resolved");
            if (credential != null) {
                request.addHeader("Authorization", credential);
            }
            MockHttpServletResponse response = new MockHttpServletResponse();
            FilterChain chain = mock(FilterChain.class);

            filter.doFilter(request, response, chain);

            assertEquals(401, response.getStatus());
            verify(chain, never()).doFilter(request, response);
        }
    }

    @Test
    void failsStartupWhenServerTokenIsMissing() {
        assertThrows(IllegalStateException.class, () -> filter(""));
    }

    @Test
    void protectsMatrixParameterVariant() throws Exception {
        InternalApiAuthenticationFilter filter = filter(TOKEN);
        MockHttpServletRequest request = request("/api/internal;route=datasource/config/1/resolved");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        assertEquals(401, response.getStatus());
        verify(chain, never()).doFilter(request, response);
    }

    @Test
    void protectsEncodedMatrixParameterVariant() throws Exception {
        InternalApiAuthenticationFilter filter = filter(TOKEN);
        MockHttpServletRequest request = request("/api/internal%3Broute=datasource/config/1/resolved");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        assertEquals(401, response.getStatus());
        verify(chain, never()).doFilter(request, response);
    }

    @Test
    void protectsEncodedInternalPathSegment() throws Exception {
        InternalApiAuthenticationFilter filter = filter(TOKEN);
        MockHttpServletRequest request = request("/api/%69nternal/datasource/config/1/resolved");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        assertEquals(401, response.getStatus());
        verify(chain, never()).doFilter(request, response);
    }

    @Test
    void protectsNormalizedTraversalPath() throws Exception {
        InternalApiAuthenticationFilter filter = filter(TOKEN);
        MockHttpServletRequest request = request("/public/../api/internal/datasource/config/1/resolved");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        assertEquals(401, response.getStatus());
        verify(chain, never()).doFilter(request, response);
    }

    @Test
    void protectsEncodedTraversalPath() throws Exception {
        InternalApiAuthenticationFilter filter = filter(TOKEN);
        MockHttpServletRequest request = request("/public/%2e%2e/api/internal/datasource/config/1/resolved");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        assertEquals(401, response.getStatus());
        verify(chain, never()).doFilter(request, response);
    }

    @Test
    void ignoresNonInternalApiPath() throws Exception {
        InternalApiAuthenticationFilter filter = filter(TOKEN);
        MockHttpServletRequest request = request("/api/datasource/config/1/resolved");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        verify(chain).doFilter(request, response);
    }

    private InternalApiAuthenticationFilter filter(String token) {
        return new InternalApiAuthenticationFilter("Authorization", "Bearer ", token);
    }

    private MockHttpServletRequest request(String path) {
        return new MockHttpServletRequest("GET", path);
    }
}
