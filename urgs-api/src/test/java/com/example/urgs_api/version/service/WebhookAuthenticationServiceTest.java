package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.GitRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class WebhookAuthenticationServiceTest {

    private static final Long REPO_ID = 1L;
    private static final String SECRET = "test-webhook-secret";

    @Mock
    private GitRepositoryService gitRepositoryService;

    private WebhookAuthenticationService service;

    @BeforeEach
    void setUp() {
        service = new WebhookAuthenticationService(gitRepositoryService);
    }

    @Test
    void verifyTokenAcceptsMatchingActiveRepository() {
        when(gitRepositoryService.findById(REPO_ID)).thenReturn(Optional.of(repository("gitee", true)));

        assertTrue(service.verifyToken(REPO_ID, "gitee", SECRET));
        assertFalse(service.verifyToken(REPO_ID, "gitee", "wrong-secret"));
    }

    @Test
    void verifyTokenRejectsDisabledOrMismatchedRepository() {
        when(gitRepositoryService.findById(REPO_ID))
                .thenReturn(Optional.of(repository("gitlab", false)))
                .thenReturn(Optional.of(repository("gitlab", true)));

        assertFalse(service.verifyToken(REPO_ID, "gitlab", SECRET));
        assertFalse(service.verifyToken(REPO_ID, "gitee", SECRET));
    }

    @Test
    void verifyGitHubSignatureUsesRawPayloadHmac() throws Exception {
        byte[] payload = "{\"ref\":\"refs/heads/main\"}".getBytes(StandardCharsets.UTF_8);
        when(gitRepositoryService.findById(REPO_ID)).thenReturn(Optional.of(repository("github", true)));

        String signature = sign(payload);

        assertTrue(service.verifyGitHubSignature(REPO_ID, signature, payload));
        assertFalse(service.verifyGitHubSignature(REPO_ID, signature,
                "{\"ref\":\"refs/heads/other\"}".getBytes(StandardCharsets.UTF_8)));
    }

    private GitRepository repository(String platform, boolean enabled) {
        GitRepository repository = new GitRepository();
        repository.setId(REPO_ID);
        repository.setPlatform(platform);
        repository.setEnabled(enabled);
        repository.setWebhookSecret(SECRET);
        return repository;
    }

    private String sign(byte[] payload) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        return "sha256=" + HexFormat.of().formatHex(mac.doFinal(payload));
    }
}
