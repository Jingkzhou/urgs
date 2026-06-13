import { get } from '@/utils/request';
import { PhysicalFieldBinding, PhysicalTableBinding } from '@/components/metadata/reg-asset/types';

interface PageResult<T> {
    records: T[];
    total: number;
}

interface DataSourceConfig {
    id: number;
    name: string;
    metaId: number;
    status: number;
    typeName?: string;
    typeCode?: string;
    category?: string;
    metaName?: string;
    metaCategory?: string;
    metaCode?: string;
}

interface DataSourceMeta {
    id: number;
    code: string;
    name: string;
    category: string;
}

interface ModelTable {
    id: string;
    name: string;
    cnName?: string;
    owner?: string;
    dataSourceId?: number;
}

interface ModelField {
    id: string;
    tableId: string;
    name: string;
    cnName?: string;
    type?: string;
}

export interface PhysicalDataSourceOption extends DataSourceConfig {
    metaName?: string;
    metaCategory?: string;
    metaCode?: string;
}

export const physicalAssetService = {
    listDataSources: async (): Promise<PhysicalDataSourceOption[]> => {
        const [metaData, configData] = await Promise.all([
            get<DataSourceMeta[]>('/api/datasource/meta'),
            get<DataSourceConfig[]>('/api/datasource/options'),
        ]);
        const metas = Array.isArray(metaData) ? metaData : [];
        const configs = Array.isArray(configData) ? configData : [];
        const metaMap = new Map<string, DataSourceMeta>();
        metas.forEach(meta => metaMap.set(String(meta.id), meta));

        return configs
            .map(config => {
                const meta = metaMap.get(String(config.metaId));
                return {
                    ...config,
                    metaName: config.typeName || meta?.name,
                    metaCategory: config.category || meta?.category,
                    metaCode: config.typeCode || meta?.code,
                };
            })
            .filter(config => ['RDBMS', 'BIG DATA'].includes((config.metaCategory || '').toUpperCase()));
    },

    listOwners: (dataSourceId: number) =>
        get<string[]>('/api/metadata/model-table/owners', { dataSourceId: String(dataSourceId) }),

    listTables: async (params: { dataSourceId: number; owner?: string; keyword?: string; page?: number; size?: number }) => {
        const data = await get<PageResult<ModelTable>>('/api/metadata/model-table', {
            dataSourceId: String(params.dataSourceId),
            owner: params.owner,
            keyword: params.keyword,
            page: String(params.page ?? 1),
            size: String(params.size ?? 20),
        });
        return data?.records?.map(toPhysicalTableBinding) ?? [];
    },

    listFields: async (table: PhysicalTableBinding): Promise<PhysicalFieldBinding[]> => {
        const data = await get<ModelField[]>('/api/metadata/model-field', { tableId: table.modelTableId });
        return (Array.isArray(data) ? data : []).map(field => ({
            modelFieldId: field.id,
            modelTableId: table.modelTableId,
            dataSourceId: table.dataSourceId,
            owner: table.owner,
            tableName: table.tableName,
            tableCnName: table.tableCnName,
            fieldName: field.name,
            fieldCnName: field.cnName,
            fieldType: field.type,
        }));
    },
};

const toPhysicalTableBinding = (table: ModelTable): PhysicalTableBinding => ({
    modelTableId: table.id,
    dataSourceId: table.dataSourceId,
    owner: table.owner,
    tableName: table.name,
    tableCnName: table.cnName,
});
