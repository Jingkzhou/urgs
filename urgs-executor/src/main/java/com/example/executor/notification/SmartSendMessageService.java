package com.example.executor.notification;

import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.domain.entity.QuartzTaskStatusEntity;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

@Slf4j
@Service
public class SmartSendMessageService {

    private static final DateTimeFormatter TRAN_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");
    private static final DateTimeFormatter TRAN_TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("HHmmssSSS");

    private final RestTemplateService restTemplateService;
    private final ObjectMapper objectMapper;
    private final ObjectMapper notificationObjectMapper;

    @Value("${sendmessage.shortmsgNewIp:25.18.17.139}")
    private String shortmsgNewIp;

    @Value("${sendmessage.shortmsgNewPort:11000}")
    private String shortmsgNewPort;

    @Value("${sendmessage.shortmsgNewAction:rbsp}")
    private String shortmsgNewAction;

    @Value("${sendmessage.shortmsgNewSystemid:RBSP}")
    private String shortmsgNewSystemid;

    public SmartSendMessageService(RestTemplateService restTemplateService, ObjectMapper objectMapper) {
        this.restTemplateService = restTemplateService;
        this.objectMapper = objectMapper;
        this.notificationObjectMapper = objectMapper.copy()
                .configure(JsonParser.Feature.ALLOW_UNQUOTED_FIELD_NAMES, true)
                .configure(JsonParser.Feature.ALLOW_SINGLE_QUOTES, true);
    }

    public List<NotificationSendResult> sendMessage(QuartzTaskEntity task, QuartzTaskStatusEntity taskStatus) {
        List<NotificationSendResult> results = new ArrayList<>();
        if (task == null || taskStatus == null) {
            return results;
        }
        if (isJsonEmpty(task.getNotificationCompleted()) && isJsonEmpty(task.getNotificationFailed())) {
            return results;
        }

        String messageContent = buildMessageContent(task, taskStatus);
        if (taskStatus.getStatus() != null && taskStatus.getStatus() == 3) {
            results.addAll(sendBatch(task.getNotificationCompleted(), messageContent, task.getId(), task.getDataDate(), "SUCCESS"));
        }
        if (taskStatus.getStatus() != null && taskStatus.getStatus() == 4) {
            results.addAll(sendBatch(task.getNotificationFailed(), messageContent, task.getId(), task.getDataDate(), "FAILED"));
        }
        return results;
    }

    private List<NotificationSendResult> sendBatch(String notificationJson, String content, Long taskId, String dataDate, String notifyType) {
        List<NotificationSendResult> results = new ArrayList<>();
        if (isJsonEmpty(notificationJson)) {
            return results;
        }
        try {
            JsonNode root = parseNotificationConfig(notificationJson);
            if (!root.isArray()) {
                log.warn("Notification config is not array, taskId={}, config={}", taskId, notificationJson);
                results.add(NotificationSendResult.configError(taskId, dataDate, notifyType, notificationJson, "notification config is not array"));
                return results;
            }
            Set<String> custIds = new HashSet<>();
            Iterator<JsonNode> iterator = root.elements();
            while (iterator.hasNext()) {
                JsonNode node = iterator.next();
                String custId = node.path("custid").asText("");
                if (!custId.isBlank() && custIds.add(custId)) {
                    results.add(sendWeChatMessage(custId, content, taskId, dataDate, notifyType));
                }
            }
            if (custIds.isEmpty()) {
                log.warn("Notification config has no valid custid, taskId={}, config={}", taskId, notificationJson);
                results.add(NotificationSendResult.configError(taskId, dataDate, notifyType, notificationJson, "notification config has no valid custid"));
            }
        } catch (Exception e) {
            log.error("Parse notification config failed, taskId={}, config={}", taskId, notificationJson, e);
            results.add(NotificationSendResult.configError(taskId, dataDate, notifyType, notificationJson, e.getMessage()));
        }
        return results;
    }

    private JsonNode parseNotificationConfig(String notificationJson) throws java.io.IOException {
        try {
            return objectMapper.readTree(notificationJson);
        } catch (Exception strictParseError) {
            return notificationObjectMapper.readTree(notificationJson);
        }
    }

