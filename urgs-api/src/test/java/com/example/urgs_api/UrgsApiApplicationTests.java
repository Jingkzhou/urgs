package com.example.urgs_api;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = "urgs.internal-api.auth-token=test-internal-token")
class UrgsApiApplicationTests {

	@Test
	void contextLoads() {
	}

}
