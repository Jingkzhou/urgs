package com.example.urgs_api.metadata.service;

import com.example.urgs_api.metadata.dto.StartEngineRequest;
import com.example.urgs_api.version.service.GitPlatformService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Slf4j
@Component
@RequiredArgsConstructor
public class LineageGitInputPreparer {

    private final GitPlatformService gitPlatformService;

    public LineageEngineInputPreparationResult prepare(StartEngineRequest request) throws Exception {
        Path baseDir = resolveSharedBaseDir();
        Path tempDir = Files.createTempDirectory(baseDir, "lineage-git-");
        try {
            Files.setPosixFilePermissions(tempDir,
                    java.nio.file.attribute.PosixFilePermissions.fromString("rwxrwxrwx"));
        } catch (Exception e) {
            log.warn("Failed to set perms on temp dir (might be non-posix fs): {}", e.getMessage());
        }
        log.info("下载代码归档到临时目录: {}", tempDir);

        try (InputStream is = gitPlatformService.downloadArchive(request.getRepoId(), request.getRef());
                ZipInputStream zis = new ZipInputStream(is)) {

            ZipEntry entry;
            int totalEntries = 0;
            while ((entry = zis.getNextEntry()) != null) {
                totalEntries++;
                if (log.isDebugEnabled()) {
                    log.debug("Git Archive Entry: {}", entry.getName());
                }

                Path outPath = tempDir.resolve(entry.getName());
                if (entry.isDirectory()) {
                    Files.createDirectories(outPath);
                } else {
                    Files.createDirectories(outPath.getParent());
                    Files.copy(zis, outPath, StandardCopyOption.REPLACE_EXISTING);
                }
                zis.closeEntry();
            }
            log.info("Extracted {} entries from Git archive.", totalEntries);
            if (totalEntries > 0) {
                logDirectoryContents(tempDir);
            }

            Path detectedRoot = tempDir;
            try (java.util.stream.Stream<Path> stream = Files.list(tempDir)) {
                List<Path> topLevel = stream
                        .filter(p -> !p.getFileName().toString().startsWith("."))
                        .filter(p -> !p.getFileName().toString().equals("__MACOSX"))
                        .collect(java.util.stream.Collectors.toList());

                if (topLevel.size() == 1 && Files.isDirectory(topLevel.get(0))) {
                    detectedRoot = topLevel.get(0);
                    log.info("Detected single root directory: {}", detectedRoot.getFileName());
                }
            }
            Path realBase = detectedRoot;

            if (request.getPaths() != null && !request.getPaths().isEmpty()) {
                if (request.getPaths().size() == 1) {
                    Path singlePath = realBase.resolve(request.getPaths().get(0));
                    if (!Files.exists(singlePath)) {
                        throw new IllegalArgumentException(
                                "Requested path not found in repository: " + request.getPaths().get(0));
                    }
                    return new LineageEngineInputPreparationResult(
                            singlePath.toAbsolutePath().toString(),
                            realBase.toAbsolutePath().toString());
                }

                Path collectionDir = tempDir.resolve("collect");
                Files.createDirectories(collectionDir);
                int fileCount = 0;
                List<String> missingPaths = new ArrayList<>();

                for (String path : request.getPaths()) {
                    Path source = realBase.resolve(path);
                    if (Files.exists(source)) {
                        Path destination = collectionDir.resolve(path);
                        Files.createDirectories(destination.getParent());

                        if (Files.isDirectory(source)) {
                            copyDirectory(source, destination);
                            fileCount++;
                        } else {
                            Files.copy(source, destination, StandardCopyOption.REPLACE_EXISTING);
                            fileCount++;
                        }
                    } else {
                        missingPaths.add(path);
                    }
                }

                if (fileCount == 0) {
                    try {
                        List<String> validFiles = Files.walk(realBase)
                                .filter(Files::isRegularFile)
                                .map(path -> realBase.relativize(path).toString())
                                .limit(20)
                                .collect(java.util.stream.Collectors.toList());
                        throw new IllegalArgumentException("No valid files found for requested paths: " +
                                String.join(", ", request.getPaths()) +
                                ". Checked base: " + realBase +
                                ". Detected root: " + detectedRoot +
                                ". Sample files in base: " + validFiles);
                    } catch (Exception e) {
                        if (e instanceof IllegalArgumentException illegalArgumentException) {
                            throw illegalArgumentException;
                        }
                        throw new IllegalArgumentException("No valid files found for requested paths: " +
                                String.join(", ", request.getPaths()) +
                                ". Checked base: " + realBase +
                                ". Detected root: " + detectedRoot);
                    }
                }

                if (!missingPaths.isEmpty()) {
                    log.warn("Some requested paths were not found in repository: {}", missingPaths);
                }

                log.info("用户选择的路径: {}", request.getPaths());
                log.info("筛选后准备分析的文件数量: {}", fileCount);
                logDirectoryContents(collectionDir);

                return new LineageEngineInputPreparationResult(
                        collectionDir.toAbsolutePath().toString(),
                        collectionDir.toAbsolutePath().toString());
            }

            return new LineageEngineInputPreparationResult(
                    realBase.toAbsolutePath().toString(),
                    realBase.toAbsolutePath().toString());
        }
    }

    private void copyDirectory(Path source, Path target) throws Exception {
        Files.walk(source).forEach(path -> {
            try {
                Path destination = target.resolve(source.relativize(path));
                if (Files.isDirectory(path)) {
                    Files.createDirectories(destination);
                } else {
                    Files.copy(path, destination, StandardCopyOption.REPLACE_EXISTING);
                }
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });
    }

    private Path resolveSharedBaseDir() throws Exception {
        Path baseDir = Path.of("/tmp/lineage-share");
        if (!Files.exists(baseDir)) {
            Files.createDirectories(baseDir);
        }
        return baseDir;
    }

    private void logDirectoryContents(Path dir) {
        try {
            List<String> files = Files.walk(dir)
                    .filter(Files::isRegularFile)
                    .map(path -> dir.relativize(path).toString())
                    .collect(java.util.stream.Collectors.toList());
            log.info("Prepared {} files for lineage engine in {}: {}", files.size(), dir, files);
        } catch (Exception e) {
            log.warn("Failed to list directory contents: {}", e.getMessage());
        }
    }
}
