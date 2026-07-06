import React, { useState } from 'react';
import { Empty, Modal, Spin } from 'antd';
import {
    AssetMaintenanceRecord,
    getRegAssetTable,
    listModelAssetFields,
    listModelAssetTables,
    listRegAssetElements,
    listRegAssetTables,
    ModelFieldAsset,
    ModelTableAsset,
} from '../../api/marketplace';
import { RegElement, RegTable } from '../metadata/reg-asset/types';

interface AssetObjectDetailLinkProps {
    record: AssetMaintenanceRecord;
    children: React.ReactNode;
    className?: string;
}

type RegulatoryAssetDetail = {
    type: 'TABLE' | 'ELEMENT';
    data: RegTable | RegElement;
};

type ModelAssetDetail = {
    table: ModelTableAsset;
    field?: ModelFieldAsset;
};

const normalizeAssetName = (value?: string) => (value || '').trim().toLowerCase();

const unqualifiedAssetName = (value?: string) => {
    const normalized = (value || '').trim();
    const parts = normalized.split('.');
    return parts[parts.length - 1] || normalized;
};

const getAssetNameCandidates = (record: AssetMaintenanceRecord) => (
    [record.tableName, unqualifiedAssetName(record.tableName), record.tableCnName]
        .map(normalizeAssetName)
        .filter(Boolean)
);

const isFieldAsset = (record: AssetMaintenanceRecord) => (
    Boolean((record.fieldName || '').trim() || (record.fieldCnName || '').trim())
);

const findMatchedRegTable = async (record: AssetMaintenanceRecord) => {
    const keywords = [record.tableName, unqualifiedAssetName(record.tableName), record.tableCnName]
        .map(value => (value || '').trim())
        .filter(Boolean);
    const targets = getAssetNameCandidates(record);

    for (const keyword of keywords) {
        const res = await listRegAssetTables({
            keyword,
            systemCode: record.systemCode,
            page: 1,
            size: 20,
        });
        const records = res?.records || [];
        const exact = records.find(table => {
            const names = [table.name, unqualifiedAssetName(table.name), table.cnName].map(normalizeAssetName);
            return names.some(name => targets.includes(name));
        });
        if (exact) return exact as RegTable;
        if (records.length > 0) return records[0] as RegTable;
    }

    return null;
};

const findMatchedRegElement = async (tableId: number | string, record: AssetMaintenanceRecord) => {
    const keywords = [record.fieldName, record.fieldCnName]
        .map(value => (value || '').trim())
        .filter(Boolean);
    const targets = keywords.map(normalizeAssetName);

    for (const keyword of keywords) {
        const res = await listRegAssetElements({ tableId, keyword, page: 1, size: 50 });
        const records = res?.records || [];
        const exact = records.find(element => {
            const names = [element.name, element.cnName].map(normalizeAssetName);
            return names.some(name => targets.includes(name));
        });
        if (exact) return exact as RegElement;
        if (records.length > 0) return records[0] as RegElement;
    }

    return null;
};

const findMatchedModelTable = async (record: AssetMaintenanceRecord) => {
    const keyword = (record.tableName || record.tableCnName || '').trim();
    if (!keyword) return null;

    const res = await listModelAssetTables({
        keyword: unqualifiedAssetName(keyword),
        page: 1,
        size: 50,
    });
    const records = res?.records || [];
    const targets = getAssetNameCandidates(record);
    return records.find(table => {
        const names = [table.name, unqualifiedAssetName(table.name), table.cnName].map(normalizeAssetName);
        return names.some(name => targets.includes(name));
    }) || records[0] || null;
};

const findMatchedModelField = async (tableId: string, record: AssetMaintenanceRecord) => {
    const targets = [record.fieldName, record.fieldCnName]
        .map(normalizeAssetName)
        .filter(Boolean);
    if (targets.length === 0) return null;

    const fields = await listModelAssetFields(tableId);
    return (fields || []).find(field => {
        const names = [field.name, field.cnName].map(normalizeAssetName);
        return names.some(name => targets.includes(name));
    }) || null;
};

const DetailItem: React.FC<{
    label: string;
    value: React.ReactNode;
    fullWidth?: boolean;
}> = ({ label, value, fullWidth }) => (
    <div className={fullWidth ? 'md:col-span-2' : ''}>
        <div className="mb-1 text-xs text-slate-400">{label}</div>
        <div className="break-words text-sm font-medium text-slate-700">{value ?? '-'}</div>
    </div>
);

