package com.example.urgs_api.im.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.UUID;

@RestController
@RequestMapping("/api/im/file")
public class ImFileController {

    @Value("${im.upload.path:uploads/}")
    private String uploadPath;

    @Value("${im.upload.url-prefix:/uploads/}")
    private String urlPrefix;

    @PostMapping("/upload")
    public String upload(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            throw new RuntimeException("File is empty");
        }

        // Ensure directory exists
        File dir = new File(uploadPath);
        if (!dir.exists()) {
            dir.mkdirs();
        }

        // Save file
        String originalFilename = file.getOriginalFilename();
        String ext = originalFilename != null && originalFilename.contains(".")
                ? originalFilename.substring(originalFilename.lastIndexOf("."))
                : "";
        String filename = UUID.randomUUID().toString() + ext;

        try {
            file.transferTo(new File(dir.getAbsolutePath() + File.separator + filename));
            return urlPrefix + filename;
        } catch (IOException e) {
            throw new RuntimeException("Upload failed", e);
        }
    }
}
