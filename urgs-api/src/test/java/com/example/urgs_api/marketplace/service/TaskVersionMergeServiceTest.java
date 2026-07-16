package com.example.urgs_api.marketplace.service;

import com.example.urgs_api.marketplace.mapper.TaskVersionChangeSnapshotMapper;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.user.mapper.UserGitIdentityMapper;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.model.UserGitIdentity;
import com.example.urgs_api.version.entity.GitRepository;
import com.example.urgs_api.version.service.GitPlatformService;
import com.example.urgs_api.version.service.GitRepositoryService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TaskVersionMergeServiceTest {

    @Mock
    private GitRepositoryService gitRepositoryService;

    @Mock
    private GitPlatformService gitPlatformService;

    @Mock
    private UserGitIdentityMapper userGitIdentityMapper;

    @Mock
    private UserMapper userMapper;

    @Mock
    private TaskVersionChangeSnapshotMapper taskVersionChangeSnapshotMapper;

    private TaskVersionMergeService taskVersionMergeService;

    @BeforeEach
    void setUp() {
        taskVersionMergeService = new TaskVersionMergeService(
                gitRepositoryService,
                gitPlatformService,
                userGitIdentityMapper,
                userMapper,
                taskVersionChangeSnapshotMapper,
                new ObjectMapper());
    }

    @Test
    void mergeOpenMasterPullRequests_usesAllReviewerAccessibleRepos() {
        Work work = new Work();
        work.setRequirementNumber("REQ-20260708");

        WorkTask task = new WorkTask();
        task.setAssigneeId("88");
        task.setInvolvedSystemIds(List.of(200L));

        UserGitIdentity identity = new UserGitIdentity();
        identity.setGitEmail("developer@example.com");
        when(userGitIdentityMapper.selectOne(any())).thenReturn(identity);

        User reviewer = new User();
        reviewer.setId(77L);
        when(userMapper.selectById(any())).thenAnswer(invocation ->
                Long.valueOf(77L).equals(invocation.getArgument(0)) ? reviewer : null);

        GitRepository firstRepo = enabledRepo(10L, 100L, "team/first");
        GitRepository secondRepo = enabledRepo(20L, 200L, "team/second");
        GitRepository thirdRepo = enabledRepo(30L, 300L, "team/third");
        GitRepository fourthRepo = enabledRepo(40L, 400L, "team/fourth");

        when(gitRepositoryService.findAccessibleByUser(77L))
                .thenReturn(List.of(firstRepo, secondRepo, thirdRepo, fourthRepo));
        when(gitPlatformService.getPullRequests(any(), any(), any(), any())).thenReturn(List.of());

        taskVersionMergeService.mergeOpenMasterPullRequests(work, task, "77");

        verify(gitRepositoryService).findAccessibleByUser(77L);
        verify(gitPlatformService).getPullRequests(10L, "all", 1, 100);
        verify(gitPlatformService).getPullRequests(20L, "all", 1, 100);
        verify(gitPlatformService).getPullRequests(30L, "all", 1, 100);
        verify(gitPlatformService).getPullRequests(40L, "all", 1, 100);
    }

    @Test
    void mergeOpenMasterPullRequests_throwsWhenPullRequestListFails() {
        Work work = new Work();
        work.setRequirementNumber("REQ-20260708");

        WorkTask task = new WorkTask();
        task.setAssigneeId("88");
        task.setInvolvedSystemIds(List.of(200L));

        UserGitIdentity identity = new UserGitIdentity();
        identity.setGitEmail("developer@example.com");
        when(userGitIdentityMapper.selectOne(any())).thenReturn(identity);

        User reviewer = new User();
        reviewer.setId(77L);
        when(userMapper.selectById(any())).thenAnswer(invocation ->
                Long.valueOf(77L).equals(invocation.getArgument(0)) ? reviewer : null);

        GitRepository targetRepo = new GitRepository();
        targetRepo.setId(20L);
        targetRepo.setSsoId(200L);
        targetRepo.setEnabled(true);
        targetRepo.setFullName("team/repo");

        when(gitRepositoryService.findAccessibleByUser(77L)).thenReturn(List.of(targetRepo));
        when(gitPlatformService.getPullRequests(20L, "all", 1, 100))
                .thenThrow(new RuntimeException("获取 PR 列表失败: HTTP 401: {\"message\":\"401 Unauthorized\"}"));

        IllegalStateException exception = assertThrows(IllegalStateException.class,
                () -> taskVersionMergeService.mergeOpenMasterPullRequests(work, task, "77"));

        assertTrue(exception.getMessage().contains("自动合并读取 MR 失败"));
        assertTrue(exception.getMessage().contains("team/repo"));
    }

    private GitRepository enabledRepo(Long id, Long ssoId, String fullName) {
        GitRepository repo = new GitRepository();
        repo.setId(id);
        repo.setSsoId(ssoId);
        repo.setEnabled(true);
        repo.setFullName(fullName);
        return repo;
    }
}
