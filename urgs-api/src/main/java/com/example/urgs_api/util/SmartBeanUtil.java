package com.example.urgs_api.util;

import org.springframework.beans.BeanUtils;

public class SmartBeanUtil {
    private SmartBeanUtil() {
    }

    public static <T> T copy(Object source, Class<T> clazz) {
        if (source == null) {
            return null;
        }
        try {
            T target = clazz.getDeclaredConstructor().newInstance();
            BeanUtils.copyProperties(source, target);
            return target;
        } catch (Exception e) {
            throw new IllegalStateException("Bean copy failed", e);
        }
    }
}
