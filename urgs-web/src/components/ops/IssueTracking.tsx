import React, { useState, useEffect, useCallback } from 'react';
import { AlertCircle, CheckCircle, Clock, Filter, Plus, Search, ArrowRight, FileText, Hourglass, Download, Upload, Edit, Eye, X, RefreshCw, LayoutList, BarChart3, Trash2, Sparkles } from 'lucide-react';
import Auth from '../Auth';
import IssueStats from './IssueStats';
import UserSelect from './UserSelect';
import Pagination from '../common/Pagination';

interface Issue {
    id: string;
    title: string;
    description: string;
    system: string;
    solution: string;
    occurTime: string;
    reporter: string;
    resolveTime: string;
    handler: string;
    issueType: '批量任务处理' | '报送支持' | '数据查询';
    status: '新建' | '处理中' | '完成' | '遗留';
    workHours: number;
}

interface IssueTrackingProps {
    initialData?: any;
}

const IssueTracking: React.FC<IssueTrackingProps> = ({ initialData }) => {
    const [viewMode, setViewMode] = useState<'list' | 'chart'>('list');
    const [frequency, setFrequency] = useState('month');
    const [filterStatus, setFilterStatus] = useState('all');
    const [filterType, setFilterType] = useState('all');
    const [filterSystem, setFilterSystem] = useState('');
    const [filterReporter, setFilterReporter] = useState('');
    const [filterStartTime, setFilterStartTime] = useState('');
    const [filterEndTime, setFilterEndTime] = useState('');
    const [keyword, setKeyword] = useState('');
    const [showModal, setShowModal] = useState(false);
    const [showDetailModal, setShowDetailModal] = useState(false);
    const [selectedIssue, setSelectedIssue] = useState<Issue | null>(null);
    const [formData, setFormData] = useState<Partial<Issue>>({});
    const [issues, setIssues] = useState<Issue[]>([]);
    const [loading, setLoading] = useState(false);
    const [currentPage, setCurrentPage] = useState(1);
    const [total, setTotal] = useState(0);
    // const [totalPages, setTotalPages] = useState(1); // No longer needed as Pagination calculates it or we rely on total
    const [saving, setSaving] = useState(false);
    const [systems, setSystems] = useState<any[]>([]);
    const [aiGenerating, setAiGenerating] = useState(false);

    useEffect(() => {
        fetchSystems();
    }, []);

    const fetchSystems = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/sys/system/list', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setSystems(data);
            }
        } catch (error) {
            console.error('Failed to fetch systems:', error);
        }
    };

    const fetchIssues = useCallback(async () => {
        setLoading(true);
        try {
            const params = new URLSearchParams({
                current: currentPage.toString(),
                size: '10',
                status: filterStatus,
                issueType: filterType,
            });
            if (filterSystem) params.append('system', filterSystem);
            if (filterReporter) params.append('reporter', filterReporter);
            if (filterStartTime) params.append('startTime', filterStartTime);
            if (filterEndTime) params.append('endTime', filterEndTime);
            if (keyword) {
                params.append('keyword', keyword);
            }

            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/issue/list?${params.toString()}`, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                }
            });

            if (res.ok) {
                const data = await res.json();
                setIssues(data.records || []);
                setTotal(data.total || 0);
            }
        } catch (error) {
            console.error('Failed to fetch issues:', error);
        } finally {
            setLoading(false);
        }
    }, [currentPage, filterStatus, filterType, filterSystem, filterReporter, filterStartTime, filterEndTime, keyword]);

    useEffect(() => {
        fetchIssues();
    }, [fetchIssues]);

    useEffect(() => {
        if (initialData) {
            setFormData(initialData);
            setShowModal(true);
        }
    }, [initialData]);

    const handleSave = async () => {
        if (formData.status === '完成') {
            if (!formData.solution?.trim()) {
                alert('状态为完成时，解决方案不能为空');
                return;
            }
            if (!formData.resolveTime) {
                alert('状态为完成时，解决时间不能为空');
                return;
            }
            if (!formData.workHours || formData.workHours <= 0) {
                alert('状态为完成时，工时必须大于 0');
                return;
            }
        }

        setSaving(true);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/issue/save', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(formData)
            });

            if (res.ok) {
                setShowModal(false);
                setFormData({});
                fetchIssues();
            } else {
                alert('保存失败，请重试');
            }
        } catch (error) {
            console.error('Failed to save issue:', error);
            alert('保存失败，请重试');
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('确定要删除此问题吗？')) return;

        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/issue/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                fetchIssues();
            } else {
                alert('删除失败');
            }
        } catch (error) {
            console.error('Failed to delete issue:', error);
        }
    };

    const getStatusStyle = (status: Issue['status']) => {
        switch (status) {
            case '新建':
                return 'bg-red-50 text-red-700 border-red-100';
            case '处理中':
                return 'bg-blue-50 text-blue-700 border-blue-100';
            case '完成':
                return 'bg-green-50 text-green-700 border-green-100';
            case '遗留':
                return 'bg-amber-50 text-amber-700 border-amber-100';
            default:
                return 'bg-slate-50 text-slate-500 border-slate-200';
        }
    };

    const getStatusIcon = (status: Issue['status']) => {
        switch (status) {
            case '新建':
                return <AlertCircle size={12} />;
            case '处理中':
                return <Clock size={12} />;
            case '完成':
                return <CheckCircle size={12} />;
            case '遗留':
                return <Hourglass size={12} />;
            default:
                return null;
        }
    };

    const getIssueTypeStyle = (type: Issue['issueType']) => {
        switch (type) {
            case '批量任务处理':
                return 'bg-purple-50 text-purple-700 border-purple-100';
            case '报送支持':
                return 'bg-cyan-50 text-cyan-700 border-cyan-100';
            case '数据查询':
                return 'bg-indigo-50 text-indigo-700 border-indigo-100';
            default:
                return 'bg-slate-50 text-slate-500 border-slate-200';
        }
    };

    const handleViewDetail = (issue: Issue) => {
        setSelectedIssue(issue);
        setShowDetailModal(true);
    };

    const handleEdit = (issue: Issue) => {
        setFormData(issue);
        setShowModal(true);
    };

    const handleGenerateSolution = async () => {
        const description = formData.description?.trim();
        if (!description) {
            alert('请先填写问题描述，再生成解决方案');
            return;
        }

        if (formData.solution?.trim()) {
            const confirmed = confirm('当前已有解决方案内容，是否覆盖并重新生成？');
            if (!confirmed) return;
        }

        setAiGenerating(true);
        setFormData(prev => ({ ...prev, solution: '' }));

        try {
            const token = localStorage.getItem('auth_token');
            const response = await fetch('/api/ai/chat/stream', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    systemPrompt: '你是资深运维工程师。请根据问题描述生成排查思路与可执行的解决方案。回答必须言简意赅，直接列出核心步骤，避免冗长的解释或废话。使用条目清晰的中文。',
                    userPrompt: `问题标题：${formData.title || '未填写'}\n问题描述：\n${description}`
                })
            });

            if (!response.ok) {
                throw new Error('Failed to start generation');
            }

            const reader = response.body?.getReader();
            const decoder = new TextDecoder();

            if (!reader) return;

            let buffer = '';

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                const chunk = decoder.decode(value, { stream: true });
                buffer += chunk;

                const lines = buffer.split('\n');
                buffer = lines.pop() || '';

                for (const line of lines) {
                    const trimmedLine = line.trim();
                    if (!trimmedLine) continue;

                    if (trimmedLine.startsWith('data:')) {
                        const dataStr = trimmedLine.replace(/^data:\s?/, '').trim();
                        if (dataStr === '[DONE]') break;

                        try {
                            const parsed = JSON.parse(dataStr);
                            if (parsed.content) {
                                setFormData(prev => ({
                                    ...prev,
                                    solution: `${prev.solution || ''}${parsed.content}`
                                }));
                            } else if (parsed.error) {
                                alert('生成出错: ' + parsed.error);
                            }
                        } catch (e) {
                            console.error('JSON parse error', e);
                        }
                    }
                }
            }
        } catch (error) {
            console.error('Generation failed:', error);
            alert('生成失败，请重试');
        } finally {
            setAiGenerating(false);
        }
    };

    const handleExport = async () => {
        const params = new URLSearchParams({
            status: filterStatus,
            issueType: filterType,
        });
        if (keyword) {
            params.append('keyword', keyword);
        }

        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/issue/export?${params.toString()}`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (res.ok) {
                const blob = await res.blob();
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                // 从响应头获取文件名，或者是默认文件名
                const contentDisposition = res.headers.get('Content-Disposition');
                let fileName = 'issue_export.xlsx';
                if (contentDisposition) {
                    const params = new URLSearchParams(contentDisposition.replace(/;/g, '&'));
                    const filenameStar = params.get('filename*');
                    if (filenameStar && filenameStar.startsWith("UTF-8''")) {
                        fileName = decodeURIComponent(filenameStar.substring(7));
                    } else {
                        const filename = params.get('filename');
                        if (filename) fileName = filename;
                    }
                }

                a.download = fileName;
                document.body.appendChild(a);
                a.click();
                window.URL.revokeObjectURL(url);
                document.body.removeChild(a);
            } else {
                alert('导出失败');
            }
        } catch (error) {
            console.error('Export failed:', error);
            alert('导出失败');
        }
    };

    const handleImport = () => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.xlsx,.xls';
        input.onchange = async (e: any) => {
            const file = e.target.files?.[0];
            if (!file) return;

            const formData = new FormData();
            formData.append('file', file);

            try {
                const token = localStorage.getItem('auth_token');
                const res = await fetch('/api/issue/import', {
                    method: 'POST',
                    headers: { 'Authorization': `Bearer ${token}` },
                    body: formData
                });

                if (res.ok) {
                    alert('导入成功');
                    fetchIssues();
                } else {
                    const msg = await res.text();
                    alert(msg || '导入失败');
                }
            } catch (error) {
                console.error('Import failed:', error);
                alert('导入失败');
            }
        };
        input.click();
    };

    return (
        <div className="space-y-6 animate-fade-in">
            {/* View Switcher & Title */}
            <div className="flex justify-between items-center">
                <div className="flex items-center gap-4">
                    <div className="bg-slate-100 p-1 rounded-lg inline-flex">
                        <button
                            onClick={() => setViewMode('list')}
                            className={`flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-all ${viewMode === 'list'
                                ? 'bg-white text-slate-800 shadow-sm'
                                : 'text-slate-500 hover:text-slate-700'
                                }`}
                        >
                            <LayoutList size={16} />
                            列表视图
                        </button>
                        <button
                            onClick={() => setViewMode('chart')}
                            className={`flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-all ${viewMode === 'chart'
                                ? 'bg-white text-slate-800 shadow-sm'
                                : 'text-slate-500 hover:text-slate-700'
                                }`}
                        >
                            <BarChart3 size={16} />
                            统计图表
                        </button>
                    </div>

                    {viewMode === 'chart' && (
                        <select
                            value={frequency}
                            onChange={(e) => setFrequency(e.target.value)}
                            className="text-sm border border-slate-200 rounded-md px-3 py-1.5 outline-none focus:ring-2 focus:ring-blue-500 bg-white text-slate-600 shadow-sm"
                        >
                            <option value="day">日报表</option>
                            <option value="month">月报表</option>
                            <option value="quarter">季报表</option>
                            <option value="half">半年报</option>
                            <option value="year">年报表</option>
                        </select>
                    )}
                </div>

                {viewMode === 'list' && (
                    <Auth code="ops:issue:create">
                        <button
                            className="flex items-center gap-1 bg-red-600 text-white px-3 py-1.5 rounded-md text-sm font-medium hover:bg-red-700 transition-colors shadow-sm"
                            onClick={() => {
                                setFormData({});
                                setShowModal(true);
                            }}
                        >
                            <Plus size={16} />
                            <span>登记问题</span>
                        </button>
                    </Auth>
                )}
            </div>

            {/* Chart View */}
            {viewMode === 'chart' && (
                <IssueStats frequency={frequency} />
            )}

            {/* List View */}
            {viewMode === 'list' && (
                <>
                    {/* Header & Actions */}
                    <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex flex-col gap-4">
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                            {/* System Filter */}
                            <select
                                className="border border-slate-200 rounded-md text-sm py-1.5 px-3 focus:ring-2 focus:ring-red-500 outline-none text-slate-600"
                                value={filterSystem}
                                onChange={(e) => setFilterSystem(e.target.value)}
                            >
                                <option value="">所有系统</option>
                                {systems.map((sys: any) => (
                                    <option key={sys.id} value={sys.name}>{sys.name}</option>
                                ))}
                            </select>

                            {/* Issue Type Filter */}
                            <select
                                className="border border-slate-200 rounded-md text-sm py-1.5 px-3 focus:ring-2 focus:ring-red-500 outline-none text-slate-600"
                                value={filterType}
                                onChange={(e) => setFilterType(e.target.value)}
                            >
                                <option value="all">所有类型</option>
                                <option value="批量任务处理">批量任务处理</option>
                                <option value="报送支持">报送支持</option>
                                <option value="数据查询">数据查询</option>
                            </select>

                            {/* Status Filter */}
                            <select
                                className="border border-slate-200 rounded-md text-sm py-1.5 px-3 focus:ring-2 focus:ring-red-500 outline-none text-slate-600"
                                value={filterStatus}
                                onChange={(e) => setFilterStatus(e.target.value)}
                            >
                                <option value="all">所有状态</option>
                                <option value="新建">新建</option>
                                <option value="处理中">处理中</option>
                                <option value="完成">完成</option>
                                <option value="遗留">遗留</option>
                            </select>

                            {/* Reporter Filter */}
                            <input
                                type="text"
                                placeholder="提出人姓名..."
                                className="border border-slate-200 rounded-md text-sm py-1.5 px-3 focus:ring-2 focus:ring-red-500 outline-none"
                                value={filterReporter}
                                onChange={(e) => setFilterReporter(e.target.value)}
                            />
                        </div>

                        <div className="flex flex-col sm:flex-row gap-4 items-center">
                            {/* Time Range */}
                            <div className="flex items-center gap-2 text-sm text-slate-600 whitespace-nowrap">
                                <Clock size={16} className="text-slate-400" />
                                <span>发生时间:</span>
                                <input
                                    type="date"
                                    className="border border-slate-200 rounded-md py-1.5 px-2 text-sm focus:ring-2 focus:ring-red-500 outline-none"
                                    value={filterStartTime}
                                    onChange={(e) => setFilterStartTime(e.target.value)}
                                />
                                <span>至</span>
                                <input
                                    type="date"
                                    className="border border-slate-200 rounded-md py-1.5 px-2 text-sm focus:ring-2 focus:ring-red-500 outline-none"
                                    value={filterEndTime}
                                    onChange={(e) => setFilterEndTime(e.target.value)}
                                />
                            </div>

                            {/* Keyword Search (Expanded) */}
                            <div className="relative flex-1 w-full">
                                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                                <input
                                    type="text"
                                    placeholder="搜索问题标题/ID..."
                                    className="w-full pl-9 pr-3 py-1.5 border border-slate-200 rounded-md text-sm focus:ring-2 focus:ring-red-500 outline-none"
                                    value={keyword}
                                    onChange={(e) => setKeyword(e.target.value)}
                                />
                            </div>
                        </div>
                        <div className="flex items-center gap-2">
                            <button
                                className="flex items-center gap-1 border border-slate-300 text-slate-600 px-3 py-1.5 rounded-md text-sm font-medium hover:bg-slate-100 transition-colors"
                                onClick={handleImport}
                            >
                                <Upload size={16} />
                                <span>导入</span>
                            </button>
                            <button
                                className="flex items-center gap-1 border border-slate-300 text-slate-600 px-3 py-1.5 rounded-md text-sm font-medium hover:bg-slate-100 transition-colors"
                                onClick={handleExport}
                            >
                                <Download size={16} />
                                <span>导出</span>
                            </button>
                        </div>
                    </div>

                    {/* Issue List */}
                    <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
                        <div className="overflow-x-auto">
                            <table className="w-full text-sm text-left">
                                <thead className="bg-slate-50 text-slate-500 font-medium border-b border-slate-200">
                                    <tr>
                                        <th className="px-4 py-3 whitespace-nowrap">问题标题</th>
                                        <th className="px-4 py-3 whitespace-nowrap">涉及系统</th>
                                        <th className="px-4 py-3 whitespace-nowrap">发生时间</th>
                                        <th className="px-4 py-3 whitespace-nowrap">提出人</th>
                                        <th className="px-4 py-3 whitespace-nowrap">解决时间</th>
                                        <th className="px-4 py-3 whitespace-nowrap">处理人</th>
                                        <th className="px-4 py-3 whitespace-nowrap">问题类型</th>
                                        <th className="px-4 py-3 whitespace-nowrap">状态</th>
                                        <th className="px-4 py-3 whitespace-nowrap">工时(h)</th>
                                        <th className="px-4 py-3 text-right whitespace-nowrap">操作</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {loading ? (
                                        <tr>
                                            <td colSpan={10} className="px-4 py-8 text-center text-slate-500">
                                                <RefreshCw className="w-6 h-6 animate-spin mx-auto mb-2" />
                                                加载中...
                                            </td>
                                        </tr>
                                    ) : issues.length === 0 ? (
                                        <tr>
                                            <td colSpan={10} className="px-4 py-8 text-center text-slate-500">
                                                暂无问题记录
                                            </td>
                                        </tr>
                                    ) : issues.map((issue) => (
                                        <tr key={issue.id} className="hover:bg-slate-50 transition-colors group">
                                            <td className="px-4 py-3">
                                                <div className="font-medium text-slate-800 max-w-[200px] truncate" title={issue.title}>{issue.title}</div>
                                                <div className="text-xs text-slate-400 font-mono">{issue.id}</div>
                                            </td>
                                            <td className="px-4 py-3 text-slate-600 whitespace-nowrap">{issue.system}</td>
                                            <td className="px-4 py-3 text-slate-600 whitespace-nowrap">{issue.occurTime}</td>
                                            <td className="px-4 py-3 text-slate-600 whitespace-nowrap">{issue.reporter}</td>
                                            <td className="px-4 py-3 text-slate-600 whitespace-nowrap">{issue.resolveTime || '-'}</td>
                                            <td className="px-4 py-3 text-slate-600 whitespace-nowrap">{issue.handler || '-'}</td>
                                            <td className="px-4 py-3 whitespace-nowrap">
                                                <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium border ${getIssueTypeStyle(issue.issueType)}`}>
                                                    <FileText size={12} />
                                                    {issue.issueType}
                                                </span>
                                            </td>
                                            <td className="px-4 py-3 whitespace-nowrap">
                                                <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium border ${getStatusStyle(issue.status)}`}>
                                                    {getStatusIcon(issue.status)}
                                                    {issue.status}
                                                </span>
                                            </td>
                                            <td className="px-4 py-3 text-slate-600 text-center whitespace-nowrap">{issue.workHours > 0 ? issue.workHours : '-'}</td>
                                            <td className="px-4 py-3 text-right whitespace-nowrap">
                                                <div className="flex items-center justify-end gap-2">
                                                    <button
                                                        className="text-blue-600 hover:text-blue-800 text-xs flex items-center gap-1 px-2 py-1 rounded hover:bg-blue-50 transition-colors"
                                                        onClick={() => handleViewDetail(issue)}
                                                    >
                                                        <Eye size={14} />
                                                        详情
                                                    </button>
                                                    <Auth code="ops:issue:create">
                                                        <button
                                                            className="text-amber-600 hover:text-amber-800 text-xs flex items-center gap-1 px-2 py-1 rounded hover:bg-amber-50 transition-colors"
                                                            onClick={() => handleEdit(issue)}
                                                        >
                                                            <Edit size={14} />
                                                            修改
                                                        </button>
                                                    </Auth>
                                                    <Auth code="ops:issue:delete">
                                                        <button
                                                            className="text-red-600 hover:text-red-800 text-xs flex items-center gap-1 px-2 py-1 rounded hover:bg-red-50 transition-colors"
                                                            onClick={() => handleDelete(issue.id)}
                                                        >
                                                            <Trash2 size={14} />
                                                            删除
                                                        </button>
                                                    </Auth>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                    {/* Pagination */}
                    <Pagination
                        current={currentPage}
                        total={total}
                        pageSize={10}
                        onChange={(page) => setCurrentPage(page)}
                        className="mt-4"
                    />
                </>
            )}

            {/* Issue Edit Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in">
                    <div className="bg-white rounded-lg shadow-xl w-[700px] max-h-[90vh] flex flex-col">
                        <div className="flex items-center justify-between p-4 border-b border-slate-100">
                            <h3 className="text-lg font-bold text-slate-800">
                                {formData.id ? '编辑问题' : '登记生产问题'}
                            </h3>
                            <button onClick={() => setShowModal(false)} className="text-slate-400 hover:text-slate-600">
                                <Plus size={24} className="rotate-45" />
                            </button>
                        </div>

                        <div className="p-6 overflow-y-auto flex-1 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">问题标题 <span className="text-red-500">*</span></label>
                                <input
                                    type="text"
                                    className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:ring-2 focus:ring-red-500 outline-none"
                                    value={formData.title || ''}
                                    onChange={e => setFormData({ ...formData, title: e.target.value })}
                                    placeholder="简明扼要描述问题..."
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">问题描述 <span className="text-red-500">*</span></label>
                                <textarea
                                    className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm h-24 focus:ring-2 focus:ring-red-500 outline-none resize-none"
                                    value={formData.description || ''}
                                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                                    placeholder="详细描述问题现象、报错日志片段..."
                                />
                            </div>

                            <div>
                                <div className="flex items-center justify-between mb-1">
                                    <label className="block text-sm font-medium text-slate-700">
                                        解决方案 {formData.status === '完成' && <span className="text-red-500">*</span>}
                                    </label>
                                    <button
                                        type="button"
                                        className="flex items-center gap-1 text-xs px-2 py-1 rounded border border-slate-200 text-slate-600 hover:bg-slate-100 transition-colors disabled:opacity-50"
                                        onClick={handleGenerateSolution}
                                        disabled={aiGenerating}
                                        title="AI 生成解决方案"
                                    >
                                        <Sparkles size={12} />
                                        <span>{aiGenerating ? '生成中...' : 'AI 生成'}</span>
                                    </button>
                                </div>
                                <textarea
                                    className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm h-24 focus:ring-2 focus:ring-red-500 outline-none resize-none"
                                    value={formData.solution || ''}
                                    onChange={e => setFormData({ ...formData, solution: e.target.value })}
                                    placeholder="描述问题的排查过程和最终解决方案..."
                                />
                                <p className="text-xs text-slate-400 mt-1">AI 生成内容仅供参考，请结合实际情况调整。</p>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">涉及系统 <span className="text-red-500">*</span></label>
                                    <select
                                        className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-red-500"
                                        value={formData.system || ''}
                                        onChange={e => setFormData({ ...formData, system: e.target.value })}
                                    >
                                        <option value="">请选择系统</option>
                                        {systems.map((sys: any) => (
                                            <option key={sys.id} value={sys.name}>{sys.name}</option>
                                        ))}
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">问题类型 <span className="text-red-500">*</span></label>
                                    <select
                                        className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-red-500"
                                        value={formData.issueType || '批量任务处理'}
                                        onChange={e => setFormData({ ...formData, issueType: e.target.value as Issue['issueType'] })}
                                    >
                                        <option value="批量任务处理">批量任务处理</option>
                                        <option value="报送支持">报送支持</option>
                                        <option value="数据查询">数据查询</option>
                                    </select>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">发生时间 <span className="text-red-500">*</span></label>
                                    <input
                                        type="datetime-local"
                                        className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-red-500"
                                        value={formData.occurTime || ''}
                                        onChange={e => setFormData({ ...formData, occurTime: e.target.value })}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">提出人 <span className="text-red-500">*</span></label>
                                    <UserSelect
                                        value={formData.reporter || ''}
                                        onChange={(val) => setFormData({ ...formData, reporter: val })}
                                        placeholder="输入提出人姓名"
                                    />
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">
                                        解决时间 {formData.status === '完成' && <span className="text-red-500">*</span>}
                                    </label>
                                    <input
                                        type="datetime-local"
                                        className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-red-500"
                                        value={formData.resolveTime || ''}
                                        onChange={e => setFormData({ ...formData, resolveTime: e.target.value })}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">处理人</label>
                                    <UserSelect
                                        value={formData.handler || ''}
                                        onChange={(val) => setFormData({ ...formData, handler: val })}
                                        placeholder="输入处理人姓名"
                                    />
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">状态</label>
                                    <select
                                        className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-red-500"
                                        value={formData.status || '新建'}
                                        onChange={e => setFormData({ ...formData, status: e.target.value as Issue['status'] })}
                                    >
                                        <option value="新建">新建</option>
                                        <option value="处理中">处理中</option>
                                        <option value="完成">完成</option>
                                        <option value="遗留">遗留</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">
                                        工时 (小时) {formData.status === '完成' && <span className="text-red-500">*</span>}
                                    </label>
                                    <input
                                        type="number"
                                        step="0.5"
                                        min="0"
                                        className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-red-500"
                                        value={formData.workHours || ''}
                                        onChange={e => setFormData({ ...formData, workHours: parseFloat(e.target.value) || 0 })}
                                        placeholder="例如: 2.5"
                                    />
                                </div>
                            </div>
                        </div>

                        <div className="p-4 border-t border-slate-100 flex justify-end gap-2 bg-slate-50 rounded-b-lg">
                            <button
                                onClick={() => setShowModal(false)}
                                className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-md text-sm font-medium transition-colors"
                            >
                                取消
                            </button>
                            <button
                                className="px-4 py-2 bg-red-600 text-white rounded-md text-sm font-medium hover:bg-red-700 transition-colors shadow-sm disabled:opacity-50"
                                onClick={handleSave}
                                disabled={saving}
                            >
                                {saving ? '保存中...' : '提交'}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Issue Detail Modal */}
            {showDetailModal && selectedIssue && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in">
                    <div className="bg-white rounded-lg shadow-xl w-[700px] max-h-[90vh] flex flex-col">
                        <div className="flex items-center justify-between p-4 border-b border-slate-100">
                            <h3 className="text-lg font-bold text-slate-800">问题详情</h3>
                            <button onClick={() => setShowDetailModal(false)} className="text-slate-400 hover:text-slate-600">
                                <X size={24} />
                            </button>
                        </div>

                        <div className="p-6 overflow-y-auto flex-1 space-y-4">
                            <div className="flex items-start gap-4">
                                <div className="flex-1">
                                    <div className="text-xs text-slate-400 font-mono mb-1">{selectedIssue.id}</div>
                                    <h4 className="text-lg font-semibold text-slate-800">{selectedIssue.title}</h4>
                                </div>
                                <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium border ${getStatusStyle(selectedIssue.status)}`}>
                                    {getStatusIcon(selectedIssue.status)}
                                    {selectedIssue.status}
                                </span>
                            </div>

                            <div className="bg-slate-50 rounded-lg p-4">
                                <label className="block text-sm font-medium text-slate-500 mb-2">问题描述</label>
                                <p className="text-slate-700 whitespace-pre-wrap">{selectedIssue.description || '暂无描述'}</p>
                            </div>

                            <div className="bg-slate-50 rounded-lg p-4">
                                <label className="block text-sm font-medium text-slate-500 mb-2">解决方案</label>
                                <p className="text-slate-700 whitespace-pre-wrap">{selectedIssue.solution || '暂无解决方案'}</p>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div className="bg-slate-50 rounded-lg p-3">
                                    <label className="block text-xs font-medium text-slate-500 mb-1">涉及系统</label>
                                    <p className="text-slate-700 font-medium">{selectedIssue.system}</p>
                                </div>
                                <div className="bg-slate-50 rounded-lg p-3">
                                    <label className="block text-xs font-medium text-slate-500 mb-1">问题类型</label>
                                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium border ${getIssueTypeStyle(selectedIssue.issueType)}`}>
                                        <FileText size={12} />
                                        {selectedIssue.issueType}
                                    </span>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div className="bg-slate-50 rounded-lg p-3">
                                    <label className="block text-xs font-medium text-slate-500 mb-1">发生时间</label>
                                    <p className="text-slate-700">{selectedIssue.occurTime}</p>
                                </div>
                                <div className="bg-slate-50 rounded-lg p-3">
                                    <label className="block text-xs font-medium text-slate-500 mb-1">提出人</label>
                                    <p className="text-slate-700 font-medium">{selectedIssue.reporter}</p>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div className="bg-slate-50 rounded-lg p-3">
                                    <label className="block text-xs font-medium text-slate-500 mb-1">解决时间</label>
                                    <p className="text-slate-700">{selectedIssue.resolveTime || '-'}</p>
                                </div>
                                <div className="bg-slate-50 rounded-lg p-3">
                                    <label className="block text-xs font-medium text-slate-500 mb-1">处理人</label>
                                    <p className="text-slate-700 font-medium">{selectedIssue.handler || '-'}</p>
                                </div>
                            </div>

                            <div className="bg-slate-50 rounded-lg p-3">
                                <label className="block text-xs font-medium text-slate-500 mb-1">工时</label>
                                <p className="text-slate-700 font-medium">{selectedIssue.workHours > 0 ? `${selectedIssue.workHours} 小时` : '-'}</p>
                            </div>
                        </div>

                        <div className="p-4 border-t border-slate-100 flex justify-end gap-2 bg-slate-50 rounded-b-lg">
                            <button
                                onClick={() => setShowDetailModal(false)}
                                className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-md text-sm font-medium transition-colors"
                            >
                                关闭
                            </button>
                            <Auth code="ops:issue:create">
                                <button
                                    className="px-4 py-2 bg-amber-500 text-white rounded-md text-sm font-medium hover:bg-amber-600 transition-colors shadow-sm"
                                    onClick={() => {
                                        setShowDetailModal(false);
                                        handleEdit(selectedIssue);
                                    }}
                                >
                                    编辑
                                </button>
                            </Auth>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default IssueTracking;
