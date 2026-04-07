package com.example.executor.quartz.service.task;

import com.example.executor.quartz.domain.entity.QuartzTaskEntity;

import java.util.Map;
import java.util.function.Consumer;

/**
 * 任务执行器接口。
 * <p>
 * 每次任务执行都会创建一个新的实例，由 ExecutorTaskService 统一驱动生命周期。
 * 实现类需保证 cancel() 可从任意线程安全调用。
 */
public interface TaskExecutor {

    /**
     * 执行任务，阻塞直到完成或被取消。
     *
     * @return 包含 "code"（"0"=成功，否则失败）和 "msg" 的结果 Map
     */
    Map<String, String> execute(QuartzTaskEntity task, String dataDate, Consumer<String> logConsumer) throws Exception;

    /**
     * 终止正在执行的任务，可从任意线程调用，调用后 execute() 应尽快返回。
     */
    void cancel();
}
