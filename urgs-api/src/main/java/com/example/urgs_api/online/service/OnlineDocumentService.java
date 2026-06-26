package com.example.urgs_api.online.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.common.exception.BadRequestException;
import com.example.urgs_api.common.exception.ForbiddenException;
import com.example.urgs_api.common.exception.ResourceNotFoundException;
import com.example.urgs_api.online.dto.OnlineDocumentPermissionGroupDTO;
import com.example.urgs_api.online.dto.OnlineDocumentPermissionGroupRequest;
import com.example.urgs_api.online.dto.OnlineDocumentPermissionDTO;
import com.example.urgs_api.online.entity.OnlineDocument;
import com.example.urgs_api.online.entity.OnlineDocumentPermissionGroup;
import com.example.urgs_api.online.entity.OnlineDocumentPermissionGroupMember;
import com.example.urgs_api.online.entity.OnlineDocumentPermission;
import com.example.urgs_api.online.mapper.OnlineDocumentMapper;
import com.example.urgs_api.online.mapper.OnlineDocumentPermissionGroupMapper;
import com.example.urgs_api.online.mapper.OnlineDocumentPermissionGroupMemberMapper;
import com.example.urgs_api.online.mapper.OnlineDocumentPermissionMapper;
import com.example.urgs_api.user.dto.UserDTO;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * 在线文档服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OnlineDocumentService {

    private final OnlineDocumentMapper documentMapper;
    private final OnlineDocumentPermissionMapper permissionMapper;
    private final OnlineDocumentPermissionGroupMapper permissionGroupMapper;
    private final OnlineDocumentPermissionGroupMemberMapper permissionGroupMemberMapper;
    private final UserMapper userMapper;
    private final ObjectMapper objectMapper;

    @Value("${urgs.profile:./uploads}")
    private String profile;

    @Value("${urgs.onlyoffice.callback-secret:urgs-onlyoffice-callback-secret}")
    private String onlyOfficeCallbackSecret;

    @Value("${urgs.onlyoffice.jwt-secret:}")
    private String onlyOfficeJwtSecret;

    @Value("${urgs.onlyoffice.document-server-url:http://localhost:8088}")
    private String onlyOfficeDocumentServerUrl;

    public IPage<OnlineDocument> listDocuments(Long userId, String keyword, String fileType, int page, int size) {
        return listDocuments(userId, ListQueryScope.ALL, keyword, fileType, page, size);
    }

    /**
     * 列出用户收藏的文档
     */
    public IPage<OnlineDocument> listFavoriteDocuments(Long userId, String keyword, String fileType, int page, int size) {
        return listDocuments(userId, ListQueryScope.FAVORITE, keyword, fileType, page, size);
    }

    /**
     * 列出用户在指定空间中的文档
     */
    public IPage<OnlineDocument> listSpaceDocuments(Long userId, String spaceType, String keyword, String fileType, int page, int size) {
        ListQueryScope scope = parseSpaceScope(spaceType);
        return listDocuments(userId, scope, keyword, fileType, page, size);
    }

    /**
     * 查询范围枚举：消除 magic string，便于阅读和重构
     */
    private enum ListQueryScope {
        /** 全部（个人+共享） */
        ALL,
        /** 仅个人创建 */
        PERSONAL,
        /** 仅共享给我 */
        SHARED,
        /** 收藏（个人+共享中标记为收藏的） */
        FAVORITE
    }

    /**
     * 统一文档查询方法：消除三个 list 方法的重复逻辑
     */
    private IPage<OnlineDocument> listDocuments(Long userId, ListQueryScope scope, String keyword, String fileType, int page, int size) {
        List<Long> sharedDocumentIds = findSharedDocumentIds(userId);

        LambdaQueryWrapper<OnlineDocument> wrapper = new LambdaQueryWrapper<>();
        applyScopeCondition(wrapper, scope, userId, sharedDocumentIds);
        applyKeywordAndFileTypeFilter(wrapper, keyword, fileType);
        wrapper.orderByDesc(OnlineDocument::getUpdateTime);

        IPage<OnlineDocument> result = documentMapper.selectPage(new Page<>(page, size), wrapper);
        fillPresentationFields(result.getRecords(), userId);
        return result;
    }

    /**
     * 查询用户被授权的文档 ID 列表
     */
    private List<Long> findSharedDocumentIds(Long userId) {
        return permissionMapper.selectList(
                        new LambdaQueryWrapper<OnlineDocumentPermission>()
                                .eq(OnlineDocumentPermission::getUserId, userId)
                                .select(OnlineDocumentPermission::getDocumentId))
                .stream()
                .map(OnlineDocumentPermission::getDocumentId)
                .toList();
    }

    /**
     * 根据查询范围应用文档可见性条件
     */
    private void applyScopeCondition(LambdaQueryWrapper<OnlineDocument> wrapper,
                                     ListQueryScope scope,
                                     Long userId,
                                     List<Long> sharedDocumentIds) {
        switch (scope) {
            case ALL -> applyOwnerOrSharedCondition(wrapper, userId, sharedDocumentIds);
            case PERSONAL -> wrapper.eq(OnlineDocument::getUserId, userId);
            case SHARED -> {
                if (sharedDocumentIds.isEmpty()) {
                    // 使用一个不可能匹配的值，确保返回空结果
                    wrapper.eq(OnlineDocument::getId, -1L);
                } else {
                    wrapper.in(OnlineDocument::getId, sharedDocumentIds);
                }
            }
            case FAVORITE -> {
                wrapper.eq(OnlineDocument::getFavorite, Boolean.TRUE);
                applyOwnerOrSharedCondition(wrapper, userId, sharedDocumentIds);
            }
        }
    }

    /**
     * 应用"个人创建 OR 他人共享"的可见性条件
     */
    private void applyOwnerOrSharedCondition(LambdaQueryWrapper<OnlineDocument> wrapper,
                                             Long userId,
                                             List<Long> sharedDocumentIds) {
        wrapper.and(w -> {
            w.eq(OnlineDocument::getUserId, userId);
            if (!sharedDocumentIds.isEmpty()) {
                w.or().in(OnlineDocument::getId, sharedDocumentIds);
            }
        });
    }

    /**
     * 统一应用关键词和文件类型过滤
     */
    private void applyKeywordAndFileTypeFilter(LambdaQueryWrapper<OnlineDocument> wrapper, String keyword, String fileType) {
        if (StringUtils.hasText(keyword)) {
            wrapper.like(OnlineDocument::getTitle, keyword);
        }
        if (StringUtils.hasText(fileType)) {
            List<String> extensions = resolveExtensions(fileType);
            if (!extensions.isEmpty()) {
                wrapper.and(w -> {
                    for (int i = 0; i < extensions.size(); i++) {
                        String ext = extensions.get(i);
                        if (i == 0) {
                            w.like(OnlineDocument::getFileName, "." + ext);
                        } else {
                            w.or().like(OnlineDocument::getFileName, "." + ext);
                        }
                    }
                });
            }
        }
    }

    /**
     * 将前端传入的空间类型字符串转换为查询范围
     */
    private ListQueryScope parseSpaceScope(String spaceType) {
        if (spaceType == null || spaceType.isBlank()) {
            return ListQueryScope.ALL;
        }
        return switch (spaceType.toLowerCase()) {
            case "personal" -> ListQueryScope.PERSONAL;
            case "shared" -> ListQueryScope.SHARED;
            case "all" -> ListQueryScope.ALL;
            default -> throw new BadRequestException("无效的空间类型: " + spaceType);
        };
    }

    /**
     * 切换文档收藏状态
     */
    @Transactional
    public OnlineDocument toggleFavorite(Long documentId, Long userId) {
        OnlineDocument doc = getAccessibleDocument(documentId, userId);
        boolean nextFavorite = !Boolean.TRUE.equals(doc.getFavorite());
        doc.setFavorite(nextFavorite);
        doc.setUpdateTime(LocalDateTime.now());
        documentMapper.updateById(doc);
        log.info("用户 {} 切换文档收藏状态: documentId={}, favorite={}", userId, documentId, nextFavorite);
        return doc;
    }

    /**
     * 设置文档空间类型
     */
    @Transactional
    public OnlineDocument setSpaceType(Long documentId, Long userId, String spaceType) {
        OnlineDocument doc = getOwnedDocument(documentId, userId);
        String normalizedSpaceType = parseSpaceScope(spaceType) == ListQueryScope.PERSONAL
                ? "personal"
                : "shared";
        doc.setSpaceType(normalizedSpaceType);
        doc.setUpdateTime(LocalDateTime.now());
        documentMapper.updateById(doc);
        log.info("用户 {} 设置文档空间类型: documentId={}, spaceType={}", userId, documentId, normalizedSpaceType);
        return doc;
    }

    private List<String> resolveExtensions(String fileType) {
        return switch (fileType) {
            case "word" -> List.of("doc", "docx");
            case "excel" -> List.of("xls", "xlsx");
            case "pdf" -> List.of("pdf");
            default -> List.of();
        };
    }

    @Transactional
    public OnlineDocument createDocument(Long userId, OnlineDocument doc) {
        doc.setUserId(userId);
        doc.setCreateTime(LocalDateTime.now());
        doc.setUpdateTime(LocalDateTime.now());
        documentMapper.insert(doc);
        log.info("用户 {} 创建在线文档: {}", userId, doc.getTitle());
        return doc;
    }

    @Transactional
    public OnlineDocument createBlankDocument(Long userId, String title, String documentType) {
        String normalizedType = normalizeDocumentType(documentType);
        String extension = switch (normalizedType) {
            case "cell" -> "xlsx";
            default -> "docx";
        };
        String safeTitle = StringUtils.hasText(title) ? title.trim() : defaultTitle(normalizedType);
        if (!safeTitle.toLowerCase().endsWith("." + extension)) {
            safeTitle = safeTitle + "." + extension;
        }

        LocalDate today = LocalDate.now();
        String datePath = today.getYear() + "/" + String.format("%02d", today.getMonthValue()) + "/"
                + String.format("%02d", today.getDayOfMonth());
        Path targetDir = Path.of(profile).toAbsolutePath().normalize().resolve("online-docs").resolve(datePath);
        String storedFileName = UUID.randomUUID() + "." + extension;
        Path targetPath = targetDir.resolve(storedFileName);

        try {
            Files.createDirectories(targetDir);
            writeBlankOfficeFile(targetPath, normalizedType);
        } catch (IOException e) {
            throw new RuntimeException("创建空白在线文档失败", e);
        }

        OnlineDocument doc = new OnlineDocument();
        doc.setTitle(safeTitle);
        doc.setFileName(safeTitle);
        doc.setFileUrl("/profile/online-docs/" + datePath + "/" + storedFileName);
        doc.setFileSize(targetPath.toFile().length());
        return createDocument(userId, doc);
    }

    @Transactional
    public OnlineDocument updateDocument(Long id, Long userId, OnlineDocument updates) {
        OnlineDocument doc = getAccessibleDocument(id, userId);
        if (updates.getTitle() != null) {
            doc.setTitle(updates.getTitle());
        }
        if (updates.getFileName() != null) {
            doc.setFileName(updates.getFileName());
        }
        doc.setUpdateTime(LocalDateTime.now());
        documentMapper.updateById(doc);
        return doc;
    }

    @Transactional
    public void deleteDocument(Long id, Long userId) {
        OnlineDocument doc = getOwnedDocument(id, userId);
        permissionMapper.delete(new LambdaQueryWrapper<OnlineDocumentPermission>()
                .eq(OnlineDocumentPermission::getDocumentId, doc.getId()));
        documentMapper.deleteById(doc.getId());
        log.info("删除在线文档: {}", id);
    }

    public OnlineDocument getAccessibleDocument(Long id, Long userId) {
        OnlineDocument doc = documentMapper.selectById(id);
        if (doc == null) {
            throw new ResourceNotFoundException("在线文档不存在");
        }
        if (!userId.equals(doc.getUserId()) && !hasPermission(id, userId)) {
            throw new ForbiddenException("无权访问该在线文档");
        }
        fillPresentationFields(List.of(doc), userId);
        return doc;
    }

    public OnlineDocument getOwnedDocument(Long id, Long userId) {
        OnlineDocument doc = documentMapper.selectById(id);
        if (doc == null) {
            throw new ResourceNotFoundException("在线文档不存在");
        }
        if (!userId.equals(doc.getUserId())) {
            throw new ForbiddenException("仅文档所有者可执行该操作");
        }
        fillPresentationFields(List.of(doc), userId);
        return doc;
    }

    public List<OnlineDocumentPermissionDTO> listPermissions(Long documentId, Long ownerId) {
        getOwnedDocument(documentId, ownerId);
        List<OnlineDocumentPermission> permissions = permissionMapper.selectList(
                new LambdaQueryWrapper<OnlineDocumentPermission>()
                        .eq(OnlineDocumentPermission::getDocumentId, documentId)
                        .orderByDesc(OnlineDocumentPermission::getCreateTime));
        if (permissions.isEmpty()) {
            return List.of();
        }

        Map<Long, User> users = userMapper.selectBatchIds(
                        permissions.stream().map(OnlineDocumentPermission::getUserId).toList())
                .stream()
                .collect(Collectors.toMap(User::getId, Function.identity(), (left, right) -> left));

        return permissions.stream().map(permission -> {
            User user = users.get(permission.getUserId());
            OnlineDocumentPermissionDTO dto = new OnlineDocumentPermissionDTO();
            dto.setUserId(permission.getUserId());
            dto.setUserName(user == null ? "用户" + permission.getUserId() : user.getName());
            dto.setEmpId(user == null ? null : user.getEmpId());
            dto.setCreateTime(permission.getCreateTime());
            return dto;
        }).toList();
    }

    public List<UserDTO> searchPermissionUsers(String keyword) {
        return userMapper.searchUsers(keyword).stream()
                .limit(50)
                .map(UserDTO::fromEntity)
                .toList();
    }

    public String getUserDisplayName(Long userId) {
        User user = userId == null ? null : userMapper.selectById(userId);
        if (user == null) {
            return "用户" + userId;
        }
        if (StringUtils.hasText(user.getName())) {
            return user.getName();
        }
        if (StringUtils.hasText(user.getEmpId())) {
            return user.getEmpId();
        }
        return "用户" + userId;
    }

    public List<OnlineDocumentPermissionGroupDTO> listPermissionGroups(Long ownerUserId) {
        List<OnlineDocumentPermissionGroup> groups = permissionGroupMapper.selectList(
                new LambdaQueryWrapper<OnlineDocumentPermissionGroup>()
                        .eq(OnlineDocumentPermissionGroup::getOwnerUserId, ownerUserId)
                        .orderByDesc(OnlineDocumentPermissionGroup::getUpdateTime));
        if (groups.isEmpty()) {
            return List.of();
        }

        List<Long> groupIds = groups.stream().map(OnlineDocumentPermissionGroup::getId).toList();
        List<OnlineDocumentPermissionGroupMember> members = permissionGroupMemberMapper.selectList(
                new LambdaQueryWrapper<OnlineDocumentPermissionGroupMember>()
                        .in(OnlineDocumentPermissionGroupMember::getGroupId, groupIds)
                        .orderByAsc(OnlineDocumentPermissionGroupMember::getId));

        Set<Long> userIds = members.stream()
                .map(OnlineDocumentPermissionGroupMember::getUserId)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Map<Long, User> users = userIds.isEmpty() ? Map.of() : userMapper.selectBatchIds(userIds)
                .stream()
                .collect(Collectors.toMap(User::getId, Function.identity(), (left, right) -> left));
        Map<Long, List<OnlineDocumentPermissionGroupMember>> membersByGroup = members.stream()
                .collect(Collectors.groupingBy(OnlineDocumentPermissionGroupMember::getGroupId));

        return groups.stream()
                .map(group -> toPermissionGroupDTO(group, membersByGroup.getOrDefault(group.getId(), List.of()), users))
                .toList();
    }

    @Transactional
    public OnlineDocumentPermissionGroupDTO createPermissionGroup(
            Long ownerUserId, OnlineDocumentPermissionGroupRequest request) {
        String name = normalizePermissionGroupName(request.getName());
        OnlineDocumentPermissionGroup group = new OnlineDocumentPermissionGroup();
        group.setOwnerUserId(ownerUserId);
        group.setName(name);
        group.setDescription(StringUtils.hasText(request.getDescription()) ? request.getDescription().trim() : null);
        LocalDateTime now = LocalDateTime.now();
        group.setCreateTime(now);
        group.setUpdateTime(now);
        permissionGroupMapper.insert(group);
        replacePermissionGroupMembers(group.getId(), ownerUserId, request.getUserIds());
        return getPermissionGroup(ownerUserId, group.getId());
    }

    @Transactional
    public OnlineDocumentPermissionGroupDTO updatePermissionGroup(
            Long ownerUserId, Long groupId, OnlineDocumentPermissionGroupRequest request) {
        OnlineDocumentPermissionGroup group = getOwnedPermissionGroup(ownerUserId, groupId);
        group.setName(normalizePermissionGroupName(request.getName()));
        group.setDescription(StringUtils.hasText(request.getDescription()) ? request.getDescription().trim() : null);
        group.setUpdateTime(LocalDateTime.now());
        permissionGroupMapper.updateById(group);
        replacePermissionGroupMembers(group.getId(), ownerUserId, request.getUserIds());
        return getPermissionGroup(ownerUserId, group.getId());
    }

    @Transactional
    public void deletePermissionGroup(Long ownerUserId, Long groupId) {
        getOwnedPermissionGroup(ownerUserId, groupId);
        permissionGroupMemberMapper.delete(new LambdaQueryWrapper<OnlineDocumentPermissionGroupMember>()
                .eq(OnlineDocumentPermissionGroupMember::getGroupId, groupId));
        permissionGroupMapper.deleteById(groupId);
    }

    @Transactional
    public List<OnlineDocumentPermissionDTO> savePermissions(Long documentId, Long ownerId, List<Long> userIds) {
        OnlineDocument doc = getOwnedDocument(documentId, ownerId);
        Set<Long> nextUserIds = userIds == null ? Set.of() : userIds.stream()
                .filter(id -> id != null && !id.equals(ownerId))
                .collect(Collectors.toCollection(LinkedHashSet::new));

        List<Long> validUserIds = nextUserIds.isEmpty()
                ? List.of()
                : userMapper.selectBatchIds(nextUserIds).stream()
                        .map(User::getId)
                        .toList();

        permissionMapper.delete(new LambdaQueryWrapper<OnlineDocumentPermission>()
                .eq(OnlineDocumentPermission::getDocumentId, documentId));

        LocalDateTime now = LocalDateTime.now();
        for (Long sharedUserId : validUserIds) {
            OnlineDocumentPermission permission = new OnlineDocumentPermission();
            permission.setDocumentId(documentId);
            permission.setUserId(sharedUserId);
            permission.setCreateBy(ownerId);
            permission.setCreateTime(now);
            permissionMapper.insert(permission);
        }

        log.info("用户 {} 更新在线文档授权: documentId={}, sharedUsers={}",
                ownerId, doc.getId(), validUserIds);
        return listPermissions(documentId, ownerId);
    }

    private OnlineDocumentPermissionGroupDTO getPermissionGroup(Long ownerUserId, Long groupId) {
        OnlineDocumentPermissionGroup group = getOwnedPermissionGroup(ownerUserId, groupId);
        List<OnlineDocumentPermissionGroupMember> members = permissionGroupMemberMapper.selectList(
                new LambdaQueryWrapper<OnlineDocumentPermissionGroupMember>()
                        .eq(OnlineDocumentPermissionGroupMember::getGroupId, groupId)
                        .orderByAsc(OnlineDocumentPermissionGroupMember::getId));
        Set<Long> userIds = members.stream()
                .map(OnlineDocumentPermissionGroupMember::getUserId)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Map<Long, User> users = userIds.isEmpty() ? Map.of() : userMapper.selectBatchIds(userIds)
                .stream()
                .collect(Collectors.toMap(User::getId, Function.identity(), (left, right) -> left));
        return toPermissionGroupDTO(group, members, users);
    }

    private OnlineDocumentPermissionGroup getOwnedPermissionGroup(Long ownerUserId, Long groupId) {
        OnlineDocumentPermissionGroup group = permissionGroupMapper.selectById(groupId);
        if (group == null) {
            throw new ResourceNotFoundException("授权组不存在");
        }
        if (!ownerUserId.equals(group.getOwnerUserId())) {
            throw new ForbiddenException("无权管理该授权组");
        }
        return group;
    }

    private void replacePermissionGroupMembers(Long groupId, Long ownerUserId, List<Long> userIds) {
        Set<Long> nextUserIds = userIds == null ? Set.of() : userIds.stream()
                .filter(id -> id != null && !id.equals(ownerUserId))
                .collect(Collectors.toCollection(LinkedHashSet::new));
        List<Long> validUserIds = nextUserIds.isEmpty()
                ? List.of()
                : userMapper.selectBatchIds(nextUserIds).stream()
                        .map(User::getId)
                        .toList();

        permissionGroupMemberMapper.delete(new LambdaQueryWrapper<OnlineDocumentPermissionGroupMember>()
                .eq(OnlineDocumentPermissionGroupMember::getGroupId, groupId));

        LocalDateTime now = LocalDateTime.now();
        for (Long memberUserId : validUserIds) {
            OnlineDocumentPermissionGroupMember member = new OnlineDocumentPermissionGroupMember();
            member.setGroupId(groupId);
            member.setUserId(memberUserId);
            member.setCreateTime(now);
            permissionGroupMemberMapper.insert(member);
        }
    }

    private String normalizePermissionGroupName(String name) {
        if (!StringUtils.hasText(name)) {
            throw new BadRequestException("授权组名称不能为空");
        }
        String normalized = name.trim();
        if (normalized.length() > 100) {
            throw new BadRequestException("授权组名称不能超过100个字符");
        }
        return normalized;
    }

    private OnlineDocumentPermissionGroupDTO toPermissionGroupDTO(
            OnlineDocumentPermissionGroup group,
            List<OnlineDocumentPermissionGroupMember> members,
            Map<Long, User> users) {
        OnlineDocumentPermissionGroupDTO dto = new OnlineDocumentPermissionGroupDTO();
        dto.setId(group.getId());
        dto.setName(group.getName());
        dto.setDescription(group.getDescription());
        dto.setCreateTime(group.getCreateTime());
        dto.setUpdateTime(group.getUpdateTime());
        dto.setMemberCount(members.size());
        dto.setMembers(members.stream()
                .map(member -> UserDTO.fromEntity(users.get(member.getUserId())))
                .filter(user -> user != null)
                .toList());
        return dto;
    }

    public OnlineDocument getDocument(Long id) {
        OnlineDocument doc = documentMapper.selectById(id);
        if (doc == null) {
            throw new ResourceNotFoundException("在线文档不存在");
        }
        return doc;
    }

    private boolean hasPermission(Long documentId, Long userId) {
        return permissionMapper.selectCount(new LambdaQueryWrapper<OnlineDocumentPermission>()
                .eq(OnlineDocumentPermission::getDocumentId, documentId)
                .eq(OnlineDocumentPermission::getUserId, userId)) > 0;
    }

    private void fillPresentationFields(List<OnlineDocument> documents, Long currentUserId) {
        if (documents == null || documents.isEmpty()) {
            return;
        }
        Set<Long> ownerIds = documents.stream()
                .map(OnlineDocument::getUserId)
                .collect(Collectors.toSet());
        Map<Long, User> users = ownerIds.isEmpty() ? Map.of() : userMapper.selectBatchIds(ownerIds)
                .stream()
                .collect(Collectors.toMap(User::getId, Function.identity(), (left, right) -> left));

        for (OnlineDocument doc : documents) {
            User owner = users.get(doc.getUserId());
            boolean isOwner = currentUserId != null && currentUserId.equals(doc.getUserId());
            doc.setOwnerName(owner == null ? "用户" + doc.getUserId() : owner.getName());
            doc.setShared(!isOwner);
            doc.setCanManagePermissions(isOwner);
        }
    }

    /**
     * 构建 ONLYOFFICE 编辑器前端配置
     */
    public Map<String, Object> buildOnlyOfficeEditorConfig(Long documentId, Long userId,
                                                            String fileUrl, String callbackUrl) {
        OnlineDocument doc = getAccessibleDocument(documentId, userId);
        String fileName = doc.getFileName() != null ? doc.getFileName() : doc.getTitle();
        String extension = getFileExtension(fileName);

        Map<String, Object> document = new HashMap<>();
        document.put("fileType", extension);
        // Keep the key stable so all users editing the same document join one co-editing session.
        document.put("key", "online-" + doc.getId());
        document.put("title", fileName);
        document.put("url", fileUrl);
        document.put("permissions", Map.of(
                "download", true,
                "edit", isEditableByOnlyOffice(extension),
                "print", true));

        Map<String, Object> editorConfig = new HashMap<>();
        editorConfig.put("mode", isEditableByOnlyOffice(extension) ? "edit" : "view");
        editorConfig.put("lang", "zh-CN");
        editorConfig.put("callbackUrl", callbackUrl);
        editorConfig.put("user", Map.of(
                "id", String.valueOf(userId),
                "name", getUserDisplayName(userId)));
        editorConfig.put("customization", Map.of(
                "autosave", true,
                "forcesave", true,
                "compactToolbar", false,
                "help", false));

        Map<String, Object> config = new HashMap<>();
        config.put("type", "desktop");
        config.put("documentType", resolveOnlyOfficeDocumentType(extension));
        config.put("document", document);
        config.put("editorConfig", editorConfig);
        config.put("width", "100%");
        config.put("height", "100%");
        if (StringUtils.hasText(onlyOfficeJwtSecret)) {
            config.put("token", buildOnlyOfficeJwt(config));
        }

        return Map.of(
                "documentServerUrl", normalizeDocumentServerUrl(),
                "config", config);
    }

    // ---- ONLYOFFICE helpers ----

    private String getFileExtension(String fileName) {
        if (!StringUtils.hasText(fileName) || !fileName.contains(".")) {
            return "";
        }
        return fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
    }

    private String resolveOnlyOfficeDocumentType(String extension) {
        if (List.of("doc", "docx", "odt", "rtf", "txt").contains(extension)) {
            return "word";
        }
        if (List.of("xls", "xlsx", "ods", "csv").contains(extension)) {
            return "cell";
        }
        if (List.of("ppt", "pptx", "odp").contains(extension)) {
            return "slide";
        }
        if ("pdf".equals(extension)) {
            return "pdf";
        }
        return "word";
    }

    private boolean isEditableByOnlyOffice(String extension) {
        return List.of("docx", "xlsx", "pptx").contains(extension);
    }

    private String normalizeDocumentServerUrl() {
        return onlyOfficeDocumentServerUrl.replaceAll("/+$", "");
    }

    private String buildOnlyOfficeJwt(Map<String, Object> payload) {
        try {
            String headerJson = objectMapper.writeValueAsString(Map.of("alg", "HS256", "typ", "JWT"));
            String payloadJson = objectMapper.writeValueAsString(payload);
            String encodedHeader = base64Url(headerJson.getBytes(StandardCharsets.UTF_8));
            String encodedPayload = base64Url(payloadJson.getBytes(StandardCharsets.UTF_8));
            String signingInput = encodedHeader + "." + encodedPayload;

            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(onlyOfficeJwtSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return signingInput + "." + base64Url(mac.doFinal(signingInput.getBytes(StandardCharsets.UTF_8)));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("ONLYOFFICE JWT 序列化失败", e);
        } catch (Exception e) {
            throw new IllegalStateException("ONLYOFFICE JWT 签名失败", e);
        }
    }

    private String base64Url(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public String buildOnlyOfficeCallbackToken(Long documentId, String fileUrl) {
        return hmacSha256(documentId + ":" + (fileUrl == null ? "" : fileUrl), onlyOfficeCallbackSecret);
    }

    public boolean verifyOnlyOfficeCallbackToken(Long documentId, String fileUrl, String token) {
        if (!StringUtils.hasText(token)) {
            return false;
        }
        return buildOnlyOfficeCallbackToken(documentId, fileUrl).equals(token);
    }

    @Transactional
    public void saveOnlyOfficeDocument(Long documentId, String downloadUrl) {
        OnlineDocument doc = getDocument(documentId);
        if (!StringUtils.hasText(doc.getFileUrl())) {
            throw new BadRequestException("在线文档文件地址为空");
        }

        Path targetPath = resolveUploadedFile(doc.getFileUrl());
        try {
            Files.createDirectories(targetPath.getParent());
            Path tempFile = Files.createTempFile(targetPath.getParent(), "onlyoffice-", ".tmp");
            try {
                HttpRequest request = HttpRequest.newBuilder(URI.create(downloadUrl)).GET().build();
                HttpResponse<Path> response = HttpClient.newHttpClient()
                        .send(request, HttpResponse.BodyHandlers.ofFile(tempFile));
                if (response.statusCode() < 200 || response.statusCode() >= 300) {
                    throw new RuntimeException("ONLYOFFICE 保存文件下载失败: " + response.statusCode());
                }
                Files.move(tempFile, targetPath, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            } finally {
                Files.deleteIfExists(tempFile);
            }
        } catch (IOException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new RuntimeException("ONLYOFFICE 保存文件失败", e);
        }

        doc.setFileSize(targetPath.toFile().length());
        doc.setUpdateTime(LocalDateTime.now());
        documentMapper.updateById(doc);
        log.info("ONLYOFFICE 保存在线文档成功: documentId={}, fileName={}", documentId, doc.getFileName());
    }

    private Path resolveUploadedFile(String fileUrl) {
        String normalized = fileUrl;
        try {
            URI uri = URI.create(fileUrl);
            if (StringUtils.hasText(uri.getPath())) {
                normalized = uri.getPath();
            }
        } catch (IllegalArgumentException ignored) {
            normalized = fileUrl;
        }

        if (!normalized.startsWith("/profile/")) {
            throw new BadRequestException("仅支持保存本地上传文件: " + fileUrl);
        }

        String relativePath = normalized.substring("/profile/".length());
        Path basePath = Path.of(profile).toAbsolutePath().normalize();
        Path resolvedPath = basePath.resolve(relativePath).normalize();
        if (!resolvedPath.startsWith(basePath)) {
            throw new BadRequestException("非法文件路径: " + fileUrl);
        }
        return resolvedPath;
    }

    private String hmacSha256(String value, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            throw new IllegalStateException("ONLYOFFICE 回调签名生成失败", e);
        }
    }

    private String normalizeDocumentType(String documentType) {
        if ("cell".equals(documentType) || "word".equals(documentType)) {
            return documentType;
        }
        throw new BadRequestException("仅支持新建文字文档和电子表格");
    }

    private String defaultTitle(String documentType) {
        return switch (documentType) {
            case "cell" -> "新建表格.xlsx";
            default -> "新建文档.docx";
        };
    }

    private void writeBlankOfficeFile(Path targetPath, String documentType) throws IOException {
        try (ZipOutputStream zip = new ZipOutputStream(Files.newOutputStream(targetPath), StandardCharsets.UTF_8)) {
            switch (documentType) {
                case "cell" -> writeBlankWorkbook(zip);
                default -> writeBlankWordDocument(zip);
            }
        }
    }

    private void writeZipEntry(ZipOutputStream zip, String name, String content) throws IOException {
        zip.putNextEntry(new ZipEntry(name));
        zip.write(content.stripLeading().getBytes(StandardCharsets.UTF_8));
        zip.closeEntry();
    }

    private void writeBlankWordDocument(ZipOutputStream zip) throws IOException {
        writeZipEntry(zip, "[Content_Types].xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
                </Types>
                """);
        writeZipEntry(zip, "_rels/.rels", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
                </Relationships>
                """);
        writeZipEntry(zip, "word/document.xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body>
                    <w:p/>
                    <w:sectPr>
                      <w:pgSz w:w="11906" w:h="16838"/>
                      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/>
                    </w:sectPr>
                  </w:body>
                </w:document>
                """);
    }

    private void writeBlankWorkbook(ZipOutputStream zip) throws IOException {
        writeZipEntry(zip, "[Content_Types].xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
                  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
                  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
                </Types>
                """);
        writeZipEntry(zip, "_rels/.rels", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
                  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
                </Relationships>
                """);
        writeZipEntry(zip, "docProps/core.xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                    xmlns:dc="http://purl.org/dc/elements/1.1/"
                    xmlns:dcterms="http://purl.org/dc/terms/"
                    xmlns:dcmitype="http://purl.org/dc/dcmitype/"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                  <dc:creator>URGS</dc:creator>
                  <cp:lastModifiedBy>URGS</cp:lastModifiedBy>
                </cp:coreProperties>
                """);
        writeZipEntry(zip, "docProps/app.xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
                    xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
                  <Application>URGS</Application>
                </Properties>
                """);
        writeZipEntry(zip, "xl/workbook.xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                  <sheets>
                    <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
                  </sheets>
                </workbook>
                """);
        writeZipEntry(zip, "xl/_rels/workbook.xml.rels", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
                </Relationships>
                """);
        writeZipEntry(zip, "xl/styles.xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                  <fonts count="1">
                    <font><sz val="11"/><color theme="1"/><name val="Calibri"/><family val="2"/></font>
                  </fonts>
                  <fills count="2">
                    <fill><patternFill patternType="none"/></fill>
                    <fill><patternFill patternType="gray125"/></fill>
                  </fills>
                  <borders count="1">
                    <border><left/><right/><top/><bottom/><diagonal/></border>
                  </borders>
                  <cellStyleXfs count="1">
                    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
                  </cellStyleXfs>
                  <cellXfs count="1">
                    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
                  </cellXfs>
                  <cellStyles count="1">
                    <cellStyle name="Normal" xfId="0" builtinId="0"/>
                  </cellStyles>
                </styleSheet>
                """);
        writeZipEntry(zip, "xl/worksheets/sheet1.xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                  <sheetData/>
                </worksheet>
                """);
    }

}
