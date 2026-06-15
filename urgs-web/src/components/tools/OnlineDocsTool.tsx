import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Dropdown, Empty, Input, Modal, Pagination, Select, Spin, Table, Upload, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import type { MenuProps, UploadProps } from 'antd';
import {
    Copy,
    Download,
    Edit3,
    FilePlus2,
    FileSpreadsheet,
    FileText,
    FileType,
    Grid3X3,
    LayoutList,
    MoreHorizontal,
    RefreshCcw,
    Search,
    Share2,
    SlidersHorizontal,
    Star,
    Trash2,
    UploadCloud,
    Users,
} from 'lucide-react';
import type { OnlineDocument, OnlineDocumentPage, OnlineDocumentPermission, OnlineDocumentPermissionUser } from '../../api/onlineDocs';
import {
    createOnlineDocumentPermissionGroup,
    createBlankOnlineDocument,
    createOnlineDocument,
    deleteOnlineDocument,
    deleteOnlineDocumentPermissionGroup,
    listOnlineDocumentPermissionGroups,
    listOnlineDocumentPermissions,
    listOnlineDocuments,
    listFavoriteDocuments,
    listSpaceDocuments,
    toggleFavorite,
    saveOnlineDocumentPermissions,
    searchOnlineDocumentPermissionUsers,
    updateOnlineDocument,
    updateOnlineDocumentPermissionGroup,
    uploadOnlineDocumentFile,
} from '../../api/onlineDocs';
import type { OnlineDocumentPermissionGroup } from '../../api/onlineDocs';
import OnlyOfficeEditorModal, { isOnlyOfficeSupported } from './OnlyOfficeEditorModal';

const PAGE_SIZE = 12;
type BlankDocumentType = 'word' | 'cell';
type TabKey = 'recent' | 'space' | 'favorite';
type UserOption = { value: number; label: string };

const blankTypeOptions: { value: BlankDocumentType; label: string; defaultTitle: string }[] = [
    { value: 'word', label: '文字文档', defaultTitle: '新建文档' },
    { value: 'cell', label: '电子表格', defaultTitle: '新建表格' },
];

// ---- helpers ----

