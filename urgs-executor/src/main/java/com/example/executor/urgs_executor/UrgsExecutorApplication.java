package com.example.executor.urgs_executor;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@org.mybatis.spring.annotation.MapperScan("com.example.executor.urgs_executor.mapper")
public class UrgsExecutorApplication {

	public static void main(String[] args) {
		SpringApplication.run(UrgsExecutorApplication.class, args);
	}

}
