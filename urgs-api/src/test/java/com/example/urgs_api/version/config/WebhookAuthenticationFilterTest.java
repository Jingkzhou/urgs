package com.example.urgs_api.version.config;

import com.example.urgs_api.version.service.WebhookAuthenticationService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class WebhookAuthenticationFilterTest {

    private static final int MAX_PAYLOAD_BYTES = 64;

    @Mock
    private WebhookAuthenticationService authenticationService;

    @Mock
    private FilterChain filterChain;

    private WebhookAuthenticationFilter filter;

    @BeforeEach
    void setUp() {
        filter = new WebhookAuthenticationFilter(authenticationService, MAX_PAYLOAD_BYTES);
    }

    @Test
    void rejectsInvalidTokenBeforeReadingPayload() throws Exception {
        MockHttpServletRequest request = request("/api/webhook/gitee/1", "payload");
        request.addHeader("X-Gitee-Token", "invalid");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(authenticationService.verifyToken(1L, "gitee", "invalid")).thenReturn(false);

        filter.doFilter(request, response, filterChain);

        assertEquals(401, response.getStatus());
        verify(filterChain, never()).doFilter(request, response);
    }

    @Test
    void rejectsChunkedPayloadAboveConfiguredLimit() throws Exception {
        MockHttpServletRequest request = chunkedRequest(
                "/api/webhook/gitlab/1", "x".repeat(MAX_PAYLOAD_BYTES + 1));
        request.addHeader("X-Gitlab-Token", "valid");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(authenticationService.verifyToken(1L, "gitlab", "valid")).thenReturn(true);

        filter.doFilter(request, response, filterChain);

        assertEquals(413, response.getStatus());
        verify(filterChain, never()).doFilter(request, response);
    }

    @Test
    void verifiesGitHubSignatureAndReplaysBoundedPayload() throws Exception {
        byte[] payload = "{\"after\":\"commit-sha\"}".getBytes(StandardCharsets.UTF_8);
        MockHttpServletRequest request = request("/api/webhook/github/1", new String(payload, StandardCharsets.UTF_8));
        request.addHeader("X-Hub-Signature-256", "sha256=valid");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(authenticationService.verifyGitHubSignature(1L, "sha256=valid", payload)).thenReturn(true);

        filter.doFilter(request, response, filterChain);

        ArgumentCaptor<ServletRequest> requestCaptor = ArgumentCaptor.forClass(ServletRequest.class);
        verify(filterChain).doFilter(requestCaptor.capture(), org.mockito.ArgumentMatchers.eq(response));
        assertArrayEquals(payload, requestCaptor.getValue().getInputStream().readAllBytes());
    }

    @Test
    void rejectsInvalidGitHubSignatureBeforeController() throws Exception {
        byte[] payload = "{\"after\":\"commit-sha\"}".getBytes(StandardCharsets.UTF_8);
        MockHttpServletRequest request = request("/api/webhook/github/1", new String(payload, StandardCharsets.UTF_8));
        request.addHeader("X-Hub-Signature-256", "sha256=invalid");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(authenticationService.verifyGitHubSignature(1L, "sha256=invalid", payload)).thenReturn(false);

        filter.doFilter(request, response, filterChain);

        assertEquals(401, response.getStatus());
        verify(filterChain, never()).doFilter(request, response);
    }

    @Test
    void rejectsNonCanonicalWebhookPathBeforeMvcCanNormalizeIt() throws Exception {
        MockHttpServletRequest request = request("/api/webhook;foo/gitee/1", "payload");
        request.addHeader("X-Gitee-Token", "valid");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, filterChain);

        assertEquals(400, response.getStatus());
        verify(filterChain, never()).doFilter(request, response);
        verify(authenticationService, never()).verifyToken(1L, "gitee", "valid");
    }

    private MockHttpServletRequest request(String path, String payload) {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", path);
        request.setContent(payload.getBytes(StandardCharsets.UTF_8));
        request.setContentType("application/json");
        return request;
    }

    private MockHttpServletRequest chunkedRequest(String path, String payload) {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", path) {
            @Override
            public int getContentLength() {
                return -1;
            }

            @Override
            public long getContentLengthLong() {
                return -1;
            }
        };
        request.setContent(payload.getBytes(StandardCharsets.UTF_8));
        request.setContentType("application/json");
        return request;
    }
}
