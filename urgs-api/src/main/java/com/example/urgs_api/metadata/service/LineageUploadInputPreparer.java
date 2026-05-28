package com.example.urgs_api.metadata.service;

import com.example.urgs_api.metadata.dto.StartEngineRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Slf4j
@Component
public class LineageUploadInputPreparer {

    @Value("${lineage.engine.shared-dir:/data/urgs/lineage/share}")
    private String sharedDir;

    public void stageUploads(StartEngineRequest request, List<MultipartFile> uploadedFiles) throws Exception {
        if (uploadedFiles == null || uploadedFiles.isEmpty()) {
            throw new IllegalArgumentException("上传模式下请至少选择一个文件");
        }

        Path stagingDir = Files.createTempDirectory(resolveSharedBaseDir(), "lineage-upload-staging-");
        try {
            Files.setPosixFilePermissions(stagingDir,
                    java.nio.file.attribute.PosixFilePermissions.fromString("rwxrwxrwx"));
        } catch (Exception e) {
            log.warn("Failed to set perms on staging dir (might be non-posix fs): {}", e.getMessage());
        }

        List<String> stagedPaths = new ArrayList<>();
        for (MultipartFile file : uploadedFiles) {
            if (file == null || file.isEmpty()) {
                continue;
            }

            String originalFilename = file.getOriginalFilename();
            String cleanedName = Paths.get(StringUtils.cleanPath(
                    StringUtils.hasText(originalFilename) ? originalFilename : "uploaded.sql"))
                    .getFileName()
                    .toString();

            Path targetPath = stagingDir.resolve(createUniqueFileName(stagingDir, cleanedName));
            Files.createDirectories(targetPath.getParent());
            file.transferTo(targetPath);
            stagedPaths.add(stagingDir.relativize(targetPath).toString().replace('\\', '/'));
        }

        if (stagedPaths.isEmpty()) {
            throw new IllegalArgumentException("请至少上传一个非空文件");
        }

        stagedPaths.sort(String::compareTo);
        grantFullPermissions(stagingDir);
        request.setLocalPath(stagingDir.toAbsolutePath().toString());
        request.setPaths(stagedPaths);
        log.info("上传文件暂存完成: {}", stagedPaths);
    }

    public LineageEngineInputPreparationResult prepare(StartEngineRequest request, List<MultipartFile> uploadedFiles)
            throws Exception {
        if (uploadedFiles != null && !uploadedFiles.isEmpty()) {
            stageUploads(request, uploadedFiles);
        }

        if (StringUtils.hasText(request.getLocalPath())) {
            Path localPath = Paths.get(request.getLocalPath()).toAbsolutePath().normalize();
            if (!Files.exists(localPath)) {
                throw new IllegalArgumentException("上传文件已失效，请重新上传后再启动");
            }

            List<Path> stagedFiles;
            try (var stream = Files.walk(localPath)) {
                stagedFiles = stream.filter(Files::isRegularFile).toList();
            }
            if (stagedFiles.isEmpty()) {
                throw new IllegalArgumentException("上传模式下请至少选择一个文件");
            }

            boolean containsZip = stagedFiles.stream()
                    .anyMatch(path -> path.getFileName().toString().toLowerCase().endsWith(".zip"));

            if (!containsZip) {
                List<String> preparedPaths = listRelativeFiles(localPath);
                request.setPaths(preparedPaths);
                grantFullPermissions(localPath);
                log.info("上传模式准备完成: {}", preparedPaths);
                logDirectoryContents(localPath);
                return new LineageEngineInputPreparationResult(localPath.toString(), localPath.toString());
            }

            Path preparedDir = Files.createTempDirectory(resolveSharedBaseDir(), "lineage-upload-prepared-");
            List<String> preparedPaths = new ArrayList<>();
            for (Path stagedFile : stagedFiles) {
                String relativePath = localPath.relativize(stagedFile).toString().replace('\\', '/');
                if (stagedFile.getFileName().toString().toLowerCase().endsWith(".zip")) {
                    extractZipToDirectory(stagedFile, preparedDir, preparedPaths);
                } else {
                    Path targetPath = preparedDir.resolve(relativePath).normalize();
                    Files.createDirectories(targetPath.getParent());
                    Files.copy(stagedFile, targetPath, StandardCopyOption.REPLACE_EXISTING);
                    preparedPaths.add(preparedDir.relativize(targetPath).toString().replace('\\', '/'));
                }
            }

            if (preparedPaths.isEmpty()) {
                throw new IllegalArgumentException("上传模式下没有可供解析的文件");
            }

            preparedPaths.sort(String::compareTo);
            grantFullPermissions(preparedDir);
            request.setLocalPath(preparedDir.toAbsolutePath().toString());
            request.setPaths(preparedPaths);
            log.info("上传模式准备完成: {}", preparedPaths);
            logDirectoryContents(preparedDir);
            return new LineageEngineInputPreparationResult(preparedDir.toString(), preparedDir.toString());
        }

        throw new IllegalArgumentException("上传模式下请至少选择一个文件");
    }

