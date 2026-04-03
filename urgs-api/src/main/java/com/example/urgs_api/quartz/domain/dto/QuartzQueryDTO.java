package net.lab1024.smartadmin.module.support.quartz.domain.dto;

import lombok.Data;
import net.lab1024.smartadmin.common.domain.PageParamDTO;

import javax.validation.constraints.NotNull;
import java.util.List;

/**
 * [  ]
 *
 * @author yandanyang
 * @version 1.0
 * @company 1024lab.net
 * @copyright (c) 2018 1024lab.netInc. All rights reserved.
 * @date 2019/4/15 0015 上午 11:29
 * @since JDK1.8
 */

/**
 * @RequirementName: 监管调度平台对接ESB微信公众号短信平台需求
 * @Developer: 周敬坤
 * @ModifiedDate: 2025-03-19
 * @ModificationDescription: JLB_W2025020608_监管调度平台对接ESB微信公众号短信平台需求。
 */
@Data
public class QuartzQueryDTO extends PageParamDTO {

    String dataDate;

    Long id;

    Long statusId;

    String taskName;

    String taskSystem;

    String theme;

    String status;

    String dependId;

    List<Long> dependIds;

    String beginDate;

    List<String> ids;

    List<String> statusIds;

    List<String> dataDates;

    String notificationFailed;

    String notificationCompleted;
}
