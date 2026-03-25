package com.example.urgs_api.ops.ws;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class DockerWebSocketConfig implements WebSocketConfigurer {

    @Autowired
    private DockerLogWebSocketHandler dockerLogWebSocketHandler;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(dockerLogWebSocketHandler, "/ws/docker/logs")
                .setAllowedOrigins("*");
    }
}
