import type { InfrastructureAsset, InfrastructureSystemManual } from '@/api/ops';
import type { SsoConfig } from '@/api/version';
import type { AssetFilters, AssetStatus, SystemOption } from './types';

export const statusLabels: Record<AssetStatus, string> = {
    active: '运行中',
    maintenance: '维护中',
    offline: '已下线',
};

export const roleLabels: Record<string, string> = {
    app: '应用服务器',
    db: '数据库服务器',
    redis: '缓存服务器',
    nginx: 'Web 代理',
    jump: '跳板机',
};

export const getSystemName = (systems: SsoConfig[], systemId?: number) =>
    systems.find(system => system.id === systemId)?.name || '未关联系统';

export const buildSystemOptions = (
    systems: SsoConfig[],
    assets: InfrastructureAsset[],
    manuals: InfrastructureSystemManual[],
): SystemOption[] => {
    return systems.map(system => {
        const systemAssets = assets.filter(asset => asset.appSystemId === system.id);
        const envTypes = getUniqueValues(systemAssets.map(asset => asset.envType))
            .map(name => {
                const envAssets = systemAssets.filter(asset => asset.envType === name);
                return {
                    name,
                    assetCount: envAssets.length,
                    activeCount: envAssets.filter(asset => asset.status === 'active').length,
                };
            });
        return {
            ...system,
            assetCount: systemAssets.length,
            activeCount: systemAssets.filter(asset => asset.status === 'active').length,
            manualCount: manuals.filter(manual => manual.appSystemId === system.id).length,
            envTypes,
        };
    });
};

export const getUniqueValues = (values: Array<string | undefined>) =>
    Array.from(new Set(values.filter(Boolean) as string[]));

export const filterAssets = (
    assets: InfrastructureAsset[],
    systems: SsoConfig[],
    manuals: InfrastructureSystemManual[],
    selectedSystemId: number | 'all',
    filters: AssetFilters,
) => {
    const keyword = filters.keyword.trim().toLowerCase();
    const matchedManualSystemIds = new Set(
        manuals
            .filter(manual => keyword && manualMatchesKeyword(manual, keyword))
            .map(manual => manual.appSystemId),
    );

    return assets.filter(asset => {
        const inSystem = selectedSystemId === 'all' || asset.appSystemId === selectedSystemId;
        const matchEnv = !filters.envId || asset.envId === filters.envId;
        const matchEnvType = !filters.envType || asset.envType === filters.envType;
        const matchStatus = !filters.status || asset.status === filters.status;
        const matchRole = !filters.role || asset.role === filters.role;
        const matchKeyword = !keyword
            || assetMatchesKeyword(asset, getSystemName(systems, asset.appSystemId), keyword)
            || matchedManualSystemIds.has(asset.appSystemId || 0);

        return inSystem && matchEnv && matchEnvType && matchStatus && matchRole && matchKeyword;
    });
};

export const filterManuals = (
    manuals: InfrastructureSystemManual[],
    selectedSystemId: number | 'all',
    keyword: string,
) => {
    const normalizedKeyword = keyword.trim().toLowerCase();
    return manuals.filter(manual => {
        const inSystem = selectedSystemId === 'all' || manual.appSystemId === selectedSystemId;
        const matchKeyword = !normalizedKeyword || manualMatchesKeyword(manual, normalizedKeyword);
        return inSystem && matchKeyword;
    });
};

const assetMatchesKeyword = (asset: InfrastructureAsset, systemName: string, keyword: string) => {
    const values = [
        systemName,
        asset.hostname,
        asset.internalIp,
        asset.externalIp,
        asset.envType,
        asset.role,
        roleLabels[asset.role || ''],
        asset.dbType,
        asset.osType,
        asset.osVersion,
        asset.hardwareModel,
        asset.description,
    ];
    return values.some(value => value?.toLowerCase().includes(keyword));
};

const manualMatchesKeyword = (manual: InfrastructureSystemManual, keyword: string) => {
    const values = [manual.title, manual.fileName, manual.description];
    return values.some(value => value?.toLowerCase().includes(keyword));
};
