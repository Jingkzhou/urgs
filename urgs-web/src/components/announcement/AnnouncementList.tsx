import React, { useState, useEffect } from 'react';
import { Search, Filter, MoreHorizontal, Eye, Trash2, Edit, LayoutGrid, List as ListIcon, Calendar, User, MessageCircle, ArrowUpRight, SearchSlash, ChevronLeft, ChevronRight, Clock } from 'lucide-react';
import { message, Modal, Tooltip, Dropdown } from 'antd';
import { motion, AnimatePresence } from 'framer-motion';
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
            centered: true,
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
        return (
            <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
            >
                <AnnouncementDetail id={selectedId} onBack={() => {
                    setSelectedId(null);
                    fetchNotices();
                }} />
            </motion.div>
        );
    }

    // 骨架屏
    const SkeletonCard = () => (
        <div className="bg-white rounded-2xl border border-slate-100 p-6 space-y-4 animate-pulse shadow-sm">
            <div className="flex justify-between items-start">
                <div className="h-5 bg-slate-100 rounded-lg w-20" />
                <div className="h-4 bg-slate-100 rounded-lg w-24" />
            </div>
            <div className="space-y-3 pt-2">
                <div className="h-6 bg-slate-100 rounded-lg w-full" />
                <div className="h-4 bg-slate-100 rounded-lg w-2/3" />
            </div>
            <div className="pt-6 border-t border-slate-50 flex justify-between items-center">
                <div className="flex gap-2">
                    <div className="h-8 w-8 rounded-full bg-slate-100" />
                    <div className="h-4 bg-slate-100 rounded w-20 self-center" />
                </div>
            </div>
        </div>
    );

    const typeConfig: Record<string, { label: string, color: string, bg: string, ring: string }> = {
        urgent: { label: '紧急', color: 'text-red-600', bg: 'bg-red-50', ring: 'ring-red-500/20' },
        normal: { label: '一般', color: 'text-violet-600', bg: 'bg-violet-50', ring: 'ring-violet-500/20' },
        update: { label: '更新', color: 'text-amber-600', bg: 'bg-amber-50', ring: 'ring-amber-500/20' },
        regulatory: { label: '监管', color: 'text-blue-600', bg: 'bg-blue-50', ring: 'ring-blue-500/20' }
    };

    const container = {
        hidden: { opacity: 0 },
        show: {
            opacity: 1,
            transition: {
                staggerChildren: 0.05
            }
        }
    };

    const item = {
        hidden: { opacity: 0, y: 20 },
        show: { opacity: 1, y: 0 }
    };

    return (
        <div className="space-y-8">
            {/* 工具栏 */}
            <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-2 border border-slate-200/60 shadow-lg shadow-slate-200/40 sticky top-4 z-20 transition-all duration-300">
                <div className="flex flex-col lg:flex-row gap-4 justify-between items-center px-2">
                    <div className="relative w-full lg:max-w-md group">
                        <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                            <Search className="h-4 w-4 text-slate-400 group-focus-within:text-violet-500 transition-colors" />
                        </div>
                        <input
                            type="text"
                            placeholder="搜索公告标题、内容关键词..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="block w-full pl-10 pr-4 py-2.5 bg-slate-50 border-none rounded-xl text-sm focus:ring-2 focus:ring-violet-500/20 focus:bg-white transition-all placeholder:text-slate-400"
                        />
                    </div>

                    <div className="flex items-center gap-3 w-full lg:w-auto overflow-x-auto pb-1 lg:pb-0 hide-scrollbar">
                        <div className="flex bg-slate-100/80 p-1 rounded-xl">
                            <button
                                onClick={() => setViewMode('card')}
                                className={`p-2 rounded-lg transition-all duration-200 ${viewMode === 'card' ? 'bg-white text-violet-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                            >
                                <LayoutGrid size={18} />
                            </button>
                            <button
                                onClick={() => setViewMode('table')}
                                className={`p-2 rounded-lg transition-all duration-200 ${viewMode === 'table' ? 'bg-white text-violet-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                            >
                                <ListIcon size={18} />
                            </button>
                        </div>

                        <div className="h-8 w-px bg-slate-200 mx-1" />

                        <div className="flex gap-2">
                            {['all', 'urgent', 'normal', 'update'].map((type) => (
                                <button
                                    key={type}
                                    onClick={() => setFilterType(type)}
                                    className={`px-4 py-2 rounded-xl text-sm font-bold transition-all border ${filterType === type
                                            ? 'bg-violet-600 text-white border-violet-600 shadow-lg shadow-violet-200'
                                            : 'bg-white text-slate-500 border-slate-200 hover:border-violet-300 hover:text-violet-600'
                                        }`}
                                >
                                    {type === 'all' ? '全部' : typeConfig[type]?.label || type}
                                </button>
                            ))}
                        </div>
                    </div>
                </div>
            </div>

            {/* 内容展示 */}
            <AnimatePresence mode="wait">
                {loading ? (
                    <motion.div
                        key="loading"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6"
                    >
                        {[1, 2, 3, 4, 5, 6].map(i => <SkeletonCard key={i} />)}
                    </motion.div>
                ) : notices.length === 0 ? (
                    <motion.div
                        key="empty"
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="flex flex-col items-center justify-center py-32 bg-white rounded-3xl border border-dashed border-slate-200 text-center"
                    >
                        <div className="w-20 h-20 bg-slate-50 rounded-2xl flex items-center justify-center mb-6 shadow-inner rotate-3">
                            <SearchSlash className="w-10 h-10 text-slate-300" />
                        </div>
                        <h3 className="text-lg font-bold text-slate-700 mb-2">未找到相关公告</h3>
                        <p className="text-slate-500 max-w-xs mx-auto mb-8">
                            我们没有找到与您搜索条件相匹配的公告内容。
                        </p>
                        <button
                            onClick={() => { setSearchTerm(''); setFilterType('all'); }}
                            className="px-6 py-2.5 bg-violet-600 text-white text-sm font-bold rounded-xl shadow-lg shadow-violet-200 hover:bg-violet-700 transition-all hover:scale-105"
                        >
                            清除筛选条件
                        </button>
                    </motion.div>
                ) : viewMode === 'card' ? (
                    <motion.div
                        key="card-view"
                        variants={container}
                        initial="hidden"
                        animate="show"
                        className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6"
                    >
                        {notices.map((notice) => {
                            const config = typeConfig[notice.type] || typeConfig.normal;
                            const userStr = localStorage.getItem('auth_user');
                            const currentUser = userStr ? JSON.parse(userStr).empId : 'admin';
                            const isOwner = notice.createBy === currentUser;

                            return (
                                <motion.div
                                    key={notice.id}
                                    variants={item}
                                    layoutId={notice.id}
                                    className="group relative bg-white rounded-3xl p-6 shadow-sm border border-slate-100 hover:shadow-xl hover:shadow-slate-200/40 hover:-translate-y-1 transition-all duration-300 cursor-pointer overflow-hidden"
                                    onClick={() => setSelectedId(notice.id)}
                                >
                                    {/* Unread Indicator */}
                                    {!notice.hasRead && (
                                        <div className="absolute top-0 right-0 w-16 h-16 bg-gradient-to-bl from-red-500/10 to-transparent pointer-events-none">
                                            <div className="absolute top-5 right-5 w-2.5 h-2.5 rounded-full bg-red-500 shadow-lg shadow-red-500/50 animate-pulse" />
                                        </div>
                                    )}

                                    <div className="flex justify-between items-start mb-5">
                                        <span className={`px-3 py-1 rounded-xl text-[10px] font-black uppercase tracking-widest ${config.bg} ${config.color} ring-1 ${config.ring}`}>
                                            {config.label}
                                        </span>
                                        <div className="flex items-center text-slate-400 text-[10px] font-bold bg-slate-50 px-2.5 py-1 rounded-lg">
                                            <Clock size={12} className="mr-1.5" />
                                            {notice.date || new Date(notice.createTime).toLocaleDateString()}
                                        </div>
                                    </div>

                                    <div className="mb-6">
                                        <h3 className="text-lg font-bold text-slate-800 line-clamp-2 leading-tight group-hover:text-violet-600 transition-colors mb-3">
                                            {notice.title}
                                        </h3>
                                        <p className="text-slate-500 text-sm line-clamp-2 leading-relaxed opacity-80">
                                            {notice.summary || '暂无摘要，点击查看详情...'}
                                        </p>
                                    </div>

                                    <div className="pt-5 border-t border-slate-50 flex items-center justify-between">
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-slate-100 to-slate-200 flex items-center justify-center text-[10px] font-black text-slate-500 border-2 border-white shadow-sm">
                                                {notice.createBy?.[0]?.toUpperCase()}
                                            </div>
                                            <div className="flex flex-col">
                                                <span className="text-[10px] font-bold text-slate-700">{notice.createBy}</span>
                                                <div className="flex items-center text-slate-400 text-[10px]">
                                                    <Eye size={10} className="mr-1" />
                                                    {notice.readCount || 0} 阅读
                                                </div>
                                            </div>
                                        </div>

                                        <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-all transform translate-x-4 group-hover:translate-x-0 bg-white pl-2">
                                            {isOwner && (
                                                <>
                                                    <Tooltip title="编辑">
                                                        <button
                                                            className="p-2 text-slate-400 hover:text-violet-600 hover:bg-violet-50 rounded-xl transition-colors"
                                                            onClick={(e) => { e.stopPropagation(); onEdit && onEdit(notice.id); }}
                                                        >
                                                            <Edit size={16} />
                                                        </button>
                                                    </Tooltip>
                                                    <Tooltip title="删除">
                                                        <button
                                                            className="p-2 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-colors"
                                                            onClick={(e) => { e.stopPropagation(); handleDelete(notice.id); }}
                                                        >
                                                            <Trash2 size={16} />
                                                        </button>
                                                    </Tooltip>
                                                </>
                                            )}
                                            <div className="w-8 h-8 rounded-full bg-slate-900 text-white flex items-center justify-center shadow-lg hover:bg-violet-600 transition-colors ml-1">
                                                <ArrowUpRight size={16} />
                                            </div>
                                        </div>
                                    </div>
                                </motion.div>
                            );
                        })}
                    </motion.div>
                ) : (
                    <motion.div
                        key="table-view"
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="bg-white rounded-3xl shadow-sm border border-slate-200/60 overflow-hidden"
                    >
                        <div className="overflow-x-auto">
                            <table className="w-full text-sm text-left">
                                <thead className="bg-slate-50/80 text-slate-500 font-bold text-xs uppercase tracking-wider border-b border-slate-100">
                                    <tr>
                                        <th className="px-6 py-5 w-24">类型</th>
                                        <th className="px-6 py-5">标题</th>
                                        <th className="px-6 py-5 w-48">发布人</th>
                                        <th className="px-6 py-5 w-48">时间</th>
                                        <th className="px-6 py-5 w-24 text-center">阅读</th>
                                        <th className="px-6 py-5 w-28 text-center">操作</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {notices.map((notice, index) => {
                                        const config = typeConfig[notice.type] || typeConfig.normal;
                                        const userStr = localStorage.getItem('auth_user');
                                        const currentUser = userStr ? JSON.parse(userStr).empId : 'admin';
                                        const isOwner = notice.createBy === currentUser;

                                        return (
                                            <motion.tr
                                                key={notice.id}
                                                initial={{ opacity: 0 }}
                                                animate={{ opacity: 1 }}
                                                transition={{ delay: index * 0.05 }}
                                                className="hover:bg-slate-50/50 transition-colors group cursor-pointer"
                                                onClick={() => setSelectedId(notice.id)}
                                            >
                                                <td className="px-6 py-4">
                                                    <span className={`inline-flex items-center px-2.5 py-1 rounded-lg text-[10px] font-black ${config.bg} ${config.color}`}>
                                                        {config.label}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <div className="flex items-center gap-3">
                                                        {!notice.hasRead && (
                                                            <div className="w-2 h-2 rounded-full bg-red-500 shadow-sm shrink-0" />
                                                        )}
                                                        <span className="font-bold text-slate-700 group-hover:text-violet-600 transition-colors truncate max-w-md text-sm">
                                                            {notice.title}
                                                        </span>
                                                    </div>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <div className="flex items-center gap-3">
                                                        <div className="w-7 h-7 rounded-full bg-slate-100 flex items-center justify-center text-[10px] font-bold text-slate-500 border border-white shadow-sm">
                                                            {notice.createBy?.[0]?.toUpperCase()}
                                                        </div>
                                                        <span className="text-slate-600 font-medium text-xs">{notice.createBy}</span>
                                                    </div>
                                                </td>
                                                <td className="px-6 py-4 text-slate-500 font-medium text-xs">
                                                    {notice.createTime ? new Date(notice.createTime).toLocaleDateString() : notice.date}
                                                </td>
                                                <td className="px-6 py-4 text-center">
                                                    <span className="bg-slate-100 text-slate-500 px-2 py-1 rounded-lg text-xs font-bold">
                                                        {notice.readCount || 0}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4">
                                                    <div className="flex items-center justify-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                        <button className="p-2 text-slate-400 hover:text-violet-600 rounded-xl hover:bg-violet-50 transition-colors">
                                                            <Eye size={16} />
                                                        </button>
                                                        {isOwner && (
                                                            <>
                                                                <button
                                                                    className="p-2 text-slate-400 hover:text-slate-700 rounded-xl hover:bg-slate-100 transition-colors"
                                                                    onClick={(e) => { e.stopPropagation(); onEdit && onEdit(notice.id); }}
                                                                >
                                                                    <Edit size={16} />
                                                                </button>
                                                                <button
                                                                    className="p-2 text-slate-400 hover:text-red-600 rounded-xl hover:bg-red-50 transition-colors"
                                                                    onClick={(e) => { e.stopPropagation(); handleDelete(notice.id); }}
                                                                >
                                                                    <Trash2 size={16} />
                                                                </button>
                                                            </>
                                                        )}
                                                    </div>
                                                </td>
                                            </motion.tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>

            {/* Pagination Grid */}
            {total > 0 && (
                <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-4 border-t border-slate-100">
                    <div className="text-xs font-bold text-slate-400 uppercase tracking-wider">
                        Running {Math.min(currentPage * 12, total)} of {total} items
                    </div>
                    <div className="flex items-center gap-2">
                        <button
                            onClick={() => { setCurrentPage(p => Math.max(1, p - 1)); window.scrollTo(0, 0); }}
                            disabled={currentPage === 1 || loading}
                            className="w-10 h-10 flex items-center justify-center bg-white border border-slate-200 rounded-xl text-slate-500 hover:border-violet-300 hover:text-violet-600 disabled:opacity-50 disabled:hover:border-slate-200 disabled:hover:text-slate-500 transition-all shadow-sm"
                        >
                            <ChevronLeft size={18} />
                        </button>

                        <div className="flex items-center px-4 py-2 bg-slate-50 rounded-xl border border-slate-100">
                            <span className="text-violet-600 font-black">{currentPage}</span>
                            <span className="text-slate-300 mx-2">/</span>
                            <span className="text-slate-500 font-bold">{Math.ceil(total / 12)}</span>
                        </div>

                        <button
                            onClick={() => { setCurrentPage(p => p + 1); window.scrollTo(0, 0); }}
                            disabled={currentPage >= Math.ceil(total / 12) || loading}
                            className="w-10 h-10 flex items-center justify-center bg-white border border-slate-200 rounded-xl text-slate-500 hover:border-violet-300 hover:text-violet-600 disabled:opacity-50 disabled:hover:border-slate-200 disabled:hover:text-slate-500 transition-all shadow-sm"
                        >
                            <ChevronRight size={18} />
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default AnnouncementList;
