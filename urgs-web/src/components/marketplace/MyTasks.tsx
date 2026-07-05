import React, { useState, useEffect } from 'react';
import { Pagination } from 'antd';
import {
    getKpiSummary,
    getMyTasks,
    reopenTask,
    releaseTask,
    advanceTaskStage,
    reportTaskStageRisk,
    createTaskAppeal,
    getWorkDetail,
    listAssetMaintenanceRecords,
    listRegAssetTables,
    getRegAssetTable,
    listRegAssetElements,
    listModelAssetTables,
    listModelAssetFields,
    AssetMaintenanceRecord,
    ModelTableAsset,
    ModelFieldAsset,
    TaskMarketDTO,
    KpiSummaryDTO,
} from '../../api/marketplace';
import { Archive, Award, Clock, Gauge, ListTodo, Star, TrendingUp, X } from 'lucide-react';
import TaskDetailDrawer from './TaskDetailDrawer';
import { getTaskStageLabel, getTaskStatusLabel } from './marketplaceLabels';
import { RegElement, RegTable } from '../metadata/reg-asset/types';
import { MarketplaceTodoFocus } from './marketplaceTodoFocus';

const formatDateInput = (date: Date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
};

const getCurrentMonthRange = () => {
    const now = new Date();
    return {
        startDate: formatDateInput(new Date(now.getFullYear(), now.getMonth(), 1)),
        endDate: formatDateInput(new Date(now.getFullYear(), now.getMonth() + 1, 0)),
    };
};

interface MyTasksProps {
    todoFocus?: MarketplaceTodoFocus | null;
}