    private Path resolveSharedBaseDir() throws Exception {
        Path baseDir = Path.of(sharedDir);
        if (!Files.exists(baseDir)) {
            Files.createDirectories(baseDir);
        }
        return baseDir;
    }

    private String createUniqueFileName(Path directory, String originalName) {
        String baseName = originalName;
        String extension = "";
        int dotIndex = originalName.lastIndexOf('.');
        if (dotIndex > 0) {
            baseName = originalName.substring(0, dotIndex);
            extension = originalName.substring(dotIndex);
        }

        String candidate = originalName;
        int index = 1;
        while (Files.exists(directory.resolve(candidate))) {
            candidate = baseName + "-" + index + extension;
            index++;
        }
        return candidate;
    }

    private void extractZipToDirectory(Path zipPath, Path targetDir, List<String> preparedPaths) throws Exception {
        try (InputStream inputStream = Files.newInputStream(zipPath);
                ZipInputStream zipInputStream = new ZipInputStream(inputStream)) {
            ZipEntry entry;
            while ((entry = zipInputStream.getNextEntry()) != null) {
                String entryName = StringUtils.cleanPath(entry.getName());
                if (!StringUtils.hasText(entryName) || entryName.startsWith("__MACOSX/")) {
                    zipInputStream.closeEntry();
                    continue;
                }

                Path targetPath = targetDir.resolve(entryName).normalize();
                if (!targetPath.startsWith(targetDir)) {
                    throw new IllegalArgumentException("压缩包包含非法路径: " + entryName);
                }

                if (entry.isDirectory()) {
                    Files.createDirectories(targetPath);
                } else {
                    Files.createDirectories(targetPath.getParent());
                    Files.copy(zipInputStream, targetPath, StandardCopyOption.REPLACE_EXISTING);
                    preparedPaths.add(targetDir.relativize(targetPath).toString().replace('\\', '/'));
                }
                zipInputStream.closeEntry();
            }
        }
    }

    private List<String> listRelativeFiles(Path root) throws Exception {
        try (var stream = Files.walk(root)) {
            return stream
                    .filter(Files::isRegularFile)
                    .map(path -> root.relativize(path).toString().replace('\\', '/'))
                    .sorted(Comparator.naturalOrder())
                    .toList();
        }
    }

    private void grantFullPermissions(Path path) {
        try {
            Files.walk(path).forEach(currentPath -> {
                try {
                    Files.setPosixFilePermissions(currentPath,
                            java.nio.file.attribute.PosixFilePermissions.fromString("rwxrwxrwx"));
                } catch (Exception e) {
                    // Ignore non-posix or permission errors on specific files
                }
            });
        } catch (Exception e) {
            log.warn("Error setting permissions on {}: {}", path, e.getMessage());
        }
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