const formatFileSize = (size?: number | null) => {
    if (!size) return '-';
    if (size < 1024) return `${size} B`;
    if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`;
    return `${(size / 1024 / 1024).toFixed(1)} MB`;
};

const formatTime = (value?: string) => {
    if (!value) return '-';
    return value.replace('T', ' ').slice(0, 16);
};

type FileTypeKey = 'word' | 'excel' | 'pdf' | 'other';

const getFileTypeKey = (fileName?: string): FileTypeKey => {
    if (!fileName) return 'other';
    const ext = fileName.split('.').pop()?.toLowerCase() || '';
    if (['doc', 'docx'].includes(ext)) return 'word';
    if (['xls', 'xlsx'].includes(ext)) return 'excel';
    if (ext === 'pdf') return 'pdf';
    return 'other';
};

const fileTypeConfig: Record<FileTypeKey, { icon: React.FC<{ size?: number }>; color: string; bg: string }> = {
    word: { icon: FileText, color: '#1677FF', bg: '#E6F4FF' },
    excel: { icon: FileSpreadsheet, color: '#52C41A', bg: '#F6FFED' },
    pdf: { icon: FileType, color: '#FF4D4F', bg: '#FFF1F0' },
    other: { icon: FileText, color: '#8C8C8C', bg: '#FAFAFA' },
};

const mergeUserOptions = (current: UserOption[], next: UserOption[]) => {
    const optionMap = new Map<number, UserOption>();
    [...current, ...next].forEach(option => optionMap.set(option.value, option));
    return Array.from(optionMap.values());
};

// ---- component ----

const OnlineDocsTool: React.FC = () => {
    // data
    const [documents, setDocuments] = useState<OnlineDocument[]>([]);
    const [keyword, setKeyword] = useState('');
    const [page, setPage] = useState(1);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);

    // space & favorite state
    const [activeSpaceType, setActiveSpaceType] = useState<'personal' | 'shared' | 'all'>('all');

    // editor & modals
    const [editorDoc, setEditorDoc] = useState<OnlineDocument | null>(null);
    const [renamingDoc, setRenamingDoc] = useState<OnlineDocument | null>(null);
    const [renameValue, setRenameValue] = useState('');
    const [createOpen, setCreateOpen] = useState(false);
    const [createTitle, setCreateTitle] = useState('新建文档');
    const [createType, setCreateType] = useState<BlankDocumentType>('word');
    const [creating, setCreating] = useState(false);
    const [permissionDoc, setPermissionDoc] = useState<OnlineDocument | null>(null);
    const [permissionUserIds, setPermissionUserIds] = useState<number[]>([]);
    const [permissionOptions, setPermissionOptions] = useState<UserOption[]>([]);
    const [permissionSearchValue, setPermissionSearchValue] = useState('');
    const [permissionGroups, setPermissionGroups] = useState<OnlineDocumentPermissionGroup[]>([]);
    const [permissionLoading, setPermissionLoading] = useState(false);
    const [permissionSaving, setPermissionSaving] = useState(false);
    const permissionSearchSeq = useRef(0);
    const [groupManagerOpen, setGroupManagerOpen] = useState(false);
    const [editingGroupId, setEditingGroupId] = useState<number | null>(null);
    const [groupName, setGroupName] = useState('');
    const [groupDescription, setGroupDescription] = useState('');
    const [groupUserIds, setGroupUserIds] = useState<number[]>([]);
    const [groupOptions, setGroupOptions] = useState<UserOption[]>([]);
    const [groupSearchValue, setGroupSearchValue] = useState('');
    const [groupLoading, setGroupLoading] = useState(false);
    const [groupSaving, setGroupSaving] = useState(false);
    const groupSearchSeq = useRef(0);

    // ui state
    const [activeTab, setActiveTab] = useState<TabKey>('recent');
    const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');
    const [filterType, setFilterType] = useState<string>('all');

    // ---- data loading ----

    const loadDocuments = useCallback(async () => {
        setLoading(true);
        try {
            // 抽取通用查询参数，避免三个分支重复
            const baseParams = {
                keyword: keyword || undefined,
                fileType: filterType === 'all' ? undefined : filterType,
                page,
                size: PAGE_SIZE,
            };
            const result: OnlineDocumentPage<OnlineDocument> = await (() => {
                switch (activeTab) {
                    case 'recent':
                        return listOnlineDocuments(baseParams);
                    case 'favorite':
                        return listFavoriteDocuments(baseParams);
                    case 'space':
                        return listSpaceDocuments({ ...baseParams, spaceType: activeSpaceType });
                }
            })();
            setDocuments(result.records || []);
            setTotal(result.total || 0);
        } catch {
            message.error('在线文档加载失败');
        } finally {
            setLoading(false);
        }
    }, [keyword, page, activeTab, filterType, activeSpaceType]);

    useEffect(() => {
        loadDocuments();
    }, [loadDocuments]);

    // ---- actions ----

    const handleUpload: UploadProps['customRequest'] = async (options) => {
        const file = options.file as File;
        const extension = file.name.split('.').pop()?.toLowerCase() || '';
        if (!['doc', 'docx', 'xls', 'xlsx', 'pdf'].includes(extension)) {
            message.warning('仅支持 doc、docx、xls、xlsx、pdf 文件');
            options.onError?.(new Error('不支持的文件类型'));
            return;
        }
        try {
            const uploaded = await uploadOnlineDocumentFile(file);
            await createOnlineDocument({
                title: uploaded.name || file.name,
                fileName: uploaded.name || file.name,
                fileUrl: uploaded.url,
                fileSize: file.size,
            });
            message.success('在线文档已上传');
            options.onSuccess?.(uploaded);
            setPage(1);
            loadDocuments();
        } catch (error) {
            options.onError?.(error as Error);
            message.error('在线文档上传失败');
        }
    };

    const handleSearch = (value: string) => {
        setKeyword(value.trim());
        setPage(1);
        setFilterType('all');
    };

    const handleDownload = (doc: OnlineDocument) => {
        window.open(doc.fileUrl, '_blank');
    };

    const handleDelete = (doc: OnlineDocument) => {
        Modal.confirm({
            title: '删除在线文档',
            content: `确认删除「${doc.title}」吗？`,
            okText: '删除',
            okButtonProps: { danger: true },
            cancelText: '取消',
            onOk: async () => {
                await deleteOnlineDocument(doc.id);
                message.success('在线文档已删除');
                loadDocuments();
            },
        });
    };

    const toUserOptions = (users: OnlineDocumentPermissionUser[], ownerUserId?: number) =>
        users
            .map(user => ({ ...user, userId: Number(user.id) }))
            .filter(user => Number.isFinite(user.userId) && user.userId !== ownerUserId)
            .map(user => ({
                value: user.userId,
                label: `${user.name || `用户${user.userId}`}${user.empId ? `（${user.empId}）` : ''}`,
            }));

    const searchPermissionUsers = async (
        value: string,
        ownerUserId = permissionDoc?.userId,
        selectedUserIds = permissionUserIds,
    ) => {
        const searchSeq = permissionSearchSeq.current + 1;
        permissionSearchSeq.current = searchSeq;
        setPermissionLoading(true);
        try {
            const users = await searchOnlineDocumentPermissionUsers(value);
            if (searchSeq !== permissionSearchSeq.current) return;
            setPermissionOptions(options => {
                const selectedOptions = options.filter(option => selectedUserIds.includes(option.value));
                return mergeUserOptions(selectedOptions, toUserOptions(users, ownerUserId));
            });
        } catch {
            message.error('用户搜索失败');
        } finally {
            if (searchSeq === permissionSearchSeq.current) {
                setPermissionLoading(false);
            }
        }
    };

    const applyPermissionGroup = (groupId: number) => {
        const group = permissionGroups.find(item => item.id === groupId);
        if (!group) return;

        const groupOptions = toUserOptions(group.members, permissionDoc?.userId);
        const groupUserIds = groupOptions.map(option => option.value);
        setPermissionOptions(options => mergeUserOptions(options, groupOptions));
        setPermissionUserIds(userIds => Array.from(new Set([...userIds, ...groupUserIds])));
    };

    const searchGroupUsers = async (value: string, selectedUserIds = groupUserIds) => {
        const searchSeq = groupSearchSeq.current + 1;
        groupSearchSeq.current = searchSeq;
        setGroupLoading(true);
        try {
            const users = await searchOnlineDocumentPermissionUsers(value);
            if (searchSeq !== groupSearchSeq.current) return;
            setGroupOptions(options => {
                const selectedOptions = options.filter(option => selectedUserIds.includes(option.value));
                return mergeUserOptions(selectedOptions, toUserOptions(users));
            });
        } catch {
            message.error('用户搜索失败');
        } finally {
            if (searchSeq === groupSearchSeq.current) {
                setGroupLoading(false);
            }
        }
    };

    const resetGroupEditor = () => {
        setEditingGroupId(null);
        setGroupName('');
        setGroupDescription('');
        setGroupUserIds([]);
        setGroupOptions([]);
        setGroupSearchValue('');
    };

    const openGroupManager = async () => {
        setGroupManagerOpen(true);
        resetGroupEditor();
        setGroupLoading(true);
        try {
            const groups = await listOnlineDocumentPermissionGroups();
            setPermissionGroups(groups);
        } catch {
            message.error('授权组加载失败');
        } finally {
            setGroupLoading(false);
        }
    };

    const editPermissionGroup = (group: OnlineDocumentPermissionGroup) => {
        setEditingGroupId(group.id);
        setGroupName(group.name);
        setGroupDescription(group.description || '');
        const options = toUserOptions(group.members);
        setGroupOptions(options);
        setGroupUserIds(options.map(option => option.value));
        setGroupSearchValue('');
    };

    const savePermissionGroup = async () => {
        const name = groupName.trim();
        if (!name) {
            message.warning('请输入授权组名称');
            return;
        }
        setGroupSaving(true);
        try {
            const payload = {
                name,
                description: groupDescription.trim() || undefined,
                userIds: groupUserIds,
            };
            const group = editingGroupId
                ? await updateOnlineDocumentPermissionGroup(editingGroupId, payload)
                : await createOnlineDocumentPermissionGroup(payload);
            setPermissionGroups(groups => [group, ...groups.filter(item => item.id !== group.id)]);
            resetGroupEditor();
            message.success('授权组已保存');
        } catch {
            message.error('授权组保存失败');
        } finally {
            setGroupSaving(false);
        }
    };

    const removePermissionGroup = (group: OnlineDocumentPermissionGroup) => {
        Modal.confirm({
            title: '删除授权组',
            content: `确认删除「${group.name}」吗？`,
            okText: '删除',
            okButtonProps: { danger: true },
            cancelText: '取消',
            onOk: async () => {
                await deleteOnlineDocumentPermissionGroup(group.id);
                setPermissionGroups(groups => groups.filter(item => item.id !== group.id));
                if (editingGroupId === group.id) {
                    resetGroupEditor();
                }
                message.success('授权组已删除');
            },
        });
    };

    const openPermissions = async (doc: OnlineDocument) => {
        setPermissionDoc(doc);
        setPermissionSearchValue('');
        setPermissionLoading(true);
        try {
            const [permissions, groups] = await Promise.all([
                listOnlineDocumentPermissions(doc.id),
                listOnlineDocumentPermissionGroups(),
            ]);
            const selectedUserIds = permissions.map(item => item.userId);
            setPermissionUserIds(selectedUserIds);
            setPermissionGroups(groups);
            setPermissionOptions(permissions.map(item => ({
                value: item.userId,
                label: `${item.userName || `用户${item.userId}`}${item.empId ? `（${item.empId}）` : ''}`,
            })));
            await searchPermissionUsers('', doc.userId, selectedUserIds);
        } catch {
            message.error('文档授权加载失败');
        } finally {
            setPermissionLoading(false);
        }
    };

    const savePermissions = async () => {
        if (!permissionDoc) return;
        setPermissionSaving(true);
        try {
            const permissions: OnlineDocumentPermission[] = await saveOnlineDocumentPermissions(
                permissionDoc.id,
                permissionUserIds,
            );
            setPermissionUserIds(permissions.map(item => item.userId));
            setPermissionSearchValue('');
            setPermissionDoc(null);
            message.success('文档授权已更新');
            loadDocuments();
        } catch {
            message.error('文档授权保存失败');
        } finally {
            setPermissionSaving(false);
        }
    };

    const openRename = (doc: OnlineDocument) => {
        setRenamingDoc(doc);
        setRenameValue(doc.title);
    };

    const openCreate = () => {
        setCreateType('word');
        setCreateTitle('新建文档');
        setCreateOpen(true);
    };

    const handleCreateTypeChange = (value: BlankDocumentType) => {
        setCreateType(value);
        const option = blankTypeOptions.find(item => item.value === value);
        setCreateTitle(option?.defaultTitle || '新建文档');
    };

    const saveCreate = async () => {
        const title = createTitle.trim();
        if (!title) {
            message.warning('请输入文档名称');
            return;
        }
        setCreating(true);
        try {
            const doc = await createBlankOnlineDocument({
                title,
                documentType: createType,
            });
            message.success('在线文档已新建');
            setCreateOpen(false);
            if (page === 1) {
                await loadDocuments();
            } else {
                setPage(1);
            }
            setEditorDoc(doc);
        } catch {
            message.error('在线文档新建失败');
        } finally {
            setCreating(false);
        }
    };

    const saveRename = async () => {
        if (!renamingDoc) return;
        const nextTitle = renameValue.trim();
        if (!nextTitle) {
            message.warning('请输入文档名称');
            return;
        }
        await updateOnlineDocument(renamingDoc.id, { title: nextTitle });
        message.success('文档名称已更新');
        setRenamingDoc(null);
        loadDocuments();
    };

    const handleCopyLink = (doc: OnlineDocument) => {
        navigator.clipboard.writeText(doc.fileUrl).then(() => {
            message.success('链接已复制');
        }).catch(() => {
            message.error('复制失败');
        });
    };

    const handleToggleFavorite = async (doc: OnlineDocument) => {
        // 计算目标状态用于 UI 反馈（API 完成后状态会翻转）
        const willFavorite = !doc.favorite;
        try {
            await toggleFavorite(doc.id);
            setDocuments(docs => docs.map(d => d.id === doc.id ? { ...d, favorite: willFavorite } : d));
            message.success(willFavorite ? '已收藏' : '已取消收藏');
            // 在收藏 Tab 取消收藏时，从当前列表中移除该文档
            if (activeTab === 'favorite' && !willFavorite && total > 1) {
                setDocuments(docs => docs.filter(d => d.id !== doc.id));
                setTotal(prev => prev - 1);
            }
        } catch {
            message.error('操作失败');
        }
    };

    const getActionItems = (doc: OnlineDocument): MenuProps['items'] => {
        const isOwner = doc.canManagePermissions === true;
        const items: MenuProps['items'] = [
            { key: 'edit', icon: <Edit3 size={14} />, label: '在线打开', onClick: () => setEditorDoc(doc) },
            { key: 'download', icon: <Download size={14} />, label: '下载', onClick: () => handleDownload(doc) },
        ];

        // 只有所有者才能重命名、授权、删除
        if (isOwner) {
            items.push(
                { key: 'rename', icon: <FileText size={14} />, label: '重命名', onClick: () => openRename(doc) },
                { type: 'divider' },
                { key: 'share', icon: <Share2 size={14} />, label: '授权', onClick: () => openPermissions(doc) },
            );
        }

        // 所有人都有收藏功能
        items.push(
            { type: 'divider' },
            {
                key: 'favorite',
                icon: <Star size={14} fill={doc.favorite ? '#FAAD14' : 'none'} stroke={doc.favorite ? '#FAAD14' : undefined} />,
                label: doc.favorite ? '取消收藏' : '收藏',
                onClick: () => handleToggleFavorite(doc),
            },
        );

        // 只有所有者才能删除
        if (isOwner) {
            items.push(
                { type: 'divider' },
                { key: 'delete', icon: <Trash2 size={14} />, label: '删除', danger: true, onClick: () => handleDelete(doc) },
            );
        }

        return items;
    };

    // ---- quick access (始终展示近期文档，与当前 tab 无关) ----

    const [recentDocs, setRecentDocs] = useState<OnlineDocument[]>([]);

    const loadRecentDocs = useCallback(async () => {
        try {
            const result = await listOnlineDocuments({ page: 1, size: 4 });
            setRecentDocs(result.records || []);
        } catch {
            // 快速访问加载失败不阻塞用户操作
        }
    }, []);

    // 首次加载 + 每次文档列表刷新后重新加载
    useEffect(() => {
        loadRecentDocs();
    }, [loadRecentDocs]);

    // 文档增删改操作后同步刷新快速访问
    useEffect(() => {
        if (!loading) {
            loadRecentDocs();
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [documents]);

    const supportedCount = useMemo(
        () => documents.filter(doc => isOnlyOfficeSupported(doc.fileName || doc.title)).length,
        [documents],
    );

    // ---- table columns ----

    const columns: ColumnsType<OnlineDocument> = useMemo(() => [
        {
            title: '名称',
            dataIndex: 'title',
            key: 'name',
            width: '35%',
            sorter: (a, b) => a.title.localeCompare(b.title),
            render: (_: string, record: OnlineDocument) => {
                const ft = fileTypeConfig[getFileTypeKey(record.fileName)];
                const Icon = ft.icon;
                return (
                    <div
                        className="flex items-center gap-3 cursor-pointer group/name"
                        onClick={() => setEditorDoc(record)}
                    >
                        <span
                            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md"
                            style={{ backgroundColor: ft.bg, color: ft.color }}
                        >
                            <Icon size={18} />
                        </span>
                        <span className="text-sm font-medium text-gray-900 truncate group-hover/name:text-[#1677FF] transition-colors">
                            {record.title}
                        </span>
                        {record.favorite && (
                            <Star size={12} fill="#FAAD14" stroke="#FAAD14" className="shrink-0" />
                        )}
                    </div>
                );
            },
        },
        {
            title: '所有者',
            dataIndex: 'userId',
            key: 'owner',
            width: '12%',
            render: (_: unknown, record: OnlineDocument) => (
                <span className="text-sm text-gray-500">
                    {record.canManagePermissions ? '我' : record.ownerName || `用户${record.userId}`}
                </span>
            ),
        },
        {
            title: '位置',
            dataIndex: 'fileName',
            key: 'location',
            width: '18%',
            render: (_: string, record: OnlineDocument) => (
                <span className="text-sm text-gray-400 truncate block max-w-[200px]">{record.fileName || record.title}</span>
            ),
        },
        {
            title: '最近查看',
            dataIndex: 'updateTime',
            key: 'updateTime',
            width: '16%',
            sorter: (a, b) => new Date(a.updateTime).getTime() - new Date(b.updateTime).getTime(),
            defaultSortOrder: 'descend',
            render: (value: string) => (
                <span className="text-sm text-gray-400">{formatTime(value)}</span>
            ),
        },
        {
            title: '文件大小',
            dataIndex: 'fileSize',
            key: 'fileSize',
            width: '10%',
            align: 'right',
            sorter: (a, b) => (a.fileSize || 0) - (b.fileSize || 0),
            render: (value: number | null) => (
                <span className="text-sm text-gray-400">{formatFileSize(value)}</span>
            ),
        },
        {
            title: '',
            key: 'actions',
            width: '9%',
            align: 'right',
            render: (_: unknown, record: OnlineDocument) => (
                <div className="flex items-center justify-end gap-1 opacity-0 group-hover/row:opacity-100 transition-opacity">
                    <button
                        onClick={(e) => { e.stopPropagation(); handleCopyLink(record); }}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-[#1677FF]"
                        title="复制链接"
                    >
                        <Copy size={14} />
                    </button>
                    <Dropdown
                        menu={{
                            items: getActionItems(record),
                        }}
                        trigger={['click']}
                    >
                        <button
                            onClick={(e) => e.stopPropagation()}
                            className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                            title="更多操作"
                        >
                            <MoreHorizontal size={14} />
                        </button>
                    </Dropdown>
                </div>
            ),
        },
    ], []);

    // ---- grid view card ----

    const renderGridCard = (doc: OnlineDocument) => {
        const ft = fileTypeConfig[getFileTypeKey(doc.fileName)];
        const Icon = ft.icon;
        return (
            <div
                key={doc.id}
                onClick={() => setEditorDoc(doc)}
                className="group/card flex flex-col rounded-xl border border-gray-100 bg-white p-4 transition-all hover:border-[#1677FF]/30 hover:shadow-md cursor-pointer"
            >
                {/* file icon area */}
                <div
                    className="flex items-center justify-center h-28 rounded-lg mb-3"
                    style={{ backgroundColor: ft.bg }}
                >
                    <span style={{ color: ft.color }}>
                        <Icon size={40} />
                    </span>
                </div>
                {/* file name */}
                <div className="flex items-center gap-1 text-sm font-medium text-gray-900 truncate" title={doc.title}>
                    <span className="truncate">{doc.title}</span>
                    {doc.favorite && (
                        <Star size={12} fill="#FAAD14" stroke="#FAAD14" className="shrink-0" />
                    )}
                </div>
                {/* meta */}
                <div className="text-xs text-gray-400 mt-1">
                    {formatTime(doc.updateTime)}
                </div>
                {/* actions */}
                <div className="flex items-center gap-1 mt-3 opacity-0 group-hover/card:opacity-100 transition-opacity">
                    <button
                        onClick={(e) => { e.stopPropagation(); handleCopyLink(doc); }}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-[#1677FF]"
                        title="复制链接"
                    >
                        <Copy size={14} />
                    </button>
                    <Dropdown
                        menu={{
                            items: getActionItems(doc),
                        }}
                        trigger={['click']}
                    >
                        <button
                            onClick={(e) => e.stopPropagation()}
                            className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                            title="更多操作"
                        >
                            <MoreHorizontal size={14} />
                        </button>
                    </Dropdown>
                </div>
            </div>
        );
    };

    // ---- tab content ----

    const renderTabContent = () => {
        if (documents.length === 0 && !loading) {
            return (
                <div className="flex items-center justify-center h-[420px]">
                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无在线文档" />
                </div>
            );
        }

        if (viewMode === 'grid') {
            return (
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 p-4">
                    {documents.map(doc => renderGridCard(doc))}
                </div>
            );
        }

        return (
            <Table<OnlineDocument>
                rowKey="id"
                columns={columns}
                dataSource={documents}
                loading={loading}
                pagination={false}
                showHeader={true}
                size="middle"
                className="online-docs-table"
                rowClassName="group/row"
                locale={{ emptyText: '暂无文档' }}
                onRow={(record) => ({
                    onDoubleClick: () => setEditorDoc(record),
                    style: { cursor: 'pointer' },
                })}
            />
        );
    };

    // ---- tabs config ----

    const tabs: { key: TabKey; label: string }[] = [
        { key: 'recent', label: '最近' },
        { key: 'space', label: '空间' },
        { key: 'favorite', label: '收藏' },
    ];

    // ---- render ----

    return (
        <div className="flex h-full flex-col bg-white">
            {/* ===== Quick Access Bar ===== */}
            {recentDocs.length > 0 && (
                <div className="shrink-0 border-b border-gray-100 bg-white px-6 py-4">
                    <div className="text-xs font-medium text-gray-400 mb-3 uppercase tracking-wide">快速访问</div>
                    <div className="flex flex-wrap gap-3">
                        {recentDocs.map(doc => {
                            const ft = fileTypeConfig[getFileTypeKey(doc.fileName)];
                            const Icon = ft.icon;
                            return (
                                <button
                                    key={doc.id}
                                    onClick={() => setEditorDoc(doc)}
                                    className="flex items-center gap-2.5 rounded-lg border border-gray-200 bg-white px-3.5 py-2.5 text-sm transition-all hover:border-[#1677FF]/30 hover:shadow-sm hover:-translate-y-0.5"
                                    title={doc.title}
                                >
                                    <span
                                        className="flex h-6 w-6 shrink-0 items-center justify-center rounded"
                                        style={{ backgroundColor: ft.bg, color: ft.color }}
                                    >
                                        <Icon size={14} />
                                    </span>
                                    <span className="flex items-center gap-1 text-gray-700 max-w-[160px] truncate text-left">
                                        <span className="truncate">{doc.title}</span>
                                        {doc.favorite && (
                                            <Star size={10} fill="#FAAD14" stroke="#FAAD14" className="shrink-0" />
                                        )}
                                    </span>
                                </button>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* ===== Tab Navigation + Toolbar ===== */}
            <div className="flex shrink-0 items-center justify-between border-b border-gray-100 bg-white px-6">
                {/* Tabs */}
                <div className="flex items-center gap-0 relative">
                       {tabs.map(tab => (
                        <button
                            key={tab.key}
                            onClick={() => {
                                setActiveTab(tab.key);
                                setPage(1);
                                setFilterType('all');
                                // 离开空间 Tab 时重置空间类型，避免下次进入时仍保留上次选择
                                if (tab.key === 'space') {
                                    setActiveSpaceType('all');
                                }
                            }}
                            className={`relative px-5 py-3 text-sm font-medium transition-colors ${
                                activeTab === tab.key
                                    ? 'text-[#1677FF]'
                                    : 'text-gray-500 hover:text-gray-700'
                            }`}
                        >
                            {tab.label}
                            {activeTab === tab.key && (
                                <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-5 h-0.5 bg-[#1677FF] rounded-full" />
                            )}
                        </button>
                    ))}

                    {/* Space Type Sub-tabs */}
                    {activeTab === 'space' && (
                        <div className="ml-4 flex items-center gap-1 pl-4 border-l border-gray-200">
                            {[
                                { key: 'all', label: '全部' },
                                { key: 'personal', label: '个人' },
                                { key: 'shared', label: '共享' },
                            ].map((space) => (
                                <button
                                    key={space.key}
                                    onClick={() => setActiveSpaceType(space.key as typeof activeSpaceType)}
                                    className={`px-3 py-1 text-xs rounded-md transition-colors ${
                                        activeSpaceType === space.key
                                            ? 'bg-[#E6F4FF] text-[#1677FF]'
                                            : 'text-gray-500 hover:bg-gray-50'
                                    }`}
                                >
                                    {space.label}
                                </button>
                            ))}
                        </div>
                    )}
                </div>

                {/* Toolbar */}
                <div className="flex items-center gap-2">
                    <Input.Search
                        allowClear
                        className="w-56"
                        placeholder="搜索在线文档"
                        prefix={<Search size={14} className="text-gray-400" />}
                        onSearch={handleSearch}
                        size="small"
                    />
                    <button
                        onClick={loadDocuments}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                        title="刷新"
                    >
                        <RefreshCcw size={14} />
                    </button>
                    <button
                        onClick={openGroupManager}
                        className="flex h-7 items-center gap-1.5 rounded-md border border-slate-200 bg-white px-2.5 text-xs font-medium text-slate-600 transition-colors hover:border-slate-300 hover:bg-slate-50"
                    >
                        <Users size={14} />
                        授权组
                    </button>
                    <button
                        onClick={openCreate}
                        className="flex h-7 items-center gap-1.5 rounded-md border border-[#1677FF]/20 bg-[#E6F4FF] px-2.5 text-xs font-medium text-[#1677FF] transition-colors hover:border-[#1677FF]/40 hover:bg-[#BAE0FF]"
                    >
                        <FilePlus2 size={14} />
                        新建
                    </button>
                    <Upload
                        customRequest={handleUpload}
                        showUploadList={false}
                        accept=".doc,.docx,.xls,.xlsx,.pdf"
                    >
                        <button className="flex h-7 items-center gap-1.5 rounded-md bg-[#1677FF] px-2.5 text-xs font-medium text-white transition-colors hover:bg-[#4096FF]">
                            <UploadCloud size={14} />
                            上传
                        </button>
                    </Upload>

                    {/* Divider */}
                    <span className="w-px h-5 bg-gray-200 mx-1" />

                    {/* View mode toggle */}
                    <button
                        onClick={() => setViewMode(viewMode === 'list' ? 'grid' : 'list')}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                        title={viewMode === 'list' ? '切换为网格视图' : '切换为列表视图'}
                    >
                        {viewMode === 'list' ? <LayoutList size={15} /> : <Grid3X3 size={15} />}
                    </button>

                    {/* Filter */}
                    <Dropdown
                        menu={{
                            selectedKeys: [filterType],
                            onClick: ({ key }) => {
                                setFilterType(key);
                                setPage(1);
                            },
                            items: [
                                { key: 'all', label: '全部文档' },
                                { key: 'word', label: '文字文档' },
                                { key: 'excel', label: '电子表格' },
                                { key: 'pdf', label: 'PDF 文档' },
                            ],
                        }}
                        trigger={['click']}
                    >
                        <button className="flex h-7 items-center gap-1 rounded-md border border-gray-200 bg-white px-2 text-xs text-gray-500 transition-colors hover:border-gray-300 hover:text-gray-700">
                            <SlidersHorizontal size={13} />
                            筛选
                        </button>
                    </Dropdown>
                </div>
            </div>

            {/* ===== Info Bar ===== */}
            <div className="flex shrink-0 items-center justify-between bg-[#FAFAFA] px-6 py-1.5 text-xs text-gray-400 border-b border-gray-100">
                <span>共 {total} 个文档</span>
                <span>{supportedCount} 个支持在线编辑</span>
            </div>

            {/* ===== Main Content ===== */}
            <Spin spinning={loading}>
                <div className="flex-1 min-h-0 overflow-auto px-6 py-3">
                    {renderTabContent()}
                </div>
            </Spin>

            {/* ===== Pagination ===== */}
            {total > PAGE_SIZE && (
                <div className="flex shrink-0 justify-end border-t border-gray-100 bg-white px-6 py-3">
                    <Pagination
                        current={page}
                        pageSize={PAGE_SIZE}
                        total={total}
                        showSizeChanger={false}
                        showQuickJumper={false}
                        onChange={setPage}
                        size="small"
                    />
                </div>
            )}

            {/* ===== Modals ===== */}

            {/* Rename Modal */}
            <Modal
                open={!!renamingDoc}
                title="重命名在线文档"
                okText="保存"
                cancelText="取消"
                onOk={saveRename}
                onCancel={() => setRenamingDoc(null)}
                destroyOnHidden
            >
                <Input
                    value={renameValue}
                    maxLength={200}
                    showCount
                    autoFocus
                    onChange={(event) => setRenameValue(event.target.value)}
                    onPressEnter={saveRename}
                />
            </Modal>

            {/* Create Modal */}
            <Modal
                open={createOpen}
                title="新建在线文档"
                okText="新建"
                cancelText="取消"
                confirmLoading={creating}
                onOk={saveCreate}
                onCancel={() => setCreateOpen(false)}
                destroyOnHidden
            >
                <div className="space-y-4">
                    <div>
                        <label className="mb-1 block text-xs font-bold text-slate-500">类型</label>
                        <Select
                            className="w-full"
                            value={createType}
                            options={blankTypeOptions.map(item => ({ value: item.value, label: item.label }))}
                            onChange={handleCreateTypeChange}
                        />
                    </div>
                    <div>
                        <label className="mb-1 block text-xs font-bold text-slate-500">名称</label>
                        <Input
                            value={createTitle}
                            maxLength={200}
                            showCount
                            autoFocus
                            onChange={(event) => setCreateTitle(event.target.value)}
                            onPressEnter={saveCreate}
                        />
                    </div>
                </div>
            </Modal>

            {/* Permission Group Manager */}
            <Modal
                open={groupManagerOpen}
                title="我的授权组"
                okText="保存组"
                cancelText="关闭"
                confirmLoading={groupSaving}
                onOk={savePermissionGroup}
                onCancel={() => {
                    setGroupManagerOpen(false);
                    resetGroupEditor();
                }}
                width={860}
                destroyOnHidden
            >
                <div className="grid min-h-[420px] grid-cols-[260px_1fr] gap-4">
                    <div className="border-r border-slate-100 pr-4">
                        <div className="mb-3 flex items-center justify-between">
                            <span className="text-xs font-bold text-slate-500">授权组</span>
                            <button
                                type="button"
                                onClick={resetGroupEditor}
                                className="rounded-md px-2 py-1 text-xs font-medium text-[#1677FF] hover:bg-[#E6F4FF]"
                            >
                                新建
                            </button>
                        </div>
                        <div className="space-y-1">
                            {permissionGroups.map(group => (
                                <button
                                    key={group.id}
                                    type="button"
                                    onClick={() => editPermissionGroup(group)}
                                    className={`flex w-full items-center justify-between rounded-md px-3 py-2 text-left text-sm transition-colors ${
                                        editingGroupId === group.id
                                            ? 'bg-[#E6F4FF] text-[#1677FF]'
                                            : 'text-slate-700 hover:bg-slate-50'
                                    }`}
                                >
                                    <span className="min-w-0 truncate">{group.name}</span>
                                    <span className="ml-2 shrink-0 text-xs text-slate-400">{group.memberCount}人</span>
                                </button>
                            ))}
                            {permissionGroups.length === 0 && (
                                <div className="py-10 text-center text-sm text-slate-400">
                                    暂无授权组
                                </div>
                            )}
                        </div>
                    </div>
                    <div className="space-y-4">
                        <div>
                            <label className="mb-1 block text-xs font-bold text-slate-500">组名称</label>
                            <Input
                                value={groupName}
                                maxLength={100}
                                placeholder="例如：EAST核对组"
                                onChange={(event) => setGroupName(event.target.value)}
                            />
                        </div>
                        <div>
                            <label className="mb-1 block text-xs font-bold text-slate-500">描述</label>
                            <Input
                                value={groupDescription}
                                maxLength={500}
                                placeholder="可选"
                                onChange={(event) => setGroupDescription(event.target.value)}
                            />
                        </div>
                        <div>
                            <label className="mb-1 block text-xs font-bold text-slate-500">成员</label>
                            <Select
                                mode="multiple"
                                allowClear
                                showSearch
                                className="w-full"
                                placeholder="搜索用户加入授权组"
                                value={groupUserIds}
                                searchValue={groupSearchValue}
                                options={groupOptions}
                                loading={groupLoading}
                                filterOption={false}
                                onSearch={(value) => {
                                    setGroupSearchValue(value);
                                    searchGroupUsers(value);
                                }}
                                onChange={(value) => {
                                    setGroupUserIds(value);
                                    setGroupSearchValue('');
                                    searchGroupUsers('', value);
                                }}
                            />
                        </div>
                        <div className="flex items-center justify-between border-t border-slate-100 pt-3">
                            <span className="text-xs text-slate-400">
                                保存后可在文档授权弹窗中选择该组，组成员会展开为具体授权人员。
                            </span>
                            {editingGroupId && (
                                <button
                                    type="button"
                                    onClick={() => {
                                        const group = permissionGroups.find(item => item.id === editingGroupId);
                                        if (group) removePermissionGroup(group);
                                    }}
                                    className="rounded-md px-2 py-1 text-xs font-medium text-red-600 hover:bg-red-50"
                                >
                                    删除组
                                </button>
                            )}
                        </div>
                    </div>
                </div>
            </Modal>

            {/* Permission Modal */}
            <Modal
                open={!!permissionDoc}
                title="文档授权"
                okText="保存"
                cancelText="取消"
                confirmLoading={permissionSaving}
                onOk={savePermissions}
                onCancel={() => {
                    setPermissionDoc(null);
                    setPermissionSearchValue('');
                }}
                destroyOnHidden
            >
                <div className="space-y-3">
                    <div className="text-sm font-medium text-gray-900 truncate">
                        {permissionDoc?.title}
                    </div>
                    <div>
                        <label className="mb-1 block text-xs font-bold text-slate-500">授权组</label>
                        <Select
                            allowClear
                            showSearch
                            className="w-full"
                            placeholder="选择授权组快速添加成员"
                            value={undefined}
                            options={permissionGroups.map(group => ({
                                value: group.id,
                                label: `${group.name}（${group.memberCount}人）`,
                            }))}
                            filterOption={(input, option) =>
                                String(option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                            }
                            onSelect={applyPermissionGroup}
                        />
                    </div>
                    <Select
                        mode="multiple"
                        allowClear
                        showSearch
                        className="w-full"
                        placeholder="搜索用户并授权"
                        value={permissionUserIds}
                        searchValue={permissionSearchValue}
                        options={permissionOptions}
                        loading={permissionLoading}
                        filterOption={false}
                        onSearch={(value) => {
                            setPermissionSearchValue(value);
                            searchPermissionUsers(value);
                        }}
                        onChange={(value) => {
                            setPermissionUserIds(value);
                            setPermissionSearchValue('');
                            searchPermissionUsers('', permissionDoc?.userId, value);
                        }}
                    />
                </div>
            </Modal>

            {/* OnlyOffice Editor */}
            <OnlyOfficeEditorModal
                open={!!editorDoc}
                document={editorDoc}
                onClose={() => setEditorDoc(null)}
                onSaved={loadDocuments}
                onDownload={handleDownload}
            />
        </div>
    );
};

export default OnlineDocsTool;