const MyTasks: React.FC<MyTasksProps> = ({ todoFocus }) => {
    const [tasks, setTasks] = useState<TaskMarketDTO[]>([]);
    const [kpiSummary, setKpiSummary] = useState<KpiSummaryDTO | null>(null);
    const [dateRange, setDateRange] = useState(getCurrentMonthRange);
    const [loading, setLoading] = useState(false);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [total, setTotal] = useState(0);
    const [taskView, setTaskView] = useState<'active' | 'archive'>('active');
    const [statusFilter, setStatusFilter] = useState('');
    const [overdueOnly, setOverdueOnly] = useState(false);
    const [deadlineRange, setDeadlineRange] = useState({ startDate: '', endDate: '' });
    const [selectedTaskId, setSelectedTaskId] = useState<string | null>(null);
    const [isDetailOpen, setIsDetailOpen] = useState(false);
    const [appealTask, setAppealTask] = useState<TaskMarketDTO | null>(null);
    const [appealForm, setAppealForm] = useState({ reason: '', expectedResult: '' });
    const [riskTask, setRiskTask] = useState<TaskMarketDTO | null>(null);
    const [riskNote, setRiskNote] = useState('');
    const [assetReviewTask, setAssetReviewTask] = useState<TaskMarketDTO | null>(null);
    const [assetReviewRecords, setAssetReviewRecords] = useState<AssetMaintenanceRecord[]>([]);
    const [assetReviewReqId, setAssetReviewReqId] = useState('');
    const [assetReviewWorkTitle, setAssetReviewWorkTitle] = useState('');
    const [assetReviewNote, setAssetReviewNote] = useState('');
    const [assetReviewLoading, setAssetReviewLoading] = useState(false);
    const [assetReviewSubmitting, setAssetReviewSubmitting] = useState(false);
    const [assetReviewError, setAssetReviewError] = useState('');
    const [assetDetailOpen, setAssetDetailOpen] = useState(false);
    const [assetDetailLoading, setAssetDetailLoading] = useState(false);
    const [assetDetailError, setAssetDetailError] = useState('');
    const [regAssetDetail, setRegAssetDetail] = useState<{ type: 'TABLE' | 'ELEMENT'; data: RegTable | RegElement } | null>(null);
    const [modelAssetDetail, setModelAssetDetail] = useState<{ table: ModelTableAsset; field?: ModelFieldAsset } | null>(null);

    const fetchTasks = async () => {
        setLoading(true);
        try {
            const taskRes = await getMyTasks({
                current: currentPage,
                size: pageSize,
                archived: taskView === 'archive',
                status: statusFilter || undefined,
                overdue: overdueOnly || undefined,
                deadlineStart: deadlineRange.startDate ? `${deadlineRange.startDate}T00:00:00` : undefined,
                deadlineEnd: deadlineRange.endDate ? `${deadlineRange.endDate}T23:59:59` : undefined,
            });
            if ((taskRes?.records || []).length === 0 && currentPage > 1 && (taskRes?.total || 0) > 0) {
                setCurrentPage(currentPage - 1);
                return;
            }
            setTasks(taskRes?.records || []);
            setTotal(taskRes?.total || 0);
        } catch (error) {
            console.error('Failed to fetch personal tasks', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTasks();
    }, [currentPage, pageSize, taskView, statusFilter, overdueOnly, deadlineRange.startDate, deadlineRange.endDate]);

    useEffect(() => {
        if (!todoFocus || todoFocus.targetTab !== 'mine') return;

        setTaskView('active');
        setCurrentPage(1);
        setDeadlineRange({ startDate: '', endDate: '' });

        if (todoFocus.type === 'OVERDUE') {
            setStatusFilter('');
            setOverdueOnly(true);
        } else {
            setOverdueOnly(false);
            setStatusFilter(['READY', 'REWORK', 'WAITING_REVIEW'].includes(todoFocus.type) ? todoFocus.type : '');
        }
    }, [todoFocus?.sequence]);

    useEffect(() => {
        getKpiSummary(dateRange)
            .then(res => setKpiSummary(res || null))
            .catch(error => console.error('Failed to fetch KPI summary', error));
    }, [dateRange.startDate, dateRange.endDate]);

    const resetToCurrentMonth = () => {
        setDateRange(getCurrentMonthRange());
    };

    const isAssetReviewAdvance = (task: TaskMarketDTO) => {
        return task.currentStage === 'TESTING' || task.currentStage === 'ASSET_REVIEW';
    };

    const isIssueTrackingTask = (task: TaskMarketDTO) => {
        const taskType = (task.taskType || '').trim();
        return taskType === '问题跟踪' || taskType === '问题追踪';
    };

    const resetAssetReviewDialog = () => {
        setAssetReviewTask(null);
        setAssetReviewRecords([]);
        setAssetReviewReqId('');
        setAssetReviewWorkTitle('');
        setAssetReviewNote('');
        setAssetReviewLoading(false);
        setAssetReviewSubmitting(false);
        setAssetReviewError('');
        setAssetDetailOpen(false);
        setAssetDetailLoading(false);
        setAssetDetailError('');
        setRegAssetDetail(null);
        setModelAssetDetail(null);
    };

    const formatRecordTime = (value?: string) => {
        if (!value) return '-';
        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
    };

    const getModTypeLabel = (modType?: string) => {
        if (!modType) return '-';
        if (modType === 'CREATE') return '新增资产';
        if (modType === 'UPDATE') return '修改调整';
        if (modType === 'DELETE') return '删除资产';
        return modType;
    };

    const normalizeAssetName = (value?: string) => (value || '').trim().toLowerCase();

    const unqualifiedAssetName = (value?: string) => {
        const normalized = (value || '').trim();
        const parts = normalized.split('.');
        return parts[parts.length - 1] || normalized;
    };

    const getAssetNameCandidates = (record: AssetMaintenanceRecord) => {
        return [record.tableName, unqualifiedAssetName(record.tableName), record.tableCnName]
            .map(normalizeAssetName)
            .filter(Boolean);
    };

    const isRecordFieldAsset = (record: AssetMaintenanceRecord) => {
        return Boolean((record.fieldName || '').trim() || (record.fieldCnName || '').trim());
    };

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
            if (exact) {
                return exact as RegTable;
            }
            if (records.length > 0) {
                return records[0] as RegTable;
            }
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
            if (exact) {
                return exact as RegElement;
            }
            if (records.length > 0) {
                return records[0] as RegElement;
            }
        }
        return null;
    };

    const findMatchedModelTable = async (record: AssetMaintenanceRecord) => {
        const keyword = (record.tableName || record.tableCnName || '').trim();
        if (!keyword) return null;

        const res = await listModelAssetTables({ keyword: unqualifiedAssetName(keyword), page: 1, size: 50 });
        const records = res?.records || [];
        const targets = getAssetNameCandidates(record);
        return records.find(table => {
            const names = [table.name, unqualifiedAssetName(table.name), table.cnName].map(normalizeAssetName);
            return names.some(name => targets.includes(name));
        }) || records[0] || null;
    };

    const findMatchedModelField = async (tableId: string, record: AssetMaintenanceRecord) => {
        const targets = [record.fieldName, record.fieldCnName].map(normalizeAssetName).filter(Boolean);
        if (targets.length === 0) return null;

        const fields = await listModelAssetFields(tableId);
        return (fields || []).find(field => {
            const names = [field.name, field.cnName].map(normalizeAssetName);
            return names.some(name => targets.includes(name));
        }) || null;
    };

    const openAssetDetail = async (record: AssetMaintenanceRecord) => {
        const hasField = isRecordFieldAsset(record);
        setAssetDetailOpen(true);
        setAssetDetailLoading(true);
        setAssetDetailError('');
        setRegAssetDetail(null);
        setModelAssetDetail(null);

        try {
            let fallbackRegTable: RegTable | null = null;
            const regTable = await findMatchedRegTable(record);
            if (regTable?.id) {
                const tableDetail = await getRegAssetTable(regTable.id) as RegTable;
                if (hasField) {
                    const element = await findMatchedRegElement(tableDetail.id!, record);
                    if (element) {
                        setRegAssetDetail({ type: 'ELEMENT', data: element });
                        return;
                    }
                    fallbackRegTable = tableDetail;
                } else {
                    setRegAssetDetail({ type: 'TABLE', data: tableDetail });
                    return;
                }
            }

            const modelTable = await findMatchedModelTable(record);
            if (modelTable) {
                if (hasField) {
                    const field = await findMatchedModelField(modelTable.id, record);
                    setModelAssetDetail({ table: modelTable, field: field || undefined });
                    if (!field) {
                        setAssetDetailError('未找到对应字段资产，已显示所属表资产信息');
                    }
                    return;
                }
                setModelAssetDetail({ table: modelTable });
                return;
            }

            if (fallbackRegTable) {
                setRegAssetDetail({ type: 'TABLE', data: fallbackRegTable });
                setAssetDetailError('未找到对应字段资产，已显示所属表资产信息');
                return;
            }

            setAssetDetailError('未找到对应的资产信息');
        } catch (error) {
            console.error('Failed to load asset detail', error);
            setAssetDetailError('资产信息加载失败');
        } finally {
            setAssetDetailLoading(false);
        }
    };

    const closeAssetDetail = () => {
        setAssetDetailOpen(false);
        setAssetDetailLoading(false);
        setAssetDetailError('');
        setRegAssetDetail(null);
        setModelAssetDetail(null);
    };

    const openAssetReviewConfirm = async (task: TaskMarketDTO) => {
        setAssetReviewTask(task);
        setAssetReviewRecords([]);
        setAssetReviewReqId('');
        setAssetReviewWorkTitle('');
        setAssetReviewNote('');
        setAssetReviewError('');
        setAssetReviewLoading(true);
        try {
            const work = await getWorkDetail(task.workId);
            const reqId = (work?.requirementNumber || '').trim();
            setAssetReviewReqId(reqId);
            setAssetReviewWorkTitle(work?.title || task.title);
            if (!reqId) {
                setAssetReviewError('当前工作没有需求编号，无法匹配资产管理维护记录');
                return;
            }

            let res = await listAssetMaintenanceRecords({ reqId, page: 1, size: 100 });
            let records = res?.records || [];
            if ((res?.total || 0) > records.length) {
                res = await listAssetMaintenanceRecords({ reqId, page: 1, size: res.total });
                records = res?.records || [];
            }
            setAssetReviewRecords(records);
            if (records.length === 0) {
                setAssetReviewError(`未找到需求编号 ${reqId} 的资产管理维护记录`);
            }
        } catch (error) {
            console.error('Failed to load asset maintenance records', error);
            setAssetReviewError('资产管理维护记录加载失败');
        } finally {
            setAssetReviewLoading(false);
        }
    };

    const handleAdvanceStage = async (task: TaskMarketDTO) => {
        if (isIssueTrackingTask(task) && !window.confirm(`确定完成问题任务「${task.title}」吗？完成后将直接进入归档。`)) {
            return;
        }
        if (!isIssueTrackingTask(task) && isAssetReviewAdvance(task)) {
            await openAssetReviewConfirm(task);
            return;
        }

        try {
            await advanceTaskStage(task.id);
            fetchTasks();
        } catch (error) {
            if (isIssueTrackingTask(task)) {
                alert('完成任务失败，请确认其子任务已全部完成');
                return;
            }
            if (task.currentStage === 'LAUNCH') {
                alert('进入验收失败，请确认子任务已完成');
                return;
            }
            alert('阶段推进失败');
        }
    };

    const confirmAssetReviewAdvance = async () => {
        if (!assetReviewTask) return;
        const trimmedNote = assetReviewNote.trim();
        if (assetReviewRecords.length === 0 && !trimmedNote) {
            setAssetReviewError('未找到资产维护记录时，请先填写提交说明');
            return;
        }
        setAssetReviewSubmitting(true);
        try {
            await advanceTaskStage(assetReviewTask.id, { assetReviewNote: trimmedNote || undefined });
            resetAssetReviewDialog();
            fetchTasks();
        } catch (error) {
            alert('提交资产同步审核失败');
            setAssetReviewSubmitting(false);
        }
    };

    const handleReportRisk = async () => {
        if (!riskTask) return;
        if (!riskNote.trim()) {
            alert('请填写风险说明');
            return;
        }
        try {
            await reportTaskStageRisk(riskTask.id, { riskNote: riskNote.trim() });
            setRiskTask(null);
            setRiskNote('');
            fetchTasks();
        } catch (error) {
            alert('风险报备失败');
        }
    };

    const getAdvanceButtonText = (task: TaskMarketDTO) => {
        if (isIssueTrackingTask(task)) return '完成任务';
        if (task.currentStage === 'TESTING') return '完成测试，提交资产审核';
        if (task.currentStage === 'ASSET_REVIEW') return '重新提交资产审核';
        if (task.currentStage === 'LAUNCH') return '上线完成，进入验收';
        return `完成${getTaskStageLabel(task.currentStage)}阶段`;
    };

    const handleReleaseTask = async (task: TaskMarketDTO) => {
        if (!window.confirm(`确定要解除承接「${task.title}」吗？解除后任务将返回任务大厅。`)) return;
        try {
            await releaseTask(task.id);
            fetchTasks();
        } catch (error) {
            alert('解除承接失败');
        }
    };

    const handleReopenTask = async (task: TaskMarketDTO) => {
        if (!window.confirm(`确定要重新开启任务「${task.title}」吗？`)) return;
        try {
            await reopenTask(task.id);
            await fetchTasks();
        } catch (error) {
            alert('重新开启任务失败，所属工作可能已取消');
        }
    };

    const handleAppeal = async () => {
        if (!appealTask) return;
        if (!appealForm.reason) {
            alert('请填写申诉原因');
            return;
        }
        try {
            await createTaskAppeal(appealTask.id, appealForm);
            setAppealTask(null);
            setAppealForm({ reason: '', expectedResult: '' });
            alert('申诉已提交');
        } catch (error) {
            alert('提交申诉失败');
        }
    };

    return (
        <div className="h-full flex flex-col p-6 overflow-y-auto">
            <div className="mb-6">
                <h2 className="text-xl font-bold text-slate-800">个人看板</h2>
                <p className="text-sm text-slate-500 mt-1">我的 KPI 积分、质量表现和承接任务</p>
            </div>

            <div className="flex flex-wrap items-center gap-3 mb-4 bg-slate-50 border border-slate-100 rounded-xl px-4 py-3">
                <span className="text-sm font-bold text-slate-700">KPI 周期</span>
                <input
                    type="date"
                    value={dateRange.startDate}
                    onChange={e => setDateRange(prev => ({ ...prev, startDate: e.target.value }))}
                    className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm"
                />
                <span className="text-slate-400 text-sm">至</span>
                <input
                    type="date"
                    value={dateRange.endDate}
                    onChange={e => setDateRange(prev => ({ ...prev, endDate: e.target.value }))}
                    className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm"
                />
                <button
                    onClick={resetToCurrentMonth}
                    className="px-3 py-1.5 text-sm font-bold text-red-600 bg-red-50 hover:bg-red-100 rounded-lg"
                >
                    本月
                </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
                <div className="bg-orange-50 border border-orange-100 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-orange-700 text-sm font-bold mb-3">
                        <Award size={18} /> 最终 KPI 积分
                    </div>
                    <div className="text-3xl font-black text-orange-700">{kpiSummary?.finalPoints ?? 0}</div>
                    <div className="text-xs text-orange-600 mt-1">基础积分 {kpiSummary?.basePoints ?? 0}</div>
                </div>
                <div className="bg-blue-50 border border-blue-100 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-blue-700 text-sm font-bold mb-3">
                        <ListTodo size={18} /> 完成任务
                    </div>
                    <div className="text-3xl font-black text-blue-700">{kpiSummary?.completedTaskCount ?? 0}</div>
                    <div className="text-xs text-blue-600 mt-1">进行中 {kpiSummary?.activeTaskCount ?? 0}</div>
                </div>
                <div className="bg-green-50 border border-green-100 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-green-700 text-sm font-bold mb-3">
                        <Gauge size={18} /> 准时率
                    </div>
                    <div className="text-3xl font-black text-green-700">{kpiSummary?.onTimeRate ?? 0}%</div>
                    <div className="text-xs text-green-600 mt-1">延期 {kpiSummary?.overdueCount ?? 0} 次</div>
                </div>
                <div className="bg-slate-50 border border-slate-200 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-slate-700 text-sm font-bold mb-3">
                        <Star size={18} /> 质量与返工
                    </div>
                    <div className="text-3xl font-black text-slate-800">{kpiSummary?.averageQualityScore ?? 0}</div>
                    <div className="text-xs text-slate-500 mt-1">返工 {kpiSummary?.reworkCount ?? 0} 次 · 高优先级 {kpiSummary?.highPriorityTaskCount ?? 0}</div>
                </div>
            </div>

            <div className="flex items-center gap-2 mb-4 border-b border-slate-100">
                <button
                    type="button"
                    onClick={() => {
                        setTaskView('active');
                        setStatusFilter('');
                        setOverdueOnly(false);
                        setCurrentPage(1);
                    }}
                    className={`inline-flex items-center gap-2 px-3 py-3 border-b-2 text-sm font-bold transition-colors ${
                        taskView === 'active'
                            ? 'border-red-600 text-red-600'
                            : 'border-transparent text-slate-500 hover:text-slate-800'
                    }`}
                >
                    <TrendingUp size={17} /> 进行中任务
                </button>
                <button
                    type="button"
                    onClick={() => {
                        setTaskView('archive');
                        setStatusFilter('');
                        setOverdueOnly(false);
                        setCurrentPage(1);
                    }}
                    className={`inline-flex items-center gap-2 px-3 py-3 border-b-2 text-sm font-bold transition-colors ${
                        taskView === 'archive'
                            ? 'border-red-600 text-red-600'
                            : 'border-transparent text-slate-500 hover:text-slate-800'
                    }`}
                >
                    <Archive size={17} /> 已归档
                </button>
            </div>

            <div className="mb-4 flex flex-wrap items-center gap-3 rounded-xl border border-slate-100 bg-slate-50 px-4 py-3">
                <span className="text-sm font-bold text-slate-700">任务筛选</span>
                <select
                    value={statusFilter}
                    onChange={event => {
                        setStatusFilter(event.target.value);
                        setOverdueOnly(false);
                        setCurrentPage(1);
                    }}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700 outline-none focus:border-red-400"
                >
                    <option value="">全部状态</option>
                    {taskView === 'archive' ? (
                        <option value="COMPLETED">已完成</option>
                    ) : (
                        <>
                            <option value="READY">待开始</option>
                            <option value="IN_PROGRESS">处理中</option>
                            <option value="PAUSED">已暂停</option>
                            <option value="WAITING_REVIEW">待审核</option>
                            <option value="REWORK">退回修改</option>
                            <option value="CANCELLED">已取消</option>
                        </>
                    )}
                </select>
                <span className="text-sm text-slate-500">截止日期</span>
                <input
                    type="date"
                    value={deadlineRange.startDate}
                    max={deadlineRange.endDate || undefined}
                    onChange={event => {
                        setOverdueOnly(false);
                        setDeadlineRange(prev => ({ ...prev, startDate: event.target.value }));
                        setCurrentPage(1);
                    }}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700"
                />
                <span className="text-sm text-slate-400">至</span>
                <input
                    type="date"
                    value={deadlineRange.endDate}
                    min={deadlineRange.startDate || undefined}
                    onChange={event => {
                        setOverdueOnly(false);
                        setDeadlineRange(prev => ({ ...prev, endDate: event.target.value }));
                        setCurrentPage(1);
                    }}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700"
                />
                {overdueOnly && (
                    <span className="rounded-lg border border-red-100 bg-red-50 px-3 py-1.5 text-sm font-bold text-red-600">
                        仅看逾期
                    </span>
                )}
                {(statusFilter || overdueOnly || deadlineRange.startDate || deadlineRange.endDate) && (
                    <button
                        type="button"
                        onClick={() => {
                            setStatusFilter('');
                            setOverdueOnly(false);
                            setDeadlineRange({ startDate: '', endDate: '' });
                            setCurrentPage(1);
                        }}
                        className="rounded-lg px-3 py-1.5 text-sm font-bold text-red-600 transition-colors hover:bg-red-50"
                    >
                        清除筛选
                    </button>
                )}
            </div>

            {loading ? (
                <div className="text-center py-10 text-slate-400">加载中...</div>
            ) : tasks.length === 0 ? (
                <div className="text-center py-10 text-slate-400 bg-slate-50 rounded-2xl border border-dashed border-slate-200">
                    {taskView === 'archive' ? '暂无已完成的归档任务。' : '您还没有领取的任务，去大厅逛逛吧。'}
                </div>
            ) : (
                <div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {tasks.map(task => (
                        <div key={task.id} className="bg-white border text-left border-slate-200 rounded-xl p-5 shadow-sm">
                            <div className="flex items-center justify-between mb-2">
                                <h3
                                    onClick={() => {
                                        setSelectedTaskId(task.id);
                                        setIsDetailOpen(true);
                                    }}
                                    className="font-bold text-slate-800 hover:text-red-600 cursor-pointer transition-colors"
                                >
                                    {task.title}
                                </h3>
                                <span className={`px-2 py-0.5 rounded text-xs font-bold uppercase ${task.status === 'COMPLETED' ? 'bg-green-100 text-green-700' :
                                    task.status === 'IN_PROGRESS' ? 'bg-blue-100 text-blue-700' :
                                        task.status === 'WAITING_REVIEW' ? 'bg-orange-100 text-orange-700' :
                                            task.status === 'REWORK' ? 'bg-red-100 text-red-700' : 'bg-slate-100 text-slate-600'
                                    }`}>
                                    {getTaskStatusLabel(task.status)}
                                </span>
                            </div>
                            <div className="mb-3 rounded-lg border border-slate-100 bg-slate-50 px-3 py-2 text-xs">
                                <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                                    <span className="font-bold text-slate-700 truncate max-w-full">
                                        工作：{task.workTitle || '-'}
                                    </span>
                                    <span className="text-slate-400">|</span>
                                    <span className="font-bold text-cyan-700">
                                        需求编号：{task.requirementNumber || '-'}
                                    </span>
                                </div>
                                <div className="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-slate-500">
                                    <span>申请部门：{task.applicationDepartment || '-'}</span>
                                    <span>申请人：{task.applicantName || '-'}</span>
                                    <span>归属系统：{task.owningSystem || '-'}</span>
                                    <span>项目类型：{task.projectType || '-'}</span>
                                </div>
                            </div>
                            <p className="text-sm text-slate-500 mb-4 line-clamp-2">{task.description}</p>
                            <div className="flex flex-wrap items-center gap-2 mb-3 text-xs">
                                {!isIssueTrackingTask(task) && (
                                    <span className="px-2 py-1 rounded bg-blue-50 text-blue-700 font-bold">
                                        当前阶段：{getTaskStageLabel(task.currentStage)}
                                    </span>
                                )}
                                {task.stageRiskReported && (
                                    <span className="px-2 py-1 rounded bg-amber-50 text-amber-700 font-bold">
                                        已报备风险
                                    </span>
                                )}
                                {task.taskRole === 'MAIN' && (
                                    <span className="px-2 py-1 rounded bg-red-50 text-red-600 font-bold">
                                        主任务
                                    </span>
                                )}
                            </div>

                            <div className="flex items-center justify-between mt-auto pt-4 border-t border-slate-100">
                                <div className="flex items-center gap-1.5 text-xs text-slate-500 font-medium">
                                    <Clock size={14} />
                                    <span>{task.deadline ? new Date(task.deadline).toLocaleDateString() : '无期限'}</span>
                                    <span className="mx-2 text-slate-300">|</span>
                                    <span className="text-orange-500 font-bold">{task.points} 积分</span>
                                </div>

                                <div className="flex gap-2">
                                    {(task.status === 'READY' || task.status === 'IN_PROGRESS' || task.status === 'REWORK') && (
                                        <>
                                            {task.status === 'READY' && task.taskRole !== 'MAIN' && (
                                                <button
                                                    onClick={() => handleReleaseTask(task)}
                                                    className="px-3 py-1 bg-slate-100 text-slate-600 hover:bg-slate-200 rounded text-xs font-bold transition-colors"
                                                >
                                                    解除承接
                                                </button>
                                            )}
                                            {!isIssueTrackingTask(task) && (
                                                <button
                                                    onClick={() => setRiskTask(task)}
                                                    className="px-3 py-1 bg-amber-50 text-amber-700 hover:bg-amber-100 rounded text-xs font-bold transition-colors"
                                                >
                                                    报备风险
                                                </button>
                                            )}
                                            <button
                                                onClick={() => handleAdvanceStage(task)}
                                                className="px-3 py-1 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded text-xs font-bold transition-colors"
                                            >
                                                {getAdvanceButtonText(task)}
                                            </button>
                                        </>
                                    )}
                                    {task.status === 'REWORK' && (
                                        <button
                                            onClick={() => setAppealTask(task)}
                                            className="px-3 py-1 bg-slate-100 text-slate-600 hover:bg-slate-200 rounded text-xs font-bold transition-colors"
                                        >
                                            申诉
                                        </button>
                                    )}
                                    {task.status === 'WAITING_REVIEW' && (
                                        <span className="text-xs text-orange-500 font-medium px-2 py-1 bg-orange-50 rounded">审核中...</span>
                                    )}
                                    {task.status === 'CANCELLED' && (
                                        <button
                                            onClick={() => handleReopenTask(task)}
                                            className="rounded bg-green-50 px-3 py-1 text-xs font-bold text-green-700 transition-colors hover:bg-green-100"
                                        >
                                            重新开启
                                        </button>
                                    )}
                                </div>
                            </div>
                        </div>
                        ))}
                    </div>
                    <div className="mt-5 flex justify-end">
                        <Pagination
                            current={currentPage}
                            pageSize={pageSize}
                            total={total}
                            showSizeChanger
                            pageSizeOptions={[10, 20, 50]}
                            showTotal={count => `共 ${count} 个任务`}
                            onChange={(page, size) => {
                                setCurrentPage(size !== pageSize ? 1 : page);
                                setPageSize(size);
                            }}
                        />
                    </div>
                </div>
            )}

            <TaskDetailDrawer
                taskId={selectedTaskId}
                isOpen={isDetailOpen}
                onClose={() => setIsDetailOpen(false)}
                onClaimSuccess={fetchTasks}
            />

            {assetReviewTask && (
                <div className="fixed inset-0 bg-black/30 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-5xl max-h-[86vh] flex flex-col">
                        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                            <div>
                                <h3 className="font-bold text-slate-800">资产同步审核确认</h3>
                                <p className="text-xs text-slate-500 mt-1">
                                    {assetReviewTask.title} · {assetReviewWorkTitle || '-'}
                                </p>
                            </div>
                            <button
                                onClick={resetAssetReviewDialog}
                                disabled={assetReviewSubmitting}
                                className="p-1.5 hover:bg-slate-100 rounded disabled:opacity-50"
                            >
                                <X size={18} />
                            </button>
                        </div>
                        <div className="p-5 overflow-y-auto space-y-4">
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
                                <div className="bg-slate-50 border border-slate-100 rounded-lg p-3">
                                    <div className="text-slate-400 mb-1">需求编号</div>
                                    <div className="font-bold text-slate-800">{assetReviewReqId || '-'}</div>
                                </div>
                                <div className="bg-slate-50 border border-slate-100 rounded-lg p-3">
                                    <div className="text-slate-400 mb-1">当前阶段</div>
                                    <div className="font-bold text-blue-700">{getTaskStageLabel(assetReviewTask.currentStage)}</div>
                                </div>
                                <div className="bg-slate-50 border border-slate-100 rounded-lg p-3">
                                    <div className="text-slate-400 mb-1">同步变更记录</div>
                                    <div className="font-bold text-cyan-700">{assetReviewRecords.length} 条</div>
                                </div>
                            </div>

                            {assetReviewLoading ? (
                                <div className="text-center py-8 text-slate-400 bg-slate-50 rounded-lg border border-dashed border-slate-200">
                                    正在加载资产管理维护记录...
                                </div>
                            ) : (
                                <>
                                    {assetReviewError && (
                                        <div className="rounded-lg border border-amber-100 bg-amber-50 px-3 py-2 text-xs font-medium text-amber-700">
                                            {assetReviewError}
                                        </div>
                                    )}

                                    <div>
                                        <label className="block text-xs font-bold text-slate-600 mb-1">
                                            提交说明{assetReviewRecords.length === 0 ? ' *' : ''}
                                        </label>
                                        <textarea
                                            value={assetReviewNote}
                                            onChange={e => setAssetReviewNote(e.target.value)}
                                            className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[84px]"
                                            placeholder={assetReviewRecords.length === 0
                                                ? '未找到维护记录，请说明本次资产是否无需同步、已通过其他方式维护，或待补充的原因'
                                                : '可补充本次资产同步范围、注意事项或特殊说明'}
                                        />
                                    </div>

                                    {assetReviewRecords.length > 0 && (
                                        <div className="border border-slate-200 rounded-lg overflow-hidden">
                                            <div className="px-3 py-2 bg-slate-50 border-b border-slate-200 text-xs font-bold text-slate-600">
                                                资产管理维护记录
                                                <span className="ml-2 font-medium text-slate-400">单击记录查看维护资产信息</span>
                                            </div>
                                            <div className="overflow-x-auto">
                                                <table className="min-w-full text-xs">
                                                    <thead className="bg-white text-slate-400">
                                                        <tr className="border-b border-slate-100">
                                                            <th className="text-left px-3 py-2 font-bold">变更类型</th>
                                                            <th className="text-left px-3 py-2 font-bold">表名</th>
                                                            <th className="text-left px-3 py-2 font-bold">表中文名</th>
                                                            <th className="text-left px-3 py-2 font-bold">字段名</th>
                                                            <th className="text-left px-3 py-2 font-bold">字段中文名</th>
                                                            <th className="text-left px-3 py-2 font-bold">系统</th>
                                                            <th className="text-left px-3 py-2 font-bold">操作人</th>
                                                            <th className="text-left px-3 py-2 font-bold">时间</th>
                                                            <th className="text-left px-3 py-2 font-bold">变更说明</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        {assetReviewRecords.map((record, index) => (
                                                            <tr
                                                                key={record.id || `${record.reqId}-${index}`}
                                                                onClick={() => openAssetDetail(record)}
                                                                title="单击查看维护的资产信息"
                                                                className="border-b border-slate-100 last:border-b-0 align-top cursor-pointer hover:bg-cyan-50/60"
                                                            >
                                                                <td className="px-3 py-2 font-bold text-cyan-700 whitespace-nowrap">
                                                                    {getModTypeLabel(record.modType)}
                                                                </td>
                                                                <td className="px-3 py-2 text-slate-700 min-w-[140px]">
                                                                    {record.tableName || '-'}
                                                                </td>
                                                                <td className="px-3 py-2 text-slate-700 min-w-[140px]">
                                                                    {record.tableCnName || '-'}
                                                                </td>
                                                                <td className="px-3 py-2 text-slate-700 min-w-[120px]">
                                                                    {record.fieldName || '-'}
                                                                </td>
                                                                <td className="px-3 py-2 text-slate-700 min-w-[140px]">
                                                                    {record.fieldCnName || '-'}
                                                                </td>
                                                                <td className="px-3 py-2 text-slate-600 whitespace-nowrap">
                                                                    {record.systemCode || record.assetType || '-'}
                                                                </td>
                                                                <td className="px-3 py-2 text-slate-600 whitespace-nowrap">
                                                                    {record.operator || '-'}
                                                                </td>
                                                                <td className="px-3 py-2 text-slate-500 whitespace-nowrap">
                                                                    {formatRecordTime(record.time)}
                                                                </td>
                                                                <td className="px-3 py-2 text-slate-700 min-w-[260px]">
                                                                    <div className="whitespace-pre-wrap break-words">{record.description || '-'}</div>
                                                                </td>
                                                            </tr>
                                                        ))}
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    )}
                                </>
                            )}
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end gap-2">
                            <button
                                onClick={resetAssetReviewDialog}
                                disabled={assetReviewSubmitting}
                                className="px-4 py-2 text-sm font-bold text-slate-500 hover:bg-slate-50 rounded-lg disabled:opacity-50"
                            >
                                关闭
                            </button>
                            <button
                                onClick={confirmAssetReviewAdvance}
                                disabled={assetReviewLoading || assetReviewSubmitting || (assetReviewRecords.length === 0 && !assetReviewNote.trim())}
                                className="px-4 py-2 text-sm font-bold text-white bg-cyan-600 hover:bg-cyan-700 rounded-lg disabled:opacity-50 disabled:hover:bg-cyan-600"
                            >
                                {assetReviewSubmitting ? '提交中...' : '确认进入审核'}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {assetDetailOpen && regAssetDetail && (
                <div className="fixed inset-0 bg-black/30 z-[10000] flex items-center justify-center p-4">
                    <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-3xl max-h-[82vh] flex flex-col">
                        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                            <div>
                                <h3 className="font-bold text-slate-800">维护资产信息</h3>
                                <p className="text-xs text-slate-500 mt-1">
                                    {regAssetDetail.type === 'TABLE' ? '监管表资产' : '监管字段资产'}
                                </p>
                            </div>
                            <button onClick={closeAssetDetail} className="p-1.5 hover:bg-slate-100 rounded">
                                <X size={18} />
                            </button>
                        </div>
                        <div className="p-5 overflow-y-auto space-y-4">
                            {assetDetailError && (
                                <div className="rounded-lg border border-amber-100 bg-amber-50 px-3 py-2 text-xs font-medium text-amber-700">
                                    {assetDetailError}
                                </div>
                            )}
                            <div className="rounded-lg border border-slate-200 overflow-hidden">
                                <div className="px-4 py-3 bg-slate-50 border-b border-slate-200">
                                    <div className="text-sm font-bold text-slate-800">
                                        {regAssetDetail.data.cnName || regAssetDetail.data.name}
                                    </div>
                                    <div className="text-xs text-slate-500 font-mono mt-1">{regAssetDetail.data.name}</div>
                                </div>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 text-sm">
                                    <div>
                                        <div className="text-xs text-slate-400 mb-1">中文名</div>
                                        <div className="font-medium text-slate-700">{regAssetDetail.data.cnName || '-'}</div>
                                    </div>
                                    <div>
                                        <div className="text-xs text-slate-400 mb-1">英文名</div>
                                        <div className="font-medium text-slate-700 font-mono">{regAssetDetail.data.name || '-'}</div>
                                    </div>
                                    <div>
                                        <div className="text-xs text-slate-400 mb-1">状态</div>
                                        <div className="font-medium text-slate-700">{regAssetDetail.data.status === 1 ? '启用' : '停用'}</div>
                                    </div>
                                    <div>
                                        <div className="text-xs text-slate-400 mb-1">自动取数</div>
                                        <div className="font-medium text-slate-700">{regAssetDetail.data.autoFetchStatus || '-'}</div>
                                    </div>

                                    {regAssetDetail.type === 'TABLE' ? (
                                        <>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">所属系统</div>
                                                <div className="font-medium text-slate-700">{(regAssetDetail.data as RegTable).systemCode || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">报送频度</div>
                                                <div className="font-medium text-slate-700">{(regAssetDetail.data as RegTable).frequency || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">监管主题</div>
                                                <div className="font-medium text-slate-700">{(regAssetDetail.data as RegTable).theme || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">取数来源</div>
                                                <div className="font-medium text-slate-700">{(regAssetDetail.data as RegTable).sourceType || '-'}</div>
                                            </div>
                                            <div className="md:col-span-2">
                                                <div className="text-xs text-slate-400 mb-1">绑定物理表</div>
                                                <div className="space-y-1">
                                                    {((regAssetDetail.data as RegTable).physicalTables || []).length > 0
                                                        ? (regAssetDetail.data as RegTable).physicalTables?.map(item => (
                                                            <div key={item.modelTableId} className="font-mono text-xs bg-slate-100 px-2 py-1 rounded">
                                                                {[item.owner, item.tableName].filter(Boolean).join('.')}
                                                                {item.tableCnName ? <span className="ml-2 text-slate-500 font-sans">{item.tableCnName}</span> : null}
                                                            </div>
                                                        ))
                                                        : <span className="text-slate-400">-</span>}
                                                </div>
                                            </div>
                                        </>
                                    ) : (
                                        <>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">资产类型</div>
                                                <div className="font-medium text-slate-700">{(regAssetDetail.data as RegElement).type === 'INDICATOR' ? '指标' : '字段'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">数据类型</div>
                                                <div className="font-medium text-slate-700">{(regAssetDetail.data as RegElement).dataType || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">长度</div>
                                                <div className="font-medium text-slate-700">{(regAssetDetail.data as RegElement).length || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">允许为空</div>
                                                <div className="font-medium text-slate-700">{(regAssetDetail.data as RegElement).nullable ? '是' : '否'}</div>
                                            </div>
                                            <div className="md:col-span-2">
                                                <div className="text-xs text-slate-400 mb-1">绑定字段</div>
                                                <div className="space-y-1">
                                                    {((regAssetDetail.data as RegElement).physicalFields || []).length > 0
                                                        ? (regAssetDetail.data as RegElement).physicalFields?.map(item => (
                                                            <div key={item.modelFieldId} className="font-mono text-xs bg-slate-100 px-2 py-1 rounded">
                                                                {item.fieldName}
                                                                <span className="ml-2 text-slate-500 font-sans">
                                                                    {[item.fieldCnName, item.fieldType].filter(Boolean).join(' / ')}
                                                                </span>
                                                                <div className="mt-0.5 text-[10px] text-slate-400">
                                                                    {[item.owner, item.tableName].filter(Boolean).join('.')}
                                                                </div>
                                                            </div>
                                                        ))
                                                        : <span className="text-slate-400">-</span>}
                                                </div>
                                            </div>
                                        </>
                                    )}

                                    <div className="md:col-span-2">
                                        <div className="text-xs text-slate-400 mb-1">业务口径</div>
                                        <div className="font-medium text-slate-700 whitespace-pre-wrap">{regAssetDetail.data.businessCaliber || '-'}</div>
                                    </div>
                                    <div className="md:col-span-2">
                                        <div className="text-xs text-slate-400 mb-1">填报说明</div>
                                        <div className="font-medium text-slate-700 whitespace-pre-wrap">{regAssetDetail.data.fillInstruction || '-'}</div>
                                    </div>
                                    <div className="md:col-span-2">
                                        <div className="text-xs text-slate-400 mb-1">开发备注</div>
                                        <div className="font-medium text-slate-700 whitespace-pre-wrap">{regAssetDetail.data.devNotes || '-'}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end">
                            <button
                                onClick={closeAssetDetail}
                                className="px-4 py-2 text-sm font-bold text-slate-500 hover:bg-slate-50 rounded-lg"
                            >
                                关闭
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {assetDetailOpen && !regAssetDetail && (
                <div className="fixed inset-0 bg-black/30 z-[10000] flex items-center justify-center p-4">
                    <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-2xl max-h-[82vh] flex flex-col">
                        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                            <div>
                                <h3 className="font-bold text-slate-800">维护资产信息</h3>
                                <p className="text-xs text-slate-500 mt-1">
                                    {modelAssetDetail?.field ? '字段资产' : '表资产'}
                                </p>
                            </div>
                            <button onClick={closeAssetDetail} className="p-1.5 hover:bg-slate-100 rounded">
                                <X size={18} />
                            </button>
                        </div>
                        <div className="p-5 overflow-y-auto">
                            {assetDetailLoading ? (
                                <div className="text-center py-10 text-slate-400 bg-slate-50 rounded-lg border border-dashed border-slate-200">
                                    正在加载资产信息...
                                </div>
                            ) : modelAssetDetail ? (
                                <div className="space-y-4">
                                    {assetDetailError && (
                                        <div className="rounded-lg border border-amber-100 bg-amber-50 px-3 py-2 text-xs font-medium text-amber-700">
                                            {assetDetailError}
                                        </div>
                                    )}
                                    <div className="rounded-lg border border-slate-200 overflow-hidden">
                                        <div className="px-4 py-3 bg-slate-50 border-b border-slate-200">
                                            <div className="text-sm font-bold text-slate-800">
                                                {modelAssetDetail.table.cnName || modelAssetDetail.table.name}
                                            </div>
                                            <div className="text-xs text-slate-500 font-mono mt-1">{modelAssetDetail.table.name}</div>
                                        </div>
                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 text-sm">
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">表中文名</div>
                                                <div className="font-medium text-slate-700">{modelAssetDetail.table.cnName || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">表名</div>
                                                <div className="font-medium text-slate-700 font-mono">{modelAssetDetail.table.name || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">Schema / Owner</div>
                                                <div className="font-medium text-slate-700">{modelAssetDetail.table.owner || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">数据源</div>
                                                <div className="font-medium text-slate-700">{modelAssetDetail.table.dataSourceId || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">主题</div>
                                                <div className="font-medium text-slate-700">{modelAssetDetail.table.theme || '-'}</div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400 mb-1">频度</div>
                                                <div className="font-medium text-slate-700">{modelAssetDetail.table.freq || '-'}</div>
                                            </div>
                                            <div className="md:col-span-2">
                                                <div className="text-xs text-slate-400 mb-1">备注</div>
                                                <div className="font-medium text-slate-700 whitespace-pre-wrap">{modelAssetDetail.table.remark || '-'}</div>
                                            </div>
                                        </div>
                                    </div>

                                    {modelAssetDetail.field && (
                                        <div className="rounded-lg border border-slate-200 overflow-hidden">
                                            <div className="px-4 py-3 bg-cyan-50 border-b border-cyan-100">
                                                <div className="text-sm font-bold text-slate-800">
                                                    {modelAssetDetail.field.cnName || modelAssetDetail.field.name}
                                                </div>
                                                <div className="text-xs text-slate-500 font-mono mt-1">{modelAssetDetail.field.name}</div>
                                            </div>
                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 text-sm">
                                                <div>
                                                    <div className="text-xs text-slate-400 mb-1">字段中文名</div>
                                                    <div className="font-medium text-slate-700">{modelAssetDetail.field.cnName || '-'}</div>
                                                </div>
                                                <div>
                                                    <div className="text-xs text-slate-400 mb-1">字段名</div>
                                                    <div className="font-medium text-slate-700 font-mono">{modelAssetDetail.field.name || '-'}</div>
                                                </div>
                                                <div>
                                                    <div className="text-xs text-slate-400 mb-1">字段类型</div>
                                                    <div className="font-medium text-slate-700">{modelAssetDetail.field.type || '-'}</div>
                                                </div>
                                                <div>
                                                    <div className="text-xs text-slate-400 mb-1">排序</div>
                                                    <div className="font-medium text-slate-700">{modelAssetDetail.field.sortOrder ?? '-'}</div>
                                                </div>
                                                <div>
                                                    <div className="text-xs text-slate-400 mb-1">主键</div>
                                                    <div className="font-medium text-slate-700">{modelAssetDetail.field.isPk ? '是' : '否'}</div>
                                                </div>
                                                <div>
                                                    <div className="text-xs text-slate-400 mb-1">允许为空</div>
                                                    <div className="font-medium text-slate-700">{modelAssetDetail.field.nullable ? '是' : '否'}</div>
                                                </div>
                                                <div className="md:col-span-2">
                                                    <div className="text-xs text-slate-400 mb-1">备注</div>
                                                    <div className="font-medium text-slate-700 whitespace-pre-wrap">{modelAssetDetail.field.remark || '-'}</div>
                                                </div>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            ) : (
                                <div className="rounded-lg border border-amber-100 bg-amber-50 px-3 py-8 text-center text-sm font-medium text-amber-700">
                                    {assetDetailError || '未找到对应的资产信息'}
                                </div>
                            )}
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end">
                            <button
                                onClick={closeAssetDetail}
                                className="px-4 py-2 text-sm font-bold text-slate-500 hover:bg-slate-50 rounded-lg"
                            >
                                关闭
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {appealTask && (
                <div className="fixed inset-0 bg-black/30 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-lg">
                        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                            <h3 className="font-bold text-slate-800">发起申诉</h3>
                            <button onClick={() => setAppealTask(null)} className="p-1.5 hover:bg-slate-100 rounded">
                                <X size={18} />
                            </button>
                        </div>
                        <div className="p-5 space-y-4">
                            <textarea
                                value={appealForm.reason}
                                onChange={e => setAppealForm({ ...appealForm, reason: e.target.value })}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[90px]"
                                placeholder="申诉原因 *"
                            />
                            <textarea
                                value={appealForm.expectedResult}
                                onChange={e => setAppealForm({ ...appealForm, expectedResult: e.target.value })}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[70px]"
                                placeholder="期望处理结果"
                            />
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end gap-2">
                            <button onClick={() => setAppealTask(null)} className="px-4 py-2 text-sm font-bold text-slate-500 hover:bg-slate-50 rounded-lg">取消</button>
                            <button onClick={handleAppeal} className="px-4 py-2 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg">提交申诉</button>
                        </div>
                    </div>
                </div>
            )}

            {riskTask && (
                <div className="fixed inset-0 bg-black/30 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-lg">
                        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                            <div>
                                <h3 className="font-bold text-slate-800">阶段风险报备</h3>
                                <p className="text-xs text-slate-500 mt-1">
                                    {riskTask.title} · {getTaskStageLabel(riskTask.currentStage)}
                                </p>
                            </div>
                            <button onClick={() => setRiskTask(null)} className="p-1.5 hover:bg-slate-100 rounded">
                                <X size={18} />
                            </button>
                        </div>
                        <div className="p-5">
                            <textarea
                                value={riskNote}
                                onChange={e => setRiskNote(e.target.value)}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[110px]"
                                placeholder="请说明当前阶段风险、影响和需要协调的事项 *"
                            />
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end gap-2">
                            <button onClick={() => setRiskTask(null)} className="px-4 py-2 text-sm font-bold text-slate-500 hover:bg-slate-50 rounded-lg">取消</button>
                            <button onClick={handleReportRisk} className="px-4 py-2 text-sm font-bold text-white bg-amber-600 hover:bg-amber-700 rounded-lg">提交报备</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default MyTasks;
