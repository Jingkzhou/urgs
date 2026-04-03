package com.example.executor;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class UrgsExecutorApplication {

    public static void main(String[] args) {
        SpringApplication.run(UrgsExecutorApplication.class, args);
    }
}
