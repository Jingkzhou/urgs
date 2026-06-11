import type { InfrastructureAsset, InfrastructureSystemManual } from '@/api/ops';
import type { SsoConfig } from '@/api/version';

export type AssetStatus = InfrastructureAsset['status'];

export interface AssetFilters {
    keyword: string;
    envId?: number;
    envType?: string;
    status?: AssetStatus;
    role?: string;
}

export interface SystemOption extends SsoConfig {
    assetCount: number;
    activeCount: number;
    manualCount: number;
    envTypes: Array<{
        name: string;
        assetCount: number;
        activeCount: number;
    }>;
}

export interface AssetTableContext {
    systems: SsoConfig[];
}

export type ManualRecord = InfrastructureSystemManual;
