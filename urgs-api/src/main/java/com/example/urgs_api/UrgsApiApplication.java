package com.example.urgs_api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.mongo.MongoAutoConfiguration;
import org.springframework.boot.autoconfigure.data.mongo.MongoDataAutoConfiguration;
import org.springframework.boot.autoconfigure.data.neo4j.Neo4jReactiveDataAutoConfiguration;
import org.springframework.boot.autoconfigure.data.neo4j.Neo4jReactiveRepositoriesAutoConfiguration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(exclude = {
		MongoAutoConfiguration.class,
		MongoDataAutoConfiguration.class,
		Neo4jReactiveDataAutoConfiguration.class,
		Neo4jReactiveRepositoriesAutoConfiguration.class
})
@EnableAsync
@EnableScheduling
public class UrgsApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(UrgsApiApplication.class, args);
	}

}
