import { useCallback, useRef, useState } from 'react';
import { Modal, message } from 'antd';
import type { OnlineDocumentPermissionGroup, OnlineDocumentPermissionUser } from '../../../api/onlineDocs';
import {
    listOnlineDocumentPermissionGroups,
    createOnlineDocumentPermissionGroup,
    updateOnlineDocumentPermissionGroup,
    deleteOnlineDocumentPermissionGroup,
    searchOnlineDocumentPermissionUsers,
} from '../../../api/onlineDocs';

type UserOption = { value: number; label: string };

export interface UsePermissionGroupsReturn {
    groupManagerOpen: boolean;
    permissionGroups: OnlineDocumentPermissionGroup[];
    editingGroupId: number | null;
    groupName: string;
    groupDescription: string;
    groupUserIds: number[];
    groupOptions: UserOption[];
    groupSearchValue: string;
    groupLoading: boolean;
    groupSaving: boolean;
    openGroupManager: () => Promise<void>;
    closeGroupManager: () => void;
    editPermissionGroup: (group: OnlineDocumentPermissionGroup) => void;
    savePermissionGroup: () => Promise<void>;
    setGroupName: (name: string) => void;
    setGroupDescription: (desc: string) => void;
    setGroupUserIds: (ids: number[]) => void;
    setGroupSearchValue: (value: string) => void;
    searchGroupUsers: (value: string, selectedUserIds?: number[]) => Promise<void>;
    toGroupUserOptions: (users: OnlineDocumentPermissionUser[], ownerUserId?: number) => UserOption[];
}

export function usePermissionGroups(): UsePermissionGroupsReturn {
    const [groupManagerOpen, setGroupManagerOpen] = useState(false);
    const [permissionGroups, setPermissionGroups] = useState<OnlineDocumentPermissionGroup[]>([]);
    const [editingGroupId, setEditingGroupId] = useState<number | null>(null);
    const [groupName, setGroupName] = useState('');
    const [groupDescription, setGroupDescription] = useState('');
    const [groupUserIds, setGroupUserIds] = useState<number[]>([]);
    const [groupOptions, setGroupOptions] = useState<UserOption[]>([]);
    const [groupSearchValue, setGroupSearchValue] = useState('');
    const [groupLoading, setGroupLoading] = useState(false);
    const [groupSaving, setGroupSaving] = useState(false);
    const groupSearchSeq = useRef(0);

    const toGroupUserOptions = useCallback((users: OnlineDocumentPermissionUser[], ownerUserId?: number) =>
        users
            .map(user => ({ ...user, userId: Number(user.id) }))
            .filter(user => Number.isFinite(user.userId) && user.userId !== ownerUserId)
            .map(user => ({
                value: user.userId,
                label: `${user.name || `用户${user.userId}`}${user.empId ? `（${user.empId}）` : ''}`,
            })),
    []);

    const resetGroupEditor = useCallback(() => {
        setEditingGroupId(null);
        setGroupName('');
        setGroupDescription('');
        setGroupUserIds([]);
        setGroupOptions([]);
        setGroupSearchValue('');
    }, []);

    const searchGroupUsers = useCallback(async (value: string, selectedUserIds?: number[]) => {
        const userIds = selectedUserIds ?? groupUserIds;
        const searchSeq = groupSearchSeq.current + 1;
        groupSearchSeq.current = searchSeq;
        setGroupLoading(true);
        try {
            const users = await searchOnlineDocumentPermissionUsers(value);
            if (searchSeq !== groupSearchSeq.current) return;
            setGroupOptions(options => {
                const selectedOptions = options.filter(option => userIds.includes(option.value));
                const existingMap = new Map(selectedOptions.map(o => [o.value, o]));
                const nextOptions = toGroupUserOptions(users);
                nextOptions.forEach(o => { if (!existingMap.has(o.value)) existingMap.set(o.value, o); });
                return Array.from(existingMap.values());
            });
        } catch {
            message.error('用户搜索失败');
        } finally {
            if (searchSeq === groupSearchSeq.current) {
                setGroupLoading(false);
            }
        }
    }, [groupUserIds, toGroupUserOptions]);

    const openGroupManager = useCallback(async () => {
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
    }, [resetGroupEditor]);

    const closeGroupManager = useCallback(() => {
        setGroupManagerOpen(false);
        resetGroupEditor();
    }, [resetGroupEditor]);

    const editPermissionGroup = useCallback((group: OnlineDocumentPermissionGroup) => {
        setEditingGroupId(group.id);
        setGroupName(group.name);
        setGroupDescription(group.description || '');
        const options = toGroupUserOptions(group.members);
        setGroupOptions(options);
        setGroupUserIds(options.map(option => option.value));
        setGroupSearchValue('');
    }, [toGroupUserOptions]);

    const savePermissionGroup = useCallback(async () => {
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
    }, [groupName, groupDescription, groupUserIds, editingGroupId, resetGroupEditor]);

    return {
        groupManagerOpen,
        permissionGroups,
        editingGroupId,
        groupName,
        groupDescription,
        groupUserIds,
        groupOptions,
        groupSearchValue,
        groupLoading,
        groupSaving,
        openGroupManager,
        closeGroupManager,
        editPermissionGroup,
        savePermissionGroup,
        setGroupName,
        setGroupDescription,
        setGroupUserIds,
        setGroupSearchValue,
        searchGroupUsers,
        toGroupUserOptions,
    };
}
