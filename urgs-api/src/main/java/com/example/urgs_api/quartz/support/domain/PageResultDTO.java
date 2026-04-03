package com.example.urgs_api.quartz.support.domain;

import lombok.Data;

import java.util.List;

@Data
public class PageResultDTO<T> {
    private Long pageNum;
    private Long pageSize;
    private Long total;
    private Long pages;
    private List<T> list;
}
