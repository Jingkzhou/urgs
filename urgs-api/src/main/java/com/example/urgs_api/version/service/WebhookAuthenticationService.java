package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.GitRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.HexFormat;

@Service
@RequiredArgsConstructor
public class WebhookAuthenticationService {

    private static final String GITHUB_SIGNATURE_PREFIX = "sha256=";
    private static final String HMAC_SHA_256 = "HmacSHA256";

    private final GitRepositoryService gitRepositoryService;

    public boolean verifyToken(Long repoId, String platform, String token) {
        GitRepository repository = findActiveRepository(repoId, platform);
        if (repository == null || !StringUtils.hasText(token)) {
            return false;
        }
        return constantTimeEquals(repository.getWebhookSecret(), token);
    }

    public boolean verifyGitHubSignature(Long repoId, String signature, byte[] payload) {
        GitRepository repository = findActiveRepository(repoId, "github");
        if (repository == null || !StringUtils.hasText(signature)
                || !signature.startsWith(GITHUB_SIGNATURE_PREFIX) || payload == null) {
            return false;
        }

        try {
            Mac mac = Mac.getInstance(HMAC_SHA_256);
            mac.init(new SecretKeySpec(repository.getWebhookSecret().getBytes(StandardCharsets.UTF_8), HMAC_SHA_256));
            String expected = GITHUB_SIGNATURE_PREFIX + HexFormat.of().formatHex(mac.doFinal(payload));
            return constantTimeEquals(expected, signature);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("无法校验 GitHub Webhook 签名", e);
        }
    }

    private GitRepository findActiveRepository(Long repoId, String platform) {
        if (repoId == null || !StringUtils.hasText(platform)) {
            return null;
        }
        return gitRepositoryService.findById(repoId)
                .filter(repository -> Boolean.TRUE.equals(repository.getEnabled()))
                .filter(repository -> platform.equalsIgnoreCase(repository.getPlatform()))
                .filter(repository -> StringUtils.hasText(repository.getWebhookSecret()))
                .orElse(null);
    }

    private boolean constantTimeEquals(String expected, String actual) {
        if (expected == null || actual == null) {
            return false;
        }
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                actual.getBytes(StandardCharsets.UTF_8));
    }
}
