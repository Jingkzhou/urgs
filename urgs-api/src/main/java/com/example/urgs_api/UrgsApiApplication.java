package com.example.urgs_api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class UrgsApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(UrgsApiApplication.class, args);
	}

}
