package com.example.executor.urgs_executor.util;

import lombok.extern.slf4j.Slf4j;

import java.io.BufferedReader;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.function.Consumer;
import java.util.function.Supplier;

/**
 * 非阻塞日志流读取工具。
 * 解决 BufferedReader.readLine() 在进程无输出时阻塞导致已有日志无法刷新到数据库的问题。
 */
@Slf4j
public class LogStreamReader {

    private static final DateTimeFormatter TS_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final long FLUSH_INTERVAL_MS = 1000;
    private static final long POLL_SLEEP_MS = 200;

    /**
     * 非阻塞读取进程输出流，定时刷新日志到数据库。
     *
     * @param reader        标准输出流
     * @param errReader     标准错误流（可为 null）
     * @param isFinished    判断执行是否结束的回调（SSH: channel::isClosed, 本地进程: () -> !process.isAlive()）
     * @param logBuilder    日志缓冲区
     * @param logPrefix     日志行前缀（如 "Shell-12345-Remote"）
     * @param flushCallback 刷新回调，接收当前完整日志内容写入数据库
     */
    public static void readAndFlush(
            BufferedReader reader,
            BufferedReader errReader,
            Supplier<Boolean> isFinished,
            StringBuilder logBuilder,
            String logPrefix,
            Consumer<String> flushCallback) throws IOException, InterruptedException {

        long lastFlush = System.currentTimeMillis();
        int previousLength = logBuilder.length();

        while (true) {
            boolean readAny = false;

            // 非阻塞读取 stdout
            readAny |= drainReader(reader, logBuilder, logPrefix, false);

            // 非阻塞读取 stderr
            if (errReader != null) {
                readAny |= drainReader(errReader, logBuilder, logPrefix, true);
            }

            // 定时刷新：距上次刷新超过 1 秒且有新内容
            long now = System.currentTimeMillis();
            if (now - lastFlush > FLUSH_INTERVAL_MS && logBuilder.length() > previousLength) {
                flushCallback.accept(logBuilder.toString());
                lastFlush = now;
                previousLength = logBuilder.length();
            }

            // 进程已结束且无更多数据可读
            if (isFinished.get() && !hasData(reader) && (errReader == null || !hasData(errReader))) {
                // 最后再读一次，确保不遗漏
                drainReader(reader, logBuilder, logPrefix, false);
                if (errReader != null) {
                    drainReader(errReader, logBuilder, logPrefix, true);
                }
                break;
            }

            if (!readAny) {
                // 无新数据但进程仍在运行，也要定时刷新已有日志
                if (now - lastFlush > FLUSH_INTERVAL_MS && logBuilder.length() > 0 && previousLength < logBuilder.length()) {
                    flushCallback.accept(logBuilder.toString());
                    lastFlush = now;
                    previousLength = logBuilder.length();
                }
                Thread.sleep(POLL_SLEEP_MS);
            }
        }

        // 最终刷新，确保所有日志写入数据库
        flushCallback.accept(logBuilder.toString());
    }

    /**
     * 非阻塞读取流中所有可用行
     */
    private static boolean drainReader(BufferedReader reader, StringBuilder logBuilder, String logPrefix, boolean isErr) throws IOException {
        boolean readAny = false;
        while (reader.ready()) {
            String line = reader.readLine();
            if (line == null) break;
            readAny = true;

            if (isErr) {
                log.error("[{}-Err] {}", logPrefix, line);
            } else {
                log.info("[{}] {}", logPrefix, line);
            }

            String ts = LocalDateTime.now().format(TS_FMT);
            if (isErr) {
                logBuilder.append("[").append(ts).append("] ERR: ").append(line).append("\n");
            } else {
                logBuilder.append("[").append(ts).append("] ").append(line).append("\n");
            }
        }
        return readAny;
    }

    private static boolean hasData(BufferedReader reader) {
        try {
            return reader.ready();
        } catch (IOException e) {
            return false;
        }
    }
}