const AssetObjectDetailLink: React.FC<AssetObjectDetailLinkProps> = ({
    record,
    children,
    className = '',
}) => {
    const [open, setOpen] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [regulatoryDetail, setRegulatoryDetail] = useState<RegulatoryAssetDetail | null>(null);
    const [modelDetail, setModelDetail] = useState<ModelAssetDetail | null>(null);

    const loadDetail = async () => {
        const hasField = isFieldAsset(record);
        setLoading(true);
        setError('');
        setRegulatoryDetail(null);
        setModelDetail(null);

        try {
            let fallbackRegTable: RegTable | null = null;
            const regTable = await findMatchedRegTable(record);
            if (regTable?.id) {
                const tableDetail = await getRegAssetTable(regTable.id) as RegTable;
                if (hasField) {
                    const element = await findMatchedRegElement(tableDetail.id!, record);
                    if (element) {
                        setRegulatoryDetail({ type: 'ELEMENT', data: element });
                        return;
                    }
                    fallbackRegTable = tableDetail;
                } else {
                    setRegulatoryDetail({ type: 'TABLE', data: tableDetail });
                    return;
                }
            }

            const modelTable = await findMatchedModelTable(record);
            if (modelTable) {
                if (hasField) {
                    const field = await findMatchedModelField(modelTable.id, record);
                    setModelDetail({ table: modelTable, field: field || undefined });
                    if (!field) setError('未找到对应字段资产，已显示所属表资产信息');
                    return;
                }
                setModelDetail({ table: modelTable });
                return;
            }

            if (fallbackRegTable) {
                setRegulatoryDetail({ type: 'TABLE', data: fallbackRegTable });
                setError('未找到对应字段资产，已显示所属表资产信息');
                return;
            }

            setError('未找到对应的资产信息');
        } catch (loadError) {
            console.error('Failed to load asset object detail', loadError);
            setError('资产信息加载失败');
        } finally {
            setLoading(false);
        }
    };

    const handleOpen = (event: React.MouseEvent<HTMLButtonElement>) => {
        event.stopPropagation();
        setOpen(true);
        loadDetail();
    };

    const closeDetail = () => {
        setOpen(false);
        setLoading(false);
        setError('');
        setRegulatoryDetail(null);
        setModelDetail(null);
    };

    const renderRegulatoryDetail = () => {
        if (!regulatoryDetail) return null;
        const data = regulatoryDetail.data;
        const isTable = regulatoryDetail.type === 'TABLE';
        const table = data as RegTable;
        const element = data as RegElement;

        return (
            <div className="space-y-4">
                <div className="rounded-lg border border-slate-200">
                    <div className="border-b border-slate-200 bg-slate-50 px-4 py-3">
                        <div className="text-sm font-bold text-slate-800">{data.cnName || data.name}</div>
                        <div className="mt-1 font-mono text-xs text-slate-500">{data.name}</div>
                    </div>
                    <div className="grid grid-cols-1 gap-4 p-4 md:grid-cols-2">
                        <DetailItem label="资产类别" value={isTable ? '监管表资产' : '监管字段资产'} />
                        <DetailItem label="状态" value={data.status === 1 ? '启用' : '停用'} />
                        {isTable ? (
                            <>
                                <DetailItem label="所属系统" value={table.systemCode || '-'} />
                                <DetailItem label="报送频度" value={table.frequency || '-'} />
                                <DetailItem label="监管主题" value={table.theme || '-'} />
                                <DetailItem label="取数来源" value={table.sourceType || '-'} />
                                <DetailItem
                                    label="绑定物理表"
                                    value={(table.physicalTables || []).length > 0
                                        ? table.physicalTables?.map(item => (
                                            <div key={item.modelTableId} className="mb-1 rounded bg-slate-100 px-2 py-1 font-mono text-xs">
                                                {[item.owner, item.tableName].filter(Boolean).join('.')}
                                                {item.tableCnName ? <span className="ml-2 font-sans text-slate-500">{item.tableCnName}</span> : null}
                                            </div>
                                        ))
                                        : '-'}
                                    fullWidth
                                />
                            </>
                        ) : (
                            <>
                                <DetailItem label="资产类型" value={element.type === 'INDICATOR' ? '指标' : '字段'} />
                                <DetailItem label="数据类型" value={element.dataType || '-'} />
                                <DetailItem label="长度" value={element.length || '-'} />
                                <DetailItem label="允许为空" value={element.nullable ? '是' : '否'} />
                                <DetailItem
                                    label="绑定字段"
                                    value={(element.physicalFields || []).length > 0
                                        ? element.physicalFields?.map(item => (
                                            <div key={item.modelFieldId} className="mb-1 rounded bg-slate-100 px-2 py-1 font-mono text-xs">
                                                {item.fieldName}
                                                <span className="ml-2 font-sans text-slate-500">
                                                    {[item.fieldCnName, item.fieldType].filter(Boolean).join(' / ')}
                                                </span>
                                            </div>
                                        ))
                                        : '-'}
                                    fullWidth
                                />
                            </>
                        )}
                        <DetailItem label="业务口径" value={data.businessCaliber || '-'} fullWidth />
                        <DetailItem label="填报说明" value={data.fillInstruction || '-'} fullWidth />
                        <DetailItem label="开发备注" value={data.devNotes || '-'} fullWidth />
                    </div>
                </div>
            </div>
        );
    };

    const renderModelDetail = () => {
        if (!modelDetail) return null;

        return (
            <div className="space-y-4">
                <div className="rounded-lg border border-slate-200">
                    <div className="border-b border-slate-200 bg-slate-50 px-4 py-3">
                        <div className="text-sm font-bold text-slate-800">
                            {modelDetail.table.cnName || modelDetail.table.name}
                        </div>
                        <div className="mt-1 font-mono text-xs text-slate-500">{modelDetail.table.name}</div>
                    </div>
                    <div className="grid grid-cols-1 gap-4 p-4 md:grid-cols-2">
                        <DetailItem label="资产类别" value="模型表资产" />
                        <DetailItem label="Schema / Owner" value={modelDetail.table.owner || '-'} />
                        <DetailItem label="数据源" value={modelDetail.table.dataSourceId || '-'} />
                        <DetailItem label="主题" value={modelDetail.table.theme || '-'} />
                        <DetailItem label="频度" value={modelDetail.table.freq || '-'} />
                        <DetailItem label="备注" value={modelDetail.table.remark || '-'} fullWidth />
                    </div>
                </div>

                {modelDetail.field && (
                    <div className="rounded-lg border border-cyan-100">
                        <div className="border-b border-cyan-100 bg-cyan-50 px-4 py-3">
                            <div className="text-sm font-bold text-slate-800">
                                {modelDetail.field.cnName || modelDetail.field.name}
                            </div>
                            <div className="mt-1 font-mono text-xs text-slate-500">{modelDetail.field.name}</div>
                        </div>
                        <div className="grid grid-cols-1 gap-4 p-4 md:grid-cols-2">
                            <DetailItem label="资产类别" value="模型字段资产" />
                            <DetailItem label="字段类型" value={modelDetail.field.type || '-'} />
                            <DetailItem label="主键" value={modelDetail.field.isPk ? '是' : '否'} />
                            <DetailItem label="允许为空" value={modelDetail.field.nullable ? '是' : '否'} />
                            <DetailItem label="备注" value={modelDetail.field.remark || '-'} fullWidth />
                        </div>
                    </div>
                )}
            </div>
        );
    };

    return (
        <>
            <button
                type="button"
                onClick={handleOpen}
                title="点击查看资产详情"
                className={`block w-full rounded text-left transition-colors hover:text-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-200 ${className}`}
            >
                {children}
            </button>

            <Modal
                title="资产详细信息"
                open={open}
                onCancel={closeDetail}
                footer={null}
                width={760}
                destroyOnHidden
                zIndex={10050}
            >
                <div className="max-h-[72vh] overflow-y-auto pt-2">
                    {loading ? (
                        <div className="flex min-h-48 items-center justify-center">
                            <Spin tip="正在加载资产信息..." />
                        </div>
                    ) : (
                        <div className="space-y-3">
                            {error && (
                                <div className="rounded-lg border border-amber-100 bg-amber-50 px-3 py-2 text-xs font-medium text-amber-700">
                                    {error}
                                </div>
                            )}
                            {renderRegulatoryDetail()}
                            {renderModelDetail()}
                            {!regulatoryDetail && !modelDetail && (
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description={error || '未找到对应的资产信息'} />
                            )}
                        </div>
                    )}
                </div>
            </Modal>
        </>
    );
};

export default AssetObjectDetailLink;
