package com.example.urgs_api.version.dto;

import lombok.Data;

/**
 * 写入 Git 仓库文件请求。
 * 文件内容使用 Base64 传输，以同时支持文本编辑和二进制文件上传。
 */
@Data
public class GitFileSaveRequest {

    /** 仓库内相对路径 */
    private String path;

    /** 目标分支 */
    private String branch;

    /** Base64 编码后的文件内容 */
    private String contentBase64;

    /** Git 提交说明 */
    private String commitMessage;

    /** 已有文件的版本 SHA，GitHub/Gitee 更新时用于并发保护 */
    private String fileSha;

    /** 是否更新已有文件；false 时创建新文件 */
    private Boolean overwrite;
}
