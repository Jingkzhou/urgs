package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.GitPullRequest;
import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.PullRequestMergeResult;
import com.example.urgs_api.version.dto.GitFileDownload;
import com.example.urgs_api.version.dto.GitFileEntry;
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
import org.mockito.ArgumentCaptor;

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
    void saveFile_GitLabCreatesCommitOnSelectedBranch() throws Exception {
        Long repoId = 10L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitlab");
        repo.setFullName("owner/repo");
        repo.setCloneUrl("https://gitlab.example.com/owner/repo.git");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(201);

        gitPlatformService.saveFile(repoId, "feature/upload", "docs/readme.md", "aGVsbG8=", "上传说明", null,
                false);

        ArgumentCaptor<HttpRequest> requestCaptor = ArgumentCaptor.forClass(HttpRequest.class);
        verify(httpClient).send(requestCaptor.capture(), any(HttpResponse.BodyHandler.class));
        HttpRequest request = requestCaptor.getValue();
        assertEquals("POST", request.method());
        assertTrue(request.uri().toString().contains("/repository/files/docs%2Freadme.md"));
        assertEquals("token", request.headers().firstValue("PRIVATE-TOKEN").orElse(null));
    }

    @Test
    void downloadFile_GitLabReturnsOriginalBytes() throws Exception {
        Long repoId = 11L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitlab");
        repo.setFullName("owner/repo");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        when(httpResponse.body()).thenReturn("{\"file_name\":\"binary.dat\",\"content\":\"AAECAw==\"}");

        GitFileDownload file = gitPlatformService.downloadFile(repoId, "main", "docs/binary.dat");

        assertEquals("binary.dat", file.getName());
        assertArrayEquals(new byte[] { 0, 1, 2, 3 }, file.getContent());
    }

    @Test
    void getFileTree_GitLabDoesNotFetchEachBlobSize() throws Exception {
        Long repoId = 12L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitlab");
        repo.setFullName("owner/repo");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        when(httpResponse.body())
                .thenReturn("[{\"name\":\"README.md\",\"path\":\"README.md\",\"type\":\"blob\",\"id\":\"blob-sha\"}]");

        List<GitFileEntry> files = gitPlatformService.getFileTree(repoId, "main", "");

        assertEquals(1, files.size());
        assertNull(files.get(0).getSize());
        verify(httpClient, times(1)).send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class));
    }

    @Test
    void getLatestCommit_GitLabFiltersByFilePath() throws Exception {
        Long repoId = 13L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitlab");
        repo.setFullName("owner/repo");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        when(httpResponse.body()).thenReturn("[{\"short_id\":\"abc1234\",\"id\":\"abc123456789\",\"message\":\"更新 App\",\"author_name\":\"开发者\",\"committed_date\":\"2026-07-17T00:00:00Z\"}]");

        GitCommit commit = gitPlatformService.getLatestCommit(repoId, "main", "src/App.java");

        ArgumentCaptor<HttpRequest> requestCaptor = ArgumentCaptor.forClass(HttpRequest.class);
        verify(httpClient).send(requestCaptor.capture(), any(HttpResponse.BodyHandler.class));
        assertTrue(requestCaptor.getValue().uri().toString().contains("path=src%2FApp.java"));
        assertEquals("更新 App", commit.getMessage());
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

    @Test
    void getPullRequestCommits_GitHub() throws Exception {
        Long repoId = 2L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("github");
        repo.setFullName("owner/repo");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        String jsonResponse = "[{\"sha\": \"shasha123\", \"commit\": {\"message\": \"test commit\", \"author\": {\"name\": \"dev\", \"email\": \"dev@example.com\", \"date\": \"2023-01-01T00:00:00Z\"}}, \"author\": {\"avatar_url\": \"avatar_url\"}}]";
        when(httpResponse.body()).thenReturn(jsonResponse);

        List<com.example.urgs_api.version.dto.GitCommit> commits = gitPlatformService.getPullRequestCommits(repoId, 1L);

        assertNotNull(commits);
        assertEquals(1, commits.size());
        assertEquals("shasha1", commits.get(0).getSha());
        assertEquals("test commit", commits.get(0).getMessage());
        assertEquals("dev", commits.get(0).getAuthorName());
    }

    @Test
    void getPullRequestCommits_GitLab() throws Exception {
        Long repoId = 3L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitlab");
        repo.setCloneUrl("https://gitlab.example.com/owner/repo.git");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        String jsonResponse = "[{\"id\": \"shasha123\", \"short_id\": \"shasha1\", \"message\": \"test commit\", \"author_name\": \"dev\", \"author_email\": \"dev@example.com\", \"committed_date\": \"2023-01-01T00:00:00Z\"}]";
        when(httpResponse.body()).thenReturn(jsonResponse);

        List<com.example.urgs_api.version.dto.GitCommit> commits = gitPlatformService.getPullRequestCommits(repoId, 1L);

        assertNotNull(commits);
        assertEquals(1, commits.size());
        assertEquals("shasha1", commits.get(0).getSha());
        assertEquals("test commit", commits.get(0).getMessage());
        assertEquals("dev", commits.get(0).getAuthorName());
    }

    @Test
    void getPullRequestFiles_GitHub() throws Exception {
        Long repoId = 2L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("github");
        repo.setFullName("owner/repo");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        String jsonResponse = "[{\"filename\": \"test.txt\", \"status\": \"added\", \"additions\": 10, \"deletions\": 0, \"patch\": \"+content\"}]";
        when(httpResponse.body()).thenReturn(jsonResponse);

        List<com.example.urgs_api.version.dto.GitCommitDiff> files = gitPlatformService.getPullRequestFiles(repoId, 1L);

        assertNotNull(files);
        assertEquals(1, files.size());
        assertEquals("test.txt", files.get(0).getNewPath());
        assertEquals("added", files.get(0).getStatus());
        assertEquals(10, files.get(0).getAdditions());
    }

    @Test
    void getPullRequestFiles_GitLab() throws Exception {
        Long repoId = 3L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitlab");
        repo.setCloneUrl("https://gitlab.example.com/owner/repo.git");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        String jsonResponse = "{\"changes\": [{\"new_path\": \"test.txt\", \"old_path\": \"test.txt\", \"new_file\": true, \"renamed_file\": false, \"deleted_file\": false, \"diff\": \"+content\"}]}";
        when(httpResponse.body()).thenReturn(jsonResponse);

        List<com.example.urgs_api.version.dto.GitCommitDiff> files = gitPlatformService.getPullRequestFiles(repoId, 1L);

        assertNotNull(files);
        assertEquals(1, files.size());
        assertEquals("test.txt", files.get(0).getNewPath());
        assertEquals("+content", files.get(0).getDiff());
    }

    @Test
    void mergePullRequest_MissingPersonalToken_ShowsClearError() {
        Long repoId = 4L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitlab");
        repo.setResolvedAccessToken(null);

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));

        RuntimeException error = assertThrows(RuntimeException.class,
                () -> gitPlatformService.mergePullRequest(repoId, 1L, "merge"));

        assertTrue(error.getMessage().contains("请先在个人信息中配置 gitlab 访问令牌"));
        verifyNoInteractions(httpClient);
    }

    @Test
    void mergePullRequest_GitHubExplicitlyRejected_ThrowsPlatformMessage() throws Exception {
        Long repoId = 5L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("github");
        repo.setFullName("owner/repo");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        when(httpResponse.body()).thenReturn("{\"merged\":false,\"message\":\"Base branch was modified\"}");

        RuntimeException error = assertThrows(RuntimeException.class,
                () -> gitPlatformService.mergePullRequest(repoId, 2L, "merge"));

        assertEquals("合并 PR 失败: Base branch was modified", error.getMessage());
    }

    @Test
    void mergePullRequest_GitLabMerged_Succeeds() throws Exception {
        Long repoId = 6L;
        GitRepository repo = new GitRepository();
        repo.setId(repoId);
        repo.setPlatform("gitlab");
        repo.setCloneUrl("https://gitlab.example.com/owner/repo.git");
        repo.setAccessToken("token");

        when(gitRepositoryService.findById(repoId)).thenReturn(Optional.of(repo));
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(httpResponse);
        when(httpResponse.statusCode()).thenReturn(200);
        when(httpResponse.body()).thenReturn("{\"state\":\"merged\"}");

        PullRequestMergeResult result = assertDoesNotThrow(
                () -> gitPlatformService.mergePullRequest(repoId, 3L, "merge"));

        assertTrue(result.isSourceBranchDeleteRequested());
        assertTrue(result.isSourceBranchDeleted());
    }
}
