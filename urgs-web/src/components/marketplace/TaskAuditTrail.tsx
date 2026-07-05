import React from 'react';
import { Empty } from 'antd';
import { AssetMaintenanceRecord, WorkTask } from '../../api/marketplace';

interface TaskAuditTrailProps {
    task: WorkTask;
}

const actionLabels: Record<string, string> = {
    APPLY: '申请承接',
    APPROVE_APP: '竞标通过',
    REJECT_APP: '竞标驳回',
    WITHDRAW_APP: '撤回竞标',
    CLAIM: '领取任务',
    RELEASE: '解除承接',
    ASSIGN: '指派任务',
    SUBMIT_REVIEW: '提交验收',
    ASSET_REVIEW_APPROVE: '资产同步审核通过',
    ASSET_REVIEW_REJECT: '资产同步审核退回',
    ASSET_REVIEW_CANCEL: '资产同步审核取消',
    REVIEW_APPROVE: '上线验收通过',
    REVIEW_REJECT: '上线验收退回',
    REVIEW_CANCEL: '上线验收取消',
    REVIEW_TRANSFER: '审核转派',
    ASSET_REVIEW_RESUBMIT: '重新提交资产同步审核',
    STAGE_TO_ASSET_REVIEW: '提交资产同步审核',
    STAGE_TO_REVIEW: '提交上线验收',
    STAGE_ADVANCE: '阶段推进',
    STAGE_RISK: '风险报备',
    RISK_TRACKING_APPEND: '风险跟踪',
    STATUS_UPDATE: '状态变更',
    REOPEN: '重新开启',
    ISSUE_TRACKING_COMPLETE: '完成问题任务',
    APPEAL_CREATE: '发起申诉',
    APPEAL_RESOLVE: '处理申诉',
};

const reviewActions = new Set([
    'ASSET_REVIEW_APPROVE',
    'ASSET_REVIEW_REJECT',
    'ASSET_REVIEW_CANCEL',
    'REVIEW_APPROVE',
    'REVIEW_REJECT',
    'REVIEW_CANCEL',
    'REVIEW_TRANSFER',
]);

const formatDateTime = (value?: string) => {
    if (!value) return '-';
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
};

const getModTypeLabel = (modType?: string) => {
    if (modType === 'CREATE') return '新增资产';
    if (modType === 'UPDATE') return '修改调整';
    if (modType === 'DELETE') return '删除资产';
    return modType || '-';
};

const parseMaintenanceSnapshot = (value?: string): AssetMaintenanceRecord[] => {
    if (!value) return [];
    try {
        const records = JSON.parse(value);
        return Array.isArray(records) ? records : [];
    } catch {
        return [];
    }
};

const TaskAuditTrail: React.FC<TaskAuditTrailProps> = ({ task }) => {
    const finalizedMaintenanceRecords = parseMaintenanceSnapshot(task.assetMaintenanceSnapshot);
    const isSnapshotFinalized = Boolean(task.assetMaintenanceSnapshotFinalized || task.assetMaintenanceSnapshot);
    const maintenanceRecords = isSnapshotFinalized
        ? finalizedMaintenanceRecords
        : (task.assetMaintenanceRecords || []);
    const auditLogs = task.auditLogs || [];

    return (
        <div className="space-y-5">
            <section>
                <div className="mb-3 flex items-center justify-between">
                    <div>
                        <div className="text-sm font-bold text-slate-800">资产同步变更明细</div>
                        <div className="mt-0.5 text-xs text-slate-400">
                            {isSnapshotFinalized
                                ? '资产审核通过时已固化，后续归档仍可追溯'
                                : '按任务需求编号实时匹配，审核通过后固化'}
                        </div>
                    </div>
                    <span className="rounded bg-cyan-50 px-2 py-1 text-xs font-bold text-cyan-700">
                        {maintenanceRecords.length} 条
                    </span>
                </div>
                {maintenanceRecords.length === 0 ? (
                    <Empty
                        image={Empty.PRESENTED_IMAGE_SIMPLE}
                        description={isSnapshotFinalized ? '本次审核未包含资产变更记录' : '当前未匹配到资产变更记录'}
                    />
                ) : (
                    <div className="overflow-x-auto rounded-lg border border-slate-200">
                        <table className="w-full min-w-[720px] text-xs">
                            <thead className="bg-slate-50 text-slate-500">
                                <tr>
                                    <th className="px-3 py-2 text-left">变更类型</th>
                                    <th className="px-3 py-2 text-left">资产对象</th>
                                    <th className="px-3 py-2 text-left">操作人</th>
                                    <th className="px-3 py-2 text-left">维护时间</th>
                                    <th className="px-3 py-2 text-left">变更说明</th>
                                </tr>
                            </thead>
                            <tbody>
                                {maintenanceRecords.map((record, index) => (
                                    <tr key={record.id || `${record.reqId || 'asset'}-${index}`} className="border-t border-slate-100 align-top">
                                        <td className="whitespace-nowrap px-3 py-2 font-bold text-cyan-700">
                                            {getModTypeLabel(record.modType)}
                                        </td>
                                        <td className="min-w-[180px] px-3 py-2">
                                            <div className="font-bold text-slate-700">{record.tableCnName || record.tableName || '-'}</div>
                                            <div className="mt-1 font-mono text-slate-400">{record.tableName || '-'}</div>
                                            {(record.fieldCnName || record.fieldName) && (
                                                <div className="mt-1 text-slate-500">
                                                    字段：{record.fieldCnName || record.fieldName}
                                                    {record.fieldCnName && record.fieldName ? ` (${record.fieldName})` : ''}
                                                </div>
                                            )}
                                        </td>
                                        <td className="px-3 py-2 text-slate-600">{record.operator || '-'}</td>
                                        <td className="whitespace-nowrap px-3 py-2 text-slate-500">{formatDateTime(record.time)}</td>
                                        <td className="min-w-[220px] whitespace-pre-wrap px-3 py-2 text-slate-600">{record.description || '-'}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </section>

            <section>
                <div className="mb-3">
                    <div className="text-sm font-bold text-slate-800">任务操作与审核轨迹</div>
                    <div className="mt-0.5 text-xs text-slate-400">按发生时间记录提交、退回、通过、阶段推进和风险处理</div>
                </div>
                {auditLogs.length === 0 ? (
                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无任务操作记录" />
                ) : (
                    <div className="space-y-2">
                        {auditLogs.map(log => (
                            <div
                                key={log.id}
                                className={`rounded-lg border px-4 py-3 ${
                                    reviewActions.has(log.action)
                                        ? 'border-orange-100 bg-orange-50/60'
                                        : 'border-slate-100 bg-slate-50'
                                }`}
                            >
                                <div className="flex flex-wrap items-center justify-between gap-2">
                                    <div className="flex items-center gap-2">
                                        <span className="text-sm font-bold text-slate-800">
                                            {actionLabels[log.action] || log.action}
                                        </span>
                                        {reviewActions.has(log.action) && (
                                            <span className="rounded bg-white px-1.5 py-0.5 text-[11px] font-bold text-orange-600">
                                                审核记录
                                            </span>
                                        )}
                                    </div>
                                    <span className="text-xs text-slate-400">{formatDateTime(log.createTime)}</span>
                                </div>
                                <div className="mt-1 text-xs text-slate-500">
                                    操作人：{log.operatorName || log.operatorId || '-'}
                                </div>
                                <div className="mt-2 whitespace-pre-wrap break-words text-sm text-slate-700">
                                    {log.detail || '-'}
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </section>
        </div>
    );
};

export default TaskAuditTrail;
