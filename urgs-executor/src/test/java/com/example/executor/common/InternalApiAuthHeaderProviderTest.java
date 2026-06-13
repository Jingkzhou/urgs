package com.example.executor.common;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertThrows;

class InternalApiAuthHeaderProviderTest {

    @Test
    void failsStartupWhenTokenIsMissing() {
        assertThrows(IllegalStateException.class,
                () -> new InternalApiAuthHeaderProvider("Authorization", "Bearer ", ""));
    }
}
