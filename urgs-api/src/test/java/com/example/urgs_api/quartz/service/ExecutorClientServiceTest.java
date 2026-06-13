package com.example.urgs_api.quartz.service;

import com.example.urgs_api.quartz.domain.dto.ExecutorPoolStatsVO;
import com.example.urgs_api.quartz.support.domain.ResponseDTO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.client.ExpectedCount.once;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class ExecutorClientServiceTest {

    private MockRestServiceServer server;
    private ExecutorClientService clientService;

    @Test
    void createsSpringBeanWhenTestConstructorIsAlsoPresent() {
        new ApplicationContextRunner()
                .withBean(RestTemplateBuilder.class, RestTemplateBuilder::new)
                .withBean(ExecutorClientService.class)
                .withPropertyValues(
                        "executor.base-url=http://executor.test",
                        "executor.stats-connect-timeout-ms=2000",
                        "executor.stats-read-timeout-ms=3000")
                .run(context -> {
                    assertTrue(context.isRunning());
                    assertNotNull(context.getBean(ExecutorClientService.class));
                });
    }

    @BeforeEach
    void setUp() {
        RestTemplate restTemplate = new RestTemplate();
        server = MockRestServiceServer.bindTo(restTemplate).build();
        clientService = new ExecutorClientService(restTemplate, "http://executor.test");
    }

    @Test
    void mapsExecutorPoolStatsContract() {
        server.expect(once(), requestTo("http://executor.test/api/executor/task/pool/stats"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess("""
                        {
                          "success": true,
                          "code": 0,
                          "msg": "success",
                          "data": {
                            "activeCount": 1,
                            "poolSize": 2,
                            "maximumPoolSize": 4,
                            "queueSize": 1,
                            "queueCapacity": 10,
                            "completedTaskCount": 7,
                            "runningTaskKeys": ["1_20260612"],
                            "queuedTaskKeys": ["2_20260612"]
                          }
                        }
                        """, MediaType.APPLICATION_JSON));

        ResponseDTO<ExecutorPoolStatsVO> response = clientService.getPoolStats();

        assertTrue(response.isSuccess());
        assertNotNull(response.getData());
        assertEquals(1, response.getData().activeCount());
        assertEquals(List.of("1_20260612"), response.getData().runningTaskKeys());
        assertEquals(List.of("2_20260612"), response.getData().queuedTaskKeys());
        server.verify();
    }

    @Test
    void rejectsSuccessfulResponseWithoutStatsData() {
        server.expect(once(), requestTo("http://executor.test/api/executor/task/pool/stats"))
                .andRespond(withSuccess("""
                        {"success": true, "code": 0, "msg": "success", "data": null}
                        """, MediaType.APPLICATION_JSON));

        ResponseDTO<ExecutorPoolStatsVO> response = clientService.getPoolStats();

        assertFalse(response.isSuccess());
        assertEquals("执行器返回的线程池统计为空", response.getMsg());
        server.verify();
    }

    @Test
    void defaultsMissingQueuedTaskKeysForRollingDeploymentCompatibility() {
        server.expect(once(), requestTo("http://executor.test/api/executor/task/pool/stats"))
                .andRespond(withSuccess("""
                        {
                          "success": true,
                          "code": 0,
                          "data": {
                            "activeCount": 0,
                            "poolSize": 0,
                            "maximumPoolSize": 500,
                            "queueSize": 0,
                            "queueCapacity": 10000,
                            "completedTaskCount": 0,
                            "runningTaskKeys": []
                          }
                        }
                        """, MediaType.APPLICATION_JSON));

        ResponseDTO<ExecutorPoolStatsVO> response = clientService.getPoolStats();

        assertTrue(response.isSuccess());
        assertNotNull(response.getData());
        assertEquals(List.of(), response.getData().queuedTaskKeys());
        server.verify();
    }
}
