package com.example.executor.notification;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class RestTemplateService {

    private final RestTemplate restTemplate;

    public RestTemplateService(RestTemplateBuilder builder) {
        this.restTemplate = builder.build();
    }

    public String doPostShortMsgSendTemplateWithBody2(String url, HttpHeaders httpHeaders, String message) {
        HttpEntity<String> requestEntity = new HttpEntity<>(message, httpHeaders);
        ResponseEntity<String> responseEntity = restTemplate.exchange(
                url, HttpMethod.POST, requestEntity, String.class);
        return responseEntity.getBody();
    }
}
