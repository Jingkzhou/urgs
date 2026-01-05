package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.GitPullRequest;
import com.example.urgs_api.version.entity.GitRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GitPlatformServiceTest {

    @Mock
    private GitRepositoryService gitRepositoryService;

    @Mock
    private HttpClient httpClient;

    @Mock
    private HttpResponse<String> httpResponse;

    private GitPlatformService gitPlatformService;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        gitPlatformService = new GitPlatformService(gitRepositoryService, objectMapper);
        gitPlatformService.setHttpClient(httpClient);
    }

    @Test
    void getPullRequests_Gitee() throws Exception {
        Long repoId = 1L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitee");
        repo.setCloneUrl("https://gitee.com/owner/repo.git");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        String jsonResponse = "[{\"id\": 100, \"number\": 1, \"title\": \"Test PR\", \"state\": \"open\", \"html_url\": \"url\", \"user\": {\"name\": \"author\"}, \"created_at\": \"2023-01-01T00:00:00Z\", \"updated_at\": \"2023-01-01T00:00:00Z\", \"head\": {\"ref\": \"feature\", \"sha\": \"sha1\"}, \"base\": {\"ref\": \"master\", \"sha\": \"sha2\"}}]";
        when(httpResponse.body()).thenReturn(jsonResponse);

        List<GitPullRequest> prs = gitPlatformService.getPullRequests(repoId, "open", 1, 10);

        assertNotNull(prs);
        assertEquals(1, prs.size());
        assertEquals("Test PR", prs.get(0).getTitle());
        assertEquals("open", prs.get(0).getState());
        assertEquals("gitee", repo.getPlatform());
    }

    @Test
    void getPullRequests_GitHub() throws Exception {
        Long repoId = 2L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("github");
        repo.setCloneUrl("https://github.com/owner/repo.git");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        String jsonResponse = "[{\"id\": 200, \"number\": 2, \"title\": \"GitHub PR\", \"state\": \"open\", \"html_url\": \"url\", \"user\": {\"login\": \"author\"}, \"created_at\": \"2023-01-01T00:00:00Z\", \"updated_at\": \"2023-01-01T00:00:00Z\", \"head\": {\"ref\": \"feature\", \"sha\": \"sha1\"}, \"base\": {\"ref\": \"main\", \"sha\": \"sha2\"}}]";
        when(httpResponse.body()).thenReturn(jsonResponse);

        List<GitPullRequest> prs = gitPlatformService.getPullRequests(repoId, "open", 1, 10);

        assertNotNull(prs);
        assertEquals("GitHub PR", prs.get(0).getTitle());
        assertEquals("author", prs.get(0).getAuthorName());
    }

    @Test
    void getPullRequests_GitLab() throws Exception {
        Long repoId = 3L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitlab");
        repo.setCloneUrl("https://gitlab.example.com/owner/repo.git");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        String jsonResponse = "[{\"id\": 300, \"iid\": 3, \"title\": \"GitLab PR\", \"state\": \"opened\", \"web_url\": \"url\", \"author\": {\"name\": \"author\"}, \"created_at\": \"2023-01-01T00:00:00Z\", \"updated_at\": \"2023-01-01T00:00:00Z\", \"source_branch\": \"feature\", \"target_branch\": \"main\", \"sha\": \"sha1\", \"merge_commit_sha\": \"sha2\"}]";
        when(httpResponse.body()).thenReturn(jsonResponse);

        List<GitPullRequest> prs = gitPlatformService.getPullRequests(repoId, "open", 1, 10);

        assertNotNull(prs);
        assertEquals("GitLab PR", prs.get(0).getTitle());
        assertEquals(3, prs.get(0).getNumber()); // Use iid for number
    }
}