    public NotificationSendResult sendWeChatMessage(String cstNo, String content, Long taskId, String dataDate, String notifyType) {
        String tranDate = LocalDateTime.now().format(TRAN_DATE_FORMAT);
        String tranTimestamp = LocalDateTime.now().format(TRAN_TIMESTAMP_FORMAT);
        String msgUrl = "http://" + shortmsgNewIp + ":" + shortmsgNewPort + "/" + shortmsgNewAction;
        String subSeqNo = shortmsgNewSystemid + tranTimestamp.substring(0, 8) + random4();
        String seqNo = shortmsgNewSystemid + tranDate + "DX" + tranTimestamp.substring(0, 8) + random4();

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.add("Content-Type", "application/json");

            var sysHead = objectMapper.createObjectNode();
            sysHead.put("svcCd", "50120005");
            sysHead.put("scnCd", "24");
            sysHead.put("company", "001");
            sysHead.put("channetCode", shortmsgNewSystemid);
            sysHead.put("cnsmSysId", shortmsgNewSystemid);
            sysHead.put("sourceType", shortmsgNewSystemid);
            sysHead.put("systemId", shortmsgNewSystemid);
            sysHead.put("userLang", "CHINESE");
            sysHead.put("tranMode", "ONLINE");
            sysHead.put("tranDate", tranDate);
            sysHead.put("subSeqNo", subSeqNo);
            sysHead.put("tranTimestamp", tranTimestamp);
            sysHead.put("seqNo", seqNo);

            var msgCntnt = objectMapper.createObjectNode();
            msgCntnt.put("const1", "监管任务批量状态受理");
            msgCntnt.put("character_string2", "taskid" + safeToString(taskId));
            msgCntnt.put("const3", "业务通报工单");
            msgCntnt.put("thing4", "监管批量系统调度平台");
            msgCntnt.put("thing6", content);

            var body = objectMapper.createObjectNode();
            body.put("tplId", "Evr20du9F_emwPrSVRPQK-QVNVOls-0YuZ77XB2AOl0");
            body.put("cstNo", cstNo);
            body.put("bsnNo", "03");
            body.put("msgCntnt", objectMapper.writeValueAsString(msgCntnt));

            var requestBody = objectMapper.createObjectNode();
            requestBody.set("sysHead", sysHead);
            requestBody.set("body", body);

            String response = restTemplateService.doPostShortMsgSendTemplateWithBody2(
                    msgUrl, headers, objectMapper.writeValueAsString(requestBody));
            log.info("Send wechat result, taskId={}, custid={}, response={}", taskId, cstNo, response);
            return NotificationSendResult.success(taskId, dataDate, notifyType, cstNo, msgUrl, seqNo, subSeqNo, tranDate, tranTimestamp, response);
        } catch (Exception e) {
            log.error("Send wechat failed, taskId={}, custid={}", taskId, cstNo, e);
            return NotificationSendResult.failure(taskId, dataDate, notifyType, cstNo, msgUrl, seqNo, subSeqNo, tranDate, tranTimestamp, e.getMessage());
        }
    }

    private boolean isJsonEmpty(String jsonStr) {
        return jsonStr == null || jsonStr.trim().isEmpty() || "[]".equals(jsonStr.trim());
    }

    private String buildMessageContent(QuartzTaskEntity task, QuartzTaskStatusEntity taskStatus) {
        StringBuilder sb = new StringBuilder();
        sb.append(safeToString(task.getTaskName()));
        sb.append(":").append(taskStatus.getStatus() != null && taskStatus.getStatus() == 3 ? "成功" : "失败").append("\n");
        sb.append("任务号：").append(safeToString(task.getId())).append("\n");
        sb.append("系统名称：").append(safeToString(task.getTaskSystem())).append("\n");
        String taskMessage = taskStatus.getMsg() != null ? taskStatus.getMsg() : "无详细信息";
        sb.append("详细信息：").append(substringByBytes(taskMessage, 100));
        sb.append("(->").append(random4()).append(")");
        return sb.toString();
    }

    String substringByBytes(String str, int maxLength) {
        if (str == null || maxLength <= 0) {
            return "";
        }
        byte[] bytes = str.getBytes(StandardCharsets.UTF_8);
        if (bytes.length <= maxLength) {
            return str;
        }
        int charIndex = 0;
        int byteCount = 0;
        while (charIndex < str.length()) {
            char currentChar = str.charAt(charIndex);
            int bytesPerChar = getUtf8BytesCount(currentChar, str, charIndex);
            if (byteCount + bytesPerChar > maxLength) {
                break;
            }
            byteCount += bytesPerChar;
            charIndex += Character.isHighSurrogate(currentChar) && charIndex + 1 < str.length() ? 2 : 1;
        }
        return str.substring(0, charIndex);
    }

    private int getUtf8BytesCount(char c, String str, int charIndex) {
        if (Character.isHighSurrogate(c) && charIndex + 1 < str.length()
                && Character.isLowSurrogate(str.charAt(charIndex + 1))) {
            return 4;
        }
        if (c <= 0x7F) {
            return 1;
        }
        if (c <= 0x7FF) {
            return 2;
        }
        return 3;
    }

    private static int random4() {
        return (int) (Math.random() * 9000 + 1000);
    }

    private static String safeToString(Object obj) {
        return obj == null ? "" : obj.toString();
    }

    public record NotificationSendResult(
            Long taskId,
            String dataDate,
            String notifyType,
            String custId,
            String msgUrl,
            String seqNo,
            String subSeqNo,
            String tranDate,
            String tranTimestamp,
            boolean success,
            String response,
            String errorMessage
    ) {
        static NotificationSendResult success(Long taskId, String dataDate, String notifyType, String custId,
                                              String msgUrl, String seqNo, String subSeqNo, String tranDate,
                                              String tranTimestamp, String response) {
            return new NotificationSendResult(taskId, dataDate, notifyType, custId, msgUrl, seqNo, subSeqNo,
                    tranDate, tranTimestamp, true, response, null);
        }

        static NotificationSendResult failure(Long taskId, String dataDate, String notifyType, String custId,
                                              String msgUrl, String seqNo, String subSeqNo, String tranDate,
                                              String tranTimestamp, String errorMessage) {
            return new NotificationSendResult(taskId, dataDate, notifyType, custId, msgUrl, seqNo, subSeqNo,
                    tranDate, tranTimestamp, false, null, errorMessage);
        }

        static NotificationSendResult configError(Long taskId, String dataDate, String notifyType,
                                                  String notificationJson, String errorMessage) {
            return new NotificationSendResult(taskId, dataDate, notifyType, null, null, null, null,
                    null, null, false, notificationJson, errorMessage);
        }
    }
}
