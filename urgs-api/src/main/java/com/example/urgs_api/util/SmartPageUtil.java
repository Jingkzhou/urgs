package com.example.urgs_api.util;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.quartz.support.domain.PageParamDTO;
import com.example.urgs_api.quartz.support.domain.PageResultDTO;

public class SmartPageUtil {
    private SmartPageUtil() {
    }

    public static <T> Page<T> convert2QueryPage(PageParamDTO dto) {
        long pageNum = dto == null || dto.getPageNum() == null ? 1L : dto.getPageNum();
        long pageSize = dto == null || dto.getPageSize() == null ? 10L : dto.getPageSize();
        return new Page<>(pageNum, pageSize);
    }

    public static <T> PageResultDTO<T> convert2PageResult(Page<T> page) {
        PageResultDTO<T> result = new PageResultDTO<>();
        result.setPageNum(page.getCurrent());
        result.setPageSize(page.getSize());
        result.setTotal(page.getTotal());
        result.setPages(page.getPages());
        result.setList(page.getRecords());
        return result;
    }
}
