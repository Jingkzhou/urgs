package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.Pipeline;
import com.example.urgs_api.version.entity.PipelineRun;
import com.example.urgs_api.version.repository.PipelineRepository;
import com.example.urgs_api.version.repository.PipelineRunRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class PipelineService {

    private final PipelineRepository pipelineRepository;
    private final PipelineRunRepository pipelineRunRepository;

    // ========== Pipeline CRUD ==========

    public List<Pipeline> findAll() {
        return pipelineRepository.findAll();
    }

    public Optional<Pipeline> findById(Long id) {
        return pipelineRepository.findById(id);
    }

    public List<Pipeline> findBySsoId(Long ssoId) {
        return pipelineRepository.findBySsoId(ssoId);
    }

    public List<Pipeline> findByRepoId(Long repoId) {
        return pipelineRepository.findByRepoId(repoId);
    }

    @Transactional
    public Pipeline create(Pipeline pipeline) {
        return pipelineRepository.save(pipeline);
    }

    @Transactional
    public Pipeline update(Long id, Pipeline pipeline) {
        Pipeline existing = pipelineRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("流水线不存在: " + id));

        existing.setName(pipeline.getName());
        existing.setSsoId(pipeline.getSsoId());
        existing.setRepoId(pipeline.getRepoId());
        existing.setStages(pipeline.getStages());
        existing.setTriggerType(pipeline.getTriggerType());
        existing.setEnabled(pipeline.getEnabled());

        return pipelineRepository.save(existing);
    }

    @Transactional
    public void delete(Long id) {
        pipelineRepository.deleteById(id);
    }

    // ========== Pipeline Run ==========

    public List<PipelineRun> findRunsByPipelineId(Long pipelineId) {
        return pipelineRunRepository.findByPipelineIdOrderByRunNumberDesc(pipelineId);
    }

    public Optional<PipelineRun> findRunById(Long id) {
        return pipelineRunRepository.findById(id);
    }

    /**
     * 触发流水线执行
     */
    @Transactional
    public PipelineRun trigger(Long pipelineId, String branch, String triggerType) {
        Pipeline pipeline = pipelineRepository.findById(pipelineId)
                .orElseThrow(() -> new IllegalArgumentException("流水线不存在: " + pipelineId));

        if (!Boolean.TRUE.equals(pipeline.getEnabled())) {
            throw new IllegalStateException("流水线已禁用: " + pipeline.getName());
        }

        // 获取下一个执行编号
        int nextRunNumber = pipelineRunRepository.findTopByPipelineIdOrderByRunNumberDesc(pipelineId)
                .map(r -> r.getRunNumber() + 1)
                .orElse(1);

        PipelineRun run = new PipelineRun();
        run.setPipelineId(pipelineId);
        run.setRunNumber(nextRunNumber);
        run.setBranch(branch != null ? branch : "master");
        run.setTriggerType(triggerType != null ? triggerType : "manual");
        run.setStatus(PipelineRun.STATUS_PENDING);

        PipelineRun savedRun = pipelineRunRepository.save(run);

        // 异步执行流水线
        executeAsync(savedRun.getId(), pipeline);

        return savedRun;
    }

    /**
     * 异步执行流水线
     */
    @Async
    public void executeAsync(Long runId, Pipeline pipeline) {
        try {
            // 更新状态为运行中
            PipelineRun run = pipelineRunRepository.findById(runId).orElse(null);
            if (run == null)
                return;

            run.setStatus(PipelineRun.STATUS_RUNNING);
            run.setStartedAt(LocalDateTime.now());
            pipelineRunRepository.save(run);

            StringBuilder logs = new StringBuilder();
            logs.append("[").append(LocalDateTime.now()).append("] 流水线开始执行\n");
            logs.append("[").append(LocalDateTime.now()).append("] 流水线: ").append(pipeline.getName()).append("\n");
            logs.append("[").append(LocalDateTime.now()).append("] 分支: ").append(run.getBranch()).append("\n");

            // TODO: 实际执行流水线阶段
            // 这里可以解析 pipeline.getStages() 并执行每个阶段
            logs.append("[").append(LocalDateTime.now()).append("] 执行阶段...\n");

            // 模拟执行
            Thread.sleep(2000);

            logs.append("[").append(LocalDateTime.now()).append("] 流水线执行完成\n");

            // 更新状态为成功
            run.setStatus(PipelineRun.STATUS_SUCCESS);
            run.setFinishedAt(LocalDateTime.now());
            run.setLogs(logs.toString());
            pipelineRunRepository.save(run);

            log.info("Pipeline run {} completed successfully", runId);

        } catch (Exception e) {
            log.error("Pipeline run {} failed", runId, e);
            pipelineRunRepository.findById(runId).ifPresent(run -> {
                run.setStatus(PipelineRun.STATUS_FAILED);
                run.setFinishedAt(LocalDateTime.now());
                run.setLogs(run.getLogs() + "\n[ERROR] " + e.getMessage());
                pipelineRunRepository.save(run);
            });
        }
    }

    /**
     * 取消执行
     */
    @Transactional
    public void cancelRun(Long runId) {
        PipelineRun run = pipelineRunRepository.findById(runId)
                .orElseThrow(() -> new IllegalArgumentException("执行记录不存在: " + runId));

        if (PipelineRun.STATUS_RUNNING.equals(run.getStatus()) ||
                PipelineRun.STATUS_PENDING.equals(run.getStatus())) {
            run.setStatus(PipelineRun.STATUS_CANCELLED);
            run.setFinishedAt(LocalDateTime.now());
            pipelineRunRepository.save(run);
        }
    }
}
