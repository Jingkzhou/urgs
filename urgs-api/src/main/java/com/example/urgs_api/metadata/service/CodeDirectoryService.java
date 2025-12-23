package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.metadata.model.CodeDirectory;
import org.springframework.web.multipart.MultipartFile;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 代码目录服务接口
 */
public interface CodeDirectoryService extends IService<CodeDirectory> {
    /**
     * 导入代码目录数据
     * 
     * @param file Excel文件
     */
    void importData(MultipartFile file);

    /**
     * 导出代码目录数据
     * 
     * @param response HTTP响应对象
     */
    void exportData(HttpServletResponse response);
}
