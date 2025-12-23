package com.example.urgs_api.common;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.Data;

@Data
public class PageRequest {
    private Integer page = 1;
    private Integer size = 10;

    public <T> Page<T> toPage() {
        return new Page<>(page, size);
    }
}
