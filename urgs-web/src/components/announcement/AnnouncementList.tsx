import React, { useState, useEffect } from 'react';
import { Search, Filter, MoreHorizontal, Eye, Trash2, Edit, LayoutGrid, List as ListIcon, Calendar, User, MessageCircle, ArrowUpRight, SearchSlash } from 'lucide-react';
import { message, Modal, Badge, Tooltip } from 'antd';
import AnnouncementDetail from './AnnouncementDetail';

interface AnnouncementListProps {
    onEdit?: (id: string) => void;
}

const AnnouncementList: React.FC<AnnouncementListProps> = ({ onEdit }) => {
    const [viewMode, setViewMode] = useState<'card' | 'table'>('card');
    const [searchTerm, setSearchTerm] = useState('');
    const [filterType, setFilterType] = useState<string>('all');
    const [notices, setNotices] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [currentPage, setCurrentPage] = useState(1);
    const [total, setTotal] = useState(0);
    const [selectedId, setSelectedId] = useState<string | null>(null);

    const fetchNotices = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            const userStr = localStorage.getItem('auth_user');
            let systems = '';
            let userId = 'admin';
            if (userStr) {
                const user = JSON.parse(userStr);
                systems = user.system || '';
                userId = user.empId || 'admin';
            }

            const queryParams = new URLSearchParams({
                current: currentPage.toString(),
                size: '12',
                type: filterType,
                keyword: searchTerm
            });

            const res = await fetch(`/api/announcement/list?${queryParams.toString()}`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'X-User-Id': encodeURIComponent(userId),
                    'X-User-Systems': encodeURIComponent(systems)
                }
            });

            if (res.ok) {
                const data = await res.json();
                setNotices(data.records);
                setTotal(data.total);
            }
        } catch (error) {
            console.error('Failed to fetch notices', error);
            message.error('公告加载失败');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        const timer = setTimeout(() => {
            fetchNotices();
        }, 300);
        return () => clearTimeout(timer);
    }, [searchTerm, filterType, currentPage]);

    const handleDelete = async (id: string) => {
        Modal.confirm({
            title: '确认删除',
            content: '确定要删除这条公告吗？此操作不可撤销。',
            okText: '确认删除',
            cancelText: '取消',
            okType: 'danger',
            onOk: async () => {
                try {
                    const token = localStorage.getItem('auth_token');
                    const userStr = localStorage.getItem('auth_user');
                    let userId = 'admin';
                    if (userStr) {
                        const user = JSON.parse(userStr);
                        userId = user.empId || 'admin';
                    }

                    const res = await fetch(`/api/announcement/${id}`, {
                        method: 'DELETE',
                        headers: {
                            'Authorization': `Bearer ${token}`,
                            'X-User-Id': encodeURIComponent(userId)
                        }
                    });

                    if (res.ok) {
                        message.success('删除成功');
                        fetchNotices();
                    } else {
                        message.error('删除失败，可能无权限');
                    }
                } catch (error) {
                    message.error('删除请求出错');
                }
            }
        });
    };

    if (selectedId) {
        return <AnnouncementDetail id={selectedId} onBack={() => {
            setSelectedId(null);
            fetchNotices();
        }} />;
    }

    // 骨架屏
    const SkeletonCard = () => (
        <div className="bg-white rounded-2xl border border-slate-100 p-5 space-y-4 animate-pulse">
            <div className="flex justify-between items-start">
                <div className="h-4 bg-slate-100 rounded w-16" />
                <div className="h-4 bg-slate-100 rounded w-24" />
            </div>
            <div className="space-y-2">
                <div className="h-6 bg-slate-100 rounded w-full" />
                <div className="h-4 bg-slate-100 rounded w-2/3" />
            </div>
            <div className="pt-4 border-t border-slate-50 flex justify-between">
                <div className="h-4 bg-slate-100 rounded w-20" />
                <div className="h-4 bg-slate-100 rounded w-16" />
            </div>
        </div>
    );

    const typeConfig: Record<string, { label: string, color: string, bg: string }> = {
        urgent: { label: '紧急', color: 'text-red-600', bg: 'bg-red-50 border-red-100' },
        normal: { label: '一般', color: 'text-blue-600', bg: 'bg-blue-50 border-blue-100' },
        update: { label: '更新', color: 'text-amber-600', bg: 'bg-amber-50 border-amber-100' },
        regulatory: { label: '监管', color: 'text-purple-600', bg: 'bg-purple-50 border-purple-100' }
    };

    return (
        <div className="space-y-6">
            {/* 工具栏 */}
            <div className="flex flex-col lg:flex-row gap-4 justify-between items-start lg:items-center">
                <div className="relative w-full lg:max-w-md group">
                    <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 w-4.5 h-4.5 group-focus-within:text-violet-500 transition-colors" />
                    <input
                        type="text"
                        placeholder="搜索公告标题、内容关键词..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full pl-11 pr-4 py-2.5 bg-slate-50 border-none rounded-xl focus:ring-2 focus:ring-violet-500/20 focus:bg-white transition-all text-sm shadow-sm"
                    />
                </div>

                <div className="flex items-center gap-3 w-full lg:w-auto">
                    <div className="flex bg-slate-100 rounded-lg p-1">
                        <button
                            onClick={() => setViewMode('card')}
                            className={`p-2 rounded-md transition-all ${viewMode === 'card' ? 'bg-white text-violet-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                        >
                            <LayoutGrid size={18} />
                        </button>
                        <button
                            onClick={() => setViewMode('table')}
                            className={`p-2 rounded-md transition-all ${viewMode === 'table' ? 'bg-white text-violet-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                        >
                            <ListIcon size={18} />
                        </button>
                    </div>

                    <select
                        value={filterType}
                        onChange={(e) => setFilterType(e.target.value)}
                        className="px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm text-slate-600 focus:outline-none focus:ring-2 focus:ring-violet-500/20 cursor-pointer shadow-sm"
                    >
                        <option value="all">所有类型</option>
                        {Object.entries(typeConfig).map(([k, v]) => (
                            <option key={k} value={k}>{v.label}</option>
                        ))}
                    </select>

                    <button className="p-2.5 bg-white border border-slate-200 rounded-xl text-slate-500 hover:bg-slate-50 shadow-sm">
                        <Filter className="w-4.5 h-4.5" />
                    </button>
                </div>
            </div>

            {/* 内容展示 */}
            {loading ? (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                    {[1, 2, 3, 4, 5, 6].map(i => <SkeletonCard key={i} />)}
                </div>
            ) : notices.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-24 bg-slate-50/50 rounded-3xl border border-dashed border-slate-200">
                    <div className="w-16 h-16 bg-white rounded-2xl flex items-center justify-center shadow-sm mb-4">
                        <SearchSlash className="w-8 h-8 text-slate-300" />
                    </div>
                    <p className="text-slate-500 font-medium">未找到符合条件的公告</p>
                    <button
                        onClick={() => { setSearchTerm(''); setFilterType('all'); }}
                        className="mt-4 text-violet-600 text-sm font-medium hover:underline"
                    >
                        重置搜索条件
                    </button>
                </div>
            ) : viewMode === 'card' ? (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                    {notices.map((notice) => {
                        const config = typeConfig[notice.type] || typeConfig.normal;
                        const userStr = localStorage.getItem('auth_user');
                        const currentUser = userStr ? JSON.parse(userStr).empId : 'admin';
                        const isOwner = notice.createBy === currentUser;

                        return (
                            <div
                                key={notice.id}
                                className="group relative bg-white rounded-2xl border border-slate-100 p-5 hover:shadow-xl hover:shadow-slate-200/50 hover:border-violet-100 transition-all duration-300 flex flex-col h-full cursor-pointer"
                                onClick={() => {
                                    console.log('Opening announcement:', notice.id);
                                    setSelectedId(notice.id);
                                }}
                            >
                                <div className="flex justify-between items-start mb-4">
                                    <span className={`px-2.5 py-0.5 rounded-lg text-[11px] font-bold uppercase tracking-wider border ${config.bg} ${config.color}`}>
                                        {config.label}
                                    </span>
                                    <div className="flex items-center text-slate-400 text-[11px] font-medium bg-slate-50 px-2 py-0.5 rounded-full">
                                        <Calendar size={12} className="mr-1" />
                                        {notice.date || new Date(notice.createTime).toLocaleDateString()}
                                    </div>
                                </div>

                                <div className="flex-1">
                                    <h3 className="text-base font-bold text-slate-800 line-clamp-2 leading-snug group-hover:text-violet-600 transition-colors mb-2">
                                        {notice.title}
                                    </h3>
                                    <p className="text-slate-500 text-sm line-clamp-2 leading-relaxed mb-4">
                                        {notice.summary || '点击查看公告详情内容...'}
                                    </p>
                                </div>

                                <div className="pt-4 border-t border-slate-50 flex items-center justify-between mt-auto">
                                    <div className="flex items-center gap-3">
                                        <div className="flex items-center text-slate-400 text-xs">
                                            <User size={13} className="mr-1" />
                                            {notice.createBy}
                                        </div>
                                        <div className="flex items-center text-slate-400 text-xs">
                                            <Eye size={13} className="mr-1" />
                                            {notice.readCount || 0}
                                        </div>
                                    </div>

                                    {/* 悬浮操作栏 */}
                                    <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-all">
                                        {isOwner && (
                                            <>
                                                <button
                                                    className="p-1.5 text-slate-400 hover:text-violet-600 hover:bg-violet-50 rounded-lg transition-colors"
                                                    onClick={(e) => { e.stopPropagation(); onEdit && onEdit(notice.id); }}
                                                >
                                                    <Edit size={14} />
                                                </button>
                                                <button
                                                    className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                                    onClick={(e) => { e.stopPropagation(); handleDelete(notice.id); }}
                                                >
                                                    <Trash2 size={14} />
                                                </button>
                                            </>
                                        )}
                                        <div className="w-6 h-6 rounded-full bg-violet-600 text-white flex items-center justify-center ml-2 shadow-lg shadow-violet-200">
                                            <ArrowUpRight size={14} />
                                        </div>
                                    </div>

                                    {!notice.hasRead && (
                                        <div className="absolute top-3 right-3 w-2 h-2 rounded-full bg-red-500 ring-4 ring-red-500/10 animate-pulse" />
                                    )}
                                </div>
                            </div>
                        );
                    })}
                </div>
            ) : (
                <div className="overflow-hidden bg-white border border-slate-100 rounded-2xl shadow-sm">
                    <table className="w-full text-sm text-left">
                        <thead className="bg-slate-50/50 text-slate-500 font-semibold border-b border-slate-100">
                            <tr>
                                <th className="px-5 py-4 w-24">类 型</th>
                                <th className="px-5 py-4">标 题</th>
                                <th className="px-5 py-4 w-40">发布人</th>
                                <th className="px-5 py-4 w-44">发布时间</th>
                                <th className="px-5 py-4 w-24 text-center">阅读量</th>
                                <th className="px-5 py-4 w-28 text-center">操 作</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {notices.map((notice) => {
                                const config = typeConfig[notice.type] || typeConfig.normal;
                                const userStr = localStorage.getItem('auth_user');
                                const currentUser = userStr ? JSON.parse(userStr).empId : 'admin';
                                const isOwner = notice.createBy === currentUser;

                                return (
                                    <tr
                                        key={notice.id}
                                        className="hover:bg-slate-50/80 transition-colors group cursor-pointer"
                                        onClick={() => {
                                            console.log('Opening announcement (table):', notice.id);
                                            setSelectedId(notice.id);
                                        }}
                                    >
                                        <td className="px-5 py-4">
                                            <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-bold ${config.bg} ${config.color}`}>
                                                {config.label}
                                            </span>
                                        </td>
                                        <td className="px-5 py-4">
                                            <div className="flex items-center gap-2">
                                                {!notice.hasRead && <div className="w-1.5 h-1.5 rounded-full bg-red-500" />}
                                                <span className="font-medium text-slate-700 group-hover:text-violet-600 transition-colors truncate max-w-md">{notice.title}</span>
                                            </div>
                                        </td>
                                        <td className="px-5 py-4 text-slate-500">
                                            <div className="flex items-center gap-2">
                                                <div className="w-6 h-6 rounded-full bg-slate-100 flex items-center justify-center text-[10px] font-bold text-slate-400">
                                                    {notice.createBy?.[0]?.toUpperCase()}
                                                </div>
                                                {notice.createBy}
                                            </div>
                                        </td>
                                        <td className="px-5 py-4 text-slate-500 font-mono text-xs">
                                            {notice.createTime ? new Date(notice.createTime).toLocaleString() : notice.date}
                                        </td>
                                        <td className="px-5 py-4 text-slate-400 text-center text-xs">
                                            {notice.readCount || 0}
                                        </td>
                                        <td className="px-5 py-4">
                                            <div className="flex items-center justify-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                <button className="p-1.5 text-slate-400 hover:text-violet-600 rounded-lg" onClick={(e) => { e.stopPropagation(); setSelectedId(notice.id); }}>
                                                    <Eye size={15} />
                                                </button>
                                                {isOwner && (
                                                    <>
                                                        <button className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg" onClick={(e) => { e.stopPropagation(); onEdit && onEdit(notice.id); }}>
                                                            <Edit size={15} />
                                                        </button>
                                                        <button className="p-1.5 text-slate-400 hover:text-red-600 rounded-lg" onClick={(e) => { e.stopPropagation(); handleDelete(notice.id); }}>
                                                            <Trash2 size={15} />
                                                        </button>
                                                    </>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            )}

            {/* 分页按钮 */}
            {total > 0 && (
                <div className="flex items-center justify-between bg-slate-50 p-4 rounded-2xl border border-slate-100">
                    <div className="text-sm text-slate-500">
                        显示 {(currentPage - 1) * 12 + 1} 到 {Math.min(currentPage * 12, total)} 条，共 <span className="font-bold text-slate-700">{total}</span> 条公告
                    </div>
                    <div className="flex items-center gap-2">
                        <button
                            onClick={() => { setCurrentPage(p => Math.max(1, p - 1)); window.scrollTo(0, 0); }}
                            disabled={currentPage === 1 || loading}
                            className="px-4 py-2 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 disabled:opacity-50 transition-colors shadow-sm"
                        >
                            上一页
                        </button>
                        <div className="flex items-center gap-1 px-3">
                            <span className="w-8 h-8 flex items-center justify-center bg-violet-600 text-white rounded-lg text-sm font-bold shadow-md shadow-violet-200">
                                {currentPage}
                            </span>
                            <span className="text-slate-400 mx-1">/</span>
                            <span className="text-slate-600 text-sm font-medium">{Math.ceil(total / 12)}</span>
                        </div>
                        <button
                            onClick={() => { setCurrentPage(p => p + 1); window.scrollTo(0, 0); }}
                            disabled={currentPage >= Math.ceil(total / 12) || loading}
                            className="px-4 py-2 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 disabled:opacity-50 transition-colors shadow-sm"
                        >
                            下一页
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default AnnouncementList;
