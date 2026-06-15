import { useCallback, useRef, useState } from 'react';
import { message } from 'antd';
import type { OnlineDocument, OnlineDocumentPermission, OnlineDocumentPermissionGroup, OnlineDocumentPermissionUser } from '../../../api/onlineDocs';
import {
    listOnlineDocumentPermissions,
    saveOnlineDocumentPermissions,
    listOnlineDocumentPermissionGroups,
    searchOnlineDocumentPermissionUsers,
} from '../../../api/onlineDocs';

type UserOption = { value: number; label: string };

export interface UseDocumentPermissionsReturn {
    permissionDoc: OnlineDocument | null;
    permissionUserIds: number[];
    permissionOptions: UserOption[];
    permissionSearchValue: string;
    permissionGroups: OnlineDocumentPermissionGroup[];
    permissionLoading: boolean;
    permissionSaving: boolean;
    openPermissions: (doc: OnlineDocument) => Promise<void>;
    closePermissions: () => void;
    savePermissions: () => Promise<void>;
    setPermissionUserIds: (ids: number[]) => void;
    setPermissionSearchValue: (value: string) => void;
    searchPermissionUsers: (value: string, ownerUserId?: number, selectedUserIds?: number[]) => Promise<void>;
    applyPermissionGroup: (groupId: number) => void;
}

export function useDocumentPermissions(getUserOptions: (users: OnlineDocumentPermissionUser[], ownerUserId?: number) => UserOption[]): UseDocumentPermissionsReturn {
    const [permissionDoc, setPermissionDoc] = useState<OnlineDocument | null>(null);
    const [permissionUserIds, setPermissionUserIds] = useState<number[]>([]);
    const [permissionOptions, setPermissionOptions] = useState<UserOption[]>([]);
    const [permissionSearchValue, setPermissionSearchValue] = useState('');
    const [permissionGroups, setPermissionGroups] = useState<OnlineDocumentPermissionGroup[]>([]);
    const [permissionLoading, setPermissionLoading] = useState(false);
    const [permissionSaving, setPermissionSaving] = useState(false);
    const permissionSearchSeq = useRef(0);

    const searchPermissionUsers = useCallback(async (
        value: string,
        ownerUserId?: number,
        selectedUserIds?: number[],
    ) => {
        const searchSeq = permissionSearchSeq.current + 1;
        permissionSearchSeq.current = searchSeq;
        setPermissionLoading(true);
        const userIds = selectedUserIds ?? permissionUserIds;
        const owner = ownerUserId ?? permissionDoc?.userId;
        try {
            const users = await searchOnlineDocumentPermissionUsers(value);
            if (searchSeq !== permissionSearchSeq.current) return;
            setPermissionOptions(options => {
                const selectedOptions = options.filter(option => userIds.includes(option.value));
                const existingMap = new Map(selectedOptions.map(o => [o.value, o]));
                const nextOptions = getUserOptions(users, owner);
                nextOptions.forEach(o => { if (!existingMap.has(o.value)) existingMap.set(o.value, o); });
                return Array.from(existingMap.values());
            });
        } catch {
            message.error('用户搜索失败');
        } finally {
            if (searchSeq === permissionSearchSeq.current) {
                setPermissionLoading(false);
            }
        }
    }, [permissionUserIds, permissionDoc, getUserOptions]);

    const applyPermissionGroup = useCallback((groupId: number) => {
        const group = permissionGroups.find(item => item.id === groupId);
        if (!group) return;
        const groupOptions = getUserOptions(group.members, permissionDoc?.userId);
        const groupUserIds = groupOptions.map(option => option.value);
        setPermissionOptions(options => {
            const existingMap = new Map(options.map(o => [o.value, o]));
            groupOptions.forEach(o => { if (!existingMap.has(o.value)) existingMap.set(o.value, o); });
            return Array.from(existingMap.values());
        });
        setPermissionUserIds(userIds => Array.from(new Set([...userIds, ...groupUserIds])));
    }, [permissionGroups, permissionDoc, getUserOptions]);

    const openPermissions = useCallback(async (doc: OnlineDocument) => {
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
    }, [searchPermissionUsers]);

    const closePermissions = useCallback(() => {
        setPermissionDoc(null);
        setPermissionSearchValue('');
    }, []);

    const savePermissions = useCallback(async () => {
        if (!permissionDoc) return;
        setPermissionSaving(true);
        try {
            const permissions: OnlineDocumentPermission[] = await saveOnlineDocumentPermissions(
                permissionDoc.id,
                permissionUserIds,
            );
            setPermissionUserIds(permissions.map(item => item.userId));
            message.success('文档授权已更新');
            closePermissions();
        } catch {
            message.error('文档授权保存失败');
        } finally {
            setPermissionSaving(false);
        }
    }, [permissionDoc, permissionUserIds, closePermissions]);

    return {
        permissionDoc,
        permissionUserIds,
        permissionOptions,
        permissionSearchValue,
        permissionGroups,
        permissionLoading,
        permissionSaving,
        openPermissions,
        closePermissions,
        savePermissions,
        setPermissionUserIds,
        setPermissionSearchValue,
        searchPermissionUsers,
        applyPermissionGroup,
    };
}
