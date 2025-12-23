package com.example.urgs_api.common.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/common")
public class CommonController {

    @Value("${urgs.profile:./uploads}")
    private String profile;

    @PostMapping("/upload")
    public ResponseEntity<Map<String, String>> uploadFile(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        try {
            // Create directory if not exists
            String datePath = new SimpleDateFormat("yyyy/MM/dd").format(new Date());
            File uploadDir = new File(profile + "/" + datePath);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }

            // Generate unique filename
            String originalFilename = file.getOriginalFilename();
            String extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            String filename = UUID.randomUUID().toString() + extension;

            // Save file
            File dest = new File(uploadDir, filename);
            // Use absolute path to avoid issues with relative paths in embedded containers
            file.transferTo(dest.getAbsoluteFile());

            // Return URL
            String url = "/profile/" + datePath + "/" + filename;
            Map<String, String> response = new HashMap<>();
            response.put("url", url);
            response.put("name", originalFilename);

            return ResponseEntity.ok(response);
        } catch (IOException e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
