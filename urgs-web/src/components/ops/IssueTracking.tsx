import React, { useState, useEffect, useCallback } from 'react';
import { Filter, Plus, Search, ArrowRight, FileText, Download, Upload, Edit, Eye, X, RefreshCw, LayoutList, BarChart3, Trash2, AlertCircle, Clock, CheckCircle, Hourglass, Sparkles, Paperclip, Calendar } from 'lucide-react';
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
    attachmentPath?: string; // JSON array string
    attachmentName?: string; // JSON array string
}

interface IssueTrackingProps {
    initialData?: any;
}

const IssueTracking: React.FC<IssueTrackingProps> = ({ initialData }) => {
    const [viewMode, setViewMode] = useState<'list' | 'chart'>('list');
    const [filterStatus, setFilterStatus] = useState('all');
    const [filterType, setFilterType] = useState('all');
    const [filterSystem, setFilterSystem] = useState('');
    const [filterReporter, setFilterReporter] = useState('');
    const [filterHandler, setFilterHandler] = useState('');
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
    const [isUploading, setIsUploading] = useState(false);
    const [selectedRowKeys, setSelectedRowKeys] = useState<string[]>([]);
    const [uploadFiles, setUploadFiles] = useState<{ name: string, path: string }[]>([]);
    const [showAdvanced, setShowAdvanced] = useState(false);

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
            if (filterHandler) params.append('handler', filterHandler);
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
    }, [currentPage, filterStatus, filterType, filterSystem, filterReporter, filterHandler, filterStartTime, filterEndTime, keyword]);

    useEffect(() => {
        fetchIssues();
    }, [fetchIssues]);

    useEffect(() => {
        if (initialData) {
            setFormData(initialData);
            if (initialData.attachmentPath) {
                try {
                    const paths = JSON.parse(initialData.attachmentPath);
                    const names = initialData.attachmentName ? JSON.parse(initialData.attachmentName) : [];
                    const files = paths.map((path: string, index: number) => ({
                        path,
                        name: names[index] || 'attachment'
                    }));
                    setUploadFiles(files);
                } catch (e) {
                    // Legacy single file support
                    setUploadFiles([{ name: initialData.attachmentName || 'attachment', path: initialData.attachmentPath }]);
                }
            } else {
                setUploadFiles([]);
            }
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
                body: JSON.stringify({
                    ...formData,
                    attachmentPath: uploadFiles.length > 0 ? JSON.stringify(uploadFiles.map(f => f.path)) : undefined,
                    attachmentName: uploadFiles.length > 0 ? JSON.stringify(uploadFiles.map(f => f.name)) : undefined
                })
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
                setSelectedRowKeys(prev => prev.filter(k => k !== id));
            } else {
                alert('删除失败');
            }
        } catch (error) {
            console.error('Failed to delete issue:', error);
        }
    };

    const handleBatchDelete = async () => {
        if (selectedRowKeys.length === 0) return;
        if (!confirm(`确定要删除选中的 ${selectedRowKeys.length} 个问题吗？`)) return;

        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/issue/batch-delete', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(selectedRowKeys)
            });
            if (res.ok) {
                fetchIssues();
                setSelectedRowKeys([]);
            } else {
                alert('批量删除失败');
            }
        } catch (error) {
            console.error('Failed to batch delete:', error);
            alert('批量删除出错');
        }
    }

    const toggleSelectAll = () => {
        if (selectedRowKeys.length === issues.length) {
            setSelectedRowKeys([]);
        } else {
            setSelectedRowKeys(issues.map(i => i.id));
        }
    };

    const toggleSelectRow = (id: string) => {
        if (selectedRowKeys.includes(id)) {
            setSelectedRowKeys(prev => prev.filter(k => k !== id));
        } else {
            setSelectedRowKeys(prev => [...prev, id]);
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
            handler: filterHandler,
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

    const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = e.target.files;
        if (!files || files.length === 0) return;

        setIsUploading(true);
        const token = localStorage.getItem('auth_token');

        try {
            const newFiles: { name: string, path: string }[] = [];
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                if (file.size > 200 * 1024 * 1024) {
                    alert(`文件 ${file.name} 大小超过 200MB，已跳过`);
                    continue;
                }

                const uploadData = new FormData();
                uploadData.append('file', file);

                const res = await fetch('/api/issue/upload', {
                    method: 'POST',
                    headers: { 'Authorization': `Bearer ${token}` },
                    body: uploadData
                });

                if (res.ok) {
                    const path = await res.text();
                    newFiles.push({ name: file.name, path });
                } else {
                    alert(`文件 ${file.name} 上传失败`);
                }
            }

            setUploadFiles(prev => [...prev, ...newFiles]);
        } catch (error) {
            console.error(error);
            alert('上传出错');
        } finally {
            setIsUploading(false);
            // Reset input
            e.target.value = '';
        }
    };

    const handleRemoveAttachment = (index: number) => {
        setUploadFiles(prev => prev.filter((_, i) => i !== index));
    };

    const handleAttachmentDownload = async (id: string, fileName: string, index: number = 0) => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/issue/download/${id}?index=${index}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const blob = await res.blob();
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = fileName;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                window.URL.revokeObjectURL(url);
            } else {
                alert('下载失败');
            }
        } catch (e) {
            console.error(e);
            alert('下载出错');
        }
    };


    return (
        <div className="space-y-6 animate-fade-in p-6 bg-[#f8fafc] min-h-screen">
            <div className="flex flex-col gap-6">
                {/* Header Section */}
                <div className="flex justify-between items-center bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div>
                        <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
                            生产问题追踪
                        </h1>
                        <p className="text-sm text-slate-500 mt-1">
                            全流程追踪与统计分析平台 · 当前共 {total} 个问题
                        </p>
                    </div>

                    <div className="flex items-center gap-4">
                        {/* View Toggle */}
                        <div className="bg-slate-100 p-1 rounded-lg inline-flex border border-slate-200">
                            <button
                                onClick={() => setViewMode('list')}
                                className={`flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-all ${viewMode === 'list'
                                    ? 'bg-white text-blue-600 shadow-sm'
                                    : 'text-slate-500 hover:text-slate-700'
                                    }`}
                            >
                                <LayoutList size={16} />
                                列表视图
                            </button>
                            <button
                                onClick={() => setViewMode('chart')}
                                className={`flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-all ${viewMode === 'chart'
                                    ? 'bg-white text-blue-600 shadow-sm'
                                    : 'text-slate-500 hover:text-slate-700'
                                    }`}
                            >
                                <BarChart3 size={16} />
                                统计分析
                            </button>
                        </div>
                    </div>
                </div>


                {/* Chart View */}
                {viewMode === 'chart' && (
                    <div className="animate-scale-in">
                        <IssueStats />
                    </div>
                )}

                {/* List View */}
                {viewMode === 'list' && (
                    <>
                        {/* Header & Actions */}
                        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex flex-col gap-4">
                            <div className="flex flex-col gap-4">
                                {/* Top Bar: Search & Actions */}
                                <div className="flex flex-col sm:flex-row gap-4 justify-between items-start sm:items-center">
                                    {/* Keyword Search */}
                                    <div className="relative flex-1 w-full sm:max-w-md group">
                                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 group-focus-within:text-blue-500 transition-colors" />
                                        <input
                                            type="text"
                                            placeholder="搜索问题标题/ID..."
                                            className="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all outline-none"
                                            value={keyword}
                                            onChange={(e) => setKeyword(e.target.value)}
                                        />
                                    </div>
                                    <div className="flex items-center gap-2">
                                        {selectedRowKeys.length > 0 && (
                                            <Auth code="ops:issue:batchDelete">
                                                <button
                                                    className="flex items-center gap-1 bg-white text-red-600 border border-red-200 px-3 py-1.5 rounded-md text-sm font-medium hover:bg-red-50 transition-colors shadow-sm"
                                                    onClick={handleBatchDelete}
                                                >
                                                    <Trash2 size={16} />
                                                    <span>批量删除 ({selectedRowKeys.length})</span>
                                                </button>
                                            </Auth>
                                        )}
                                        <Auth code="ops:issue:create">
                                            <button
                                                className="flex items-center gap-1 bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700 transition-all shadow-md hover:shadow-lg hover:-translate-y-0.5"
                                                onClick={() => {
                                                    setFormData({
                                                        issueType: '批量任务处理',
                                                        status: '新建'
                                                    });
                                                    setUploadFiles([]);
                                                    setShowModal(true);
                                                }}
                                            >
                                                <Plus size={16} />
                                                <span>登记问题</span>
                                            </button>
                                        </Auth>
                                    </div>

                                    {/* Actions */}
                                    <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
                                        <button
                                            className={`flex items-center gap-1 px-3 py-2 rounded-lg text-sm font-medium transition-all border ${showAdvanced ? 'bg-blue-50 border-blue-200 text-blue-700' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'}`}
                                            onClick={() => setShowAdvanced(!showAdvanced)}
                                        >
                                            <Filter size={16} />
                                            <span>{showAdvanced ? '收起筛选' : '高级筛选'}</span>
                                        </button>
                                        <div className="h-4 w-[1px] bg-slate-200 mx-1"></div>
                                        <button
                                            className="flex items-center gap-1 border border-slate-200 text-slate-600 px-3 py-2 rounded-lg text-sm font-medium hover:bg-slate-50 transition-colors bg-white hover:text-slate-900"
                                            onClick={handleImport}
                                        >
                                            <Upload size={16} />
                                            <span>导入</span>
                                        </button>
                                        <button
                                            className="flex items-center gap-1 border border-slate-200 text-slate-600 px-3 py-2 rounded-lg text-sm font-medium hover:bg-slate-50 transition-colors bg-white hover:text-slate-900"
                                            onClick={handleExport}
                                        >
                                            <Download size={16} />
                                            <span>导出</span>
                                        </button>
                                    </div>
                                </div>

                                {/* Advanced Filters */}
                                {showAdvanced && (
                                    <div className="p-4 bg-slate-50 rounded-lg border border-slate-100 animate-slide-in-down">
                                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                                            {/* System Filter */}
                                            <select
                                                className="border border-slate-200 rounded-md text-sm py-1.5 px-3 focus:ring-2 focus:ring-red-500 outline-none text-slate-600 bg-white"
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
                                                className="border border-slate-200 rounded-md text-sm py-1.5 px-3 focus:ring-2 focus:ring-red-500 outline-none text-slate-600 bg-white"
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
                                                className="border border-slate-200 rounded-md text-sm py-1.5 px-3 focus:ring-2 focus:ring-red-500 outline-none text-slate-600 bg-white"
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
                                                className="border border-slate-200 rounded-md text-sm py-1.5 px-3 focus:ring-2 focus:ring-red-500 outline-none bg-white"
                                                value={filterReporter}
                                                onChange={(e) => setFilterReporter(e.target.value)}
                                            />

                                            {/* Handler Filter */}
                                            <input
                                                type="text"
                                                placeholder="处理人姓名..."
                                                className="border border-slate-200 rounded-md text-sm py-1.5 px-3 focus:ring-2 focus:ring-red-500 outline-none bg-white"
                                                value={filterHandler}
                                                onChange={(e) => setFilterHandler(e.target.value)}
                                            />
                                        </div>

                                        <div className="flex items-center gap-2 text-sm text-slate-600 whitespace-nowrap pt-2 border-t border-slate-200">
                                            <Clock size={16} className="text-slate-400" />
                                            <span>发生时间:</span>
                                            <input
                                                type="date"
                                                className="border border-slate-200 rounded-md py-1.5 px-2 text-sm focus:ring-2 focus:ring-red-500 outline-none bg-white"
                                                value={filterStartTime}
                                                onChange={(e) => setFilterStartTime(e.target.value)}
                                            />
                                            <span>至</span>
                                            <input
                                                type="date"
                                                className="border border-slate-200 rounded-md py-1.5 px-2 text-sm focus:ring-2 focus:ring-red-500 outline-none bg-white"
                                                value={filterEndTime}
                                                onChange={(e) => setFilterEndTime(e.target.value)}
                                            />
                                            <button
                                                className="ml-auto text-xs text-slate-400 hover:text-red-500"
                                                onClick={() => {
                                                    setFilterSystem('');
                                                    setFilterType('all');
                                                    setFilterStatus('all');
                                                    setFilterReporter('');
                                                    setFilterHandler('');
                                                    setFilterStartTime('');
                                                    setFilterEndTime('');
                                                }}
                                            >
                                                重置筛选
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Issue List */}
                        <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
                            <div className="overflow-x-auto">
                                <table className="w-full text-sm text-left">
                                    <thead className="bg-slate-50 text-slate-500 font-medium border-b border-slate-200">
                                        <tr>
                                            <th className="px-4 py-3 whitespace-nowrap w-4">
                                                <input
                                                    type="checkbox"
                                                    checked={issues.length > 0 && selectedRowKeys.length === issues.length}
                                                    onChange={toggleSelectAll}
                                                    className="rounded border-slate-300 text-red-600 focus:ring-red-500"
                                                />
                                            </th>
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
                                            <tr
                                                key={issue.id}
                                                className="hover:bg-slate-50 transition-colors group cursor-pointer"
                                                onClick={() => handleViewDetail(issue)}
                                            >
                                                <td className="px-4 py-3">
                                                    <input
                                                        type="checkbox"
                                                        checked={selectedRowKeys.includes(issue.id)}
                                                        onChange={() => toggleSelectRow(issue.id)}
                                                        onClick={(e) => e.stopPropagation()}
                                                        className="rounded border-slate-300 text-red-600 focus:ring-red-500"
                                                    />
                                                </td>
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
                                                        <Auth code="ops:issue:create">
                                                            <button
                                                                className="text-amber-600 hover:text-amber-800 text-xs flex items-center gap-1 px-2 py-1 rounded hover:bg-amber-50 transition-colors"
                                                                onClick={(e) => {
                                                                    e.stopPropagation();
                                                                    handleEdit(issue);
                                                                }}
                                                            >
                                                                <Edit size={14} />
                                                                修改
                                                            </button>
                                                        </Auth>
                                                        <Auth code="ops:issue:delete">
                                                            <button
                                                                className="text-red-600 hover:text-red-800 text-xs flex items-center gap-1 px-2 py-1 rounded hover:bg-red-50 transition-colors"
                                                                onClick={(e) => {
                                                                    e.stopPropagation();
                                                                    handleDelete(issue.id);
                                                                }}
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

                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">附件</label>
                                    <div className="flex flex-col gap-2">
                                        <div className="flex items-center gap-2">
                                            <label className={`flex items-center gap-2 px-3 py-2 border border-slate-300 rounded-md text-sm text-slate-600 cursor-pointer hover:bg-slate-50 transition-colors ${isUploading ? 'opacity-50 cursor-not-allowed' : ''}`}>
                                                <Upload size={16} />
                                                <span>{isUploading ? '上传中...' : '上传附件 (支持多选)'}</span>
                                                <input
                                                    type="file"
                                                    className="hidden"
                                                    multiple
                                                    onChange={handleFileUpload}
                                                    disabled={isUploading}
                                                />
                                            </label>
                                        </div>
                                        {uploadFiles.length > 0 && (
                                            <div className="bg-slate-50 rounded p-2 flex flex-col gap-1">
                                                {uploadFiles.map((f, i) => (
                                                    <div key={i} className="flex items-center justify-between text-sm text-slate-600 px-2 py-1 bg-white rounded border border-slate-200">
                                                        <div className="flex items-center gap-2 overflow-hidden">
                                                            <Paperclip size={12} className="shrink-0" />
                                                            <span className="truncate">{f.name}</span>
                                                        </div>
                                                        <button
                                                            className="text-slate-400 hover:text-red-500 shrink-0"
                                                            onClick={() => handleRemoveAttachment(i)}
                                                        >
                                                            <X size={14} />
                                                        </button>
                                                    </div>
                                                ))}
                                            </div>
                                        )}
                                    </div>
                                    <p className="text-xs text-slate-400 mt-1">支持最大 200MB 的文件上传，可同时选择多个文件</p>
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

                {/* Issue Detail Sidebar */}
                {showDetailModal && selectedIssue && (
                    <div className="fixed inset-0 z-50 flex justify-end">
                        {/* Backdrop */}
                        <div
                            className="absolute inset-0 bg-black/20 backdrop-blur-sm transition-opacity"
                            onClick={() => setShowDetailModal(false)}
                        />

                        {/* Sidebar */}
                        <div className="relative w-[500px] h-full bg-white shadow-2xl flex flex-col transform transition-transform duration-300 ease-in-out animate-slide-in-right">
                            <div className="flex items-center justify-between p-4 border-b border-slate-100 bg-slate-50/50">
                                <h3 className="text-lg font-bold text-slate-800">问题详情</h3>
                                <button onClick={() => setShowDetailModal(false)} className="text-slate-400 hover:text-slate-600 p-1 hover:bg-slate-100 rounded-full transition-colors">
                                    <X size={20} />
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

                                {selectedIssue.attachmentPath && (
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <label className="block text-xs font-medium text-slate-500 mb-2">附件列表</label>
                                        <div className="flex flex-col gap-2">
                                            {(() => {
                                                try {
                                                    // Try parse JSON
                                                    const paths = JSON.parse(selectedIssue.attachmentPath);
                                                    const names = selectedIssue.attachmentName ? JSON.parse(selectedIssue.attachmentName) : [];
                                                    if (Array.isArray(paths)) {
                                                        return paths.map((p, i) => (
                                                            <button
                                                                key={i}
                                                                onClick={() => handleAttachmentDownload(selectedIssue.id, names[i] || `attachment_${i + 1}`, i)}
                                                                className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 w-fit"
                                                            >
                                                                <Paperclip size={14} />
                                                                {names[i] || `附件 ${i + 1}`}
                                                            </button>
                                                        ));
                                                    }
                                                } catch (e) {
                                                    // Fallback for single file
                                                    return (
                                                        <button
                                                            onClick={() => handleAttachmentDownload(selectedIssue.id, selectedIssue.attachmentName || 'attachment')}
                                                            className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 w-fit"
                                                        >
                                                            <Paperclip size={14} />
                                                            {selectedIssue.attachmentName || '点击下载附件'}
                                                        </button>
                                                    )
                                                }
                                            })()}
                                        </div>
                                    </div>
                                )}

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
        </div>
    );
};

export default IssueTracking;
