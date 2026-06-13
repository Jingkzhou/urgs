package com.example.urgs_api.version.config;

import com.example.urgs_api.version.service.WebhookAuthenticationService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class WebhookAuthenticationFilter extends OncePerRequestFilter {

    private static final String WEBHOOK_ROOT = "/api/webhook";
    private static final Pattern WEBHOOK_PATH = Pattern.compile("^/api/webhook/(gitee|gitlab|github)/(\\d+)$");

    private final WebhookAuthenticationService authenticationService;
    private final int maxPayloadBytes;

    public WebhookAuthenticationFilter(
            WebhookAuthenticationService authenticationService,
            @Value("${urgs.webhook.max-payload-bytes:1048576}") int maxPayloadBytes) {
        if (maxPayloadBytes <= 0) {
            throw new IllegalArgumentException("urgs.webhook.max-payload-bytes 必须大于 0");
        }
        this.authenticationService = authenticationService;
        this.maxPayloadBytes = maxPayloadBytes;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String path = pathWithinApplication(request);
        if (!"POST".equalsIgnoreCase(request.getMethod()) || !isWebhookPath(path)) {
            filterChain.doFilter(request, response);
            return;
        }

        Matcher matcher = WEBHOOK_PATH.matcher(path);
        if (!matcher.matches()) {
            response.setStatus(HttpStatus.BAD_REQUEST.value());
            return;
        }

        String platform = matcher.group(1);
        Long repoId;
        try {
            repoId = Long.valueOf(matcher.group(2));
        } catch (NumberFormatException e) {
            response.setStatus(HttpStatus.BAD_REQUEST.value());
            return;
        }
        if (!"github".equals(platform) && !verifyToken(request, repoId, platform)) {
            response.setStatus(HttpStatus.UNAUTHORIZED.value());
            return;
        }

        if (request.getContentLengthLong() > maxPayloadBytes) {
            response.setStatus(HttpStatus.PAYLOAD_TOO_LARGE.value());
            return;
        }

        byte[] payload = request.getInputStream().readNBytes(maxPayloadBytes + 1);
        if (payload.length > maxPayloadBytes) {
            response.setStatus(HttpStatus.PAYLOAD_TOO_LARGE.value());
            return;
        }

        if ("github".equals(platform)
                && !authenticationService.verifyGitHubSignature(
                        repoId, request.getHeader("X-Hub-Signature-256"), payload)) {
            response.setStatus(HttpStatus.UNAUTHORIZED.value());
            return;
        }

        filterChain.doFilter(new CachedBodyRequest(request, payload), response);
    }

    private boolean verifyToken(HttpServletRequest request, Long repoId, String platform) {
        String headerName = "gitee".equals(platform) ? "X-Gitee-Token" : "X-Gitlab-Token";
        return authenticationService.verifyToken(repoId, platform, request.getHeader(headerName));
    }

    private boolean isWebhookPath(String path) {
        return WEBHOOK_ROOT.equals(path)
                || path.startsWith(WEBHOOK_ROOT + "/")
                || path.startsWith(WEBHOOK_ROOT + ";");
    }

    private String pathWithinApplication(HttpServletRequest request) {
        String requestUri = request.getRequestURI();
        String contextPath = request.getContextPath();
        return contextPath.isEmpty() ? requestUri : requestUri.substring(contextPath.length());
    }

    private static final class CachedBodyRequest extends HttpServletRequestWrapper {

        private final byte[] body;

        private CachedBodyRequest(HttpServletRequest request, byte[] body) {
            super(request);
            this.body = body;
        }

        @Override
        public ServletInputStream getInputStream() {
            ByteArrayInputStream input = new ByteArrayInputStream(body);
            return new ServletInputStream() {
                @Override
                public boolean isFinished() {
                    return input.available() == 0;
                }

                @Override
                public boolean isReady() {
                    return true;
                }

                @Override
                public void setReadListener(ReadListener readListener) {
                    throw new UnsupportedOperationException("异步读取 Webhook 请求体不受支持");
                }

                @Override
                public int read() {
                    return input.read();
                }
            };
        }

        @Override
        public BufferedReader getReader() {
            return new BufferedReader(new InputStreamReader(getInputStream(), StandardCharsets.UTF_8));
        }

        @Override
        public int getContentLength() {
            return body.length;
        }

        @Override
        public long getContentLengthLong() {
            return body.length;
        }
    }
}
