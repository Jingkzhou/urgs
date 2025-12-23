import React, { useState } from 'react';
import { Search, Filter, MoreHorizontal, Eye, Trash2, Edit } from 'lucide-react';
import { NOTICES } from '../../constants';
import { message, Modal, Badge } from 'antd';
import AnnouncementDetail from './AnnouncementDetail';

const AnnouncementList: React.FC = () => {
    const [searchTerm, setSearchTerm] = useState('');
    const [filterType, setFilterType] = useState<string>('all');

    const [notices, setNotices] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [currentPage, setCurrentPage] = useState(1);
    const [total, setTotal] = useState(0);
    const [selectedId, setSelectedId] = useState<string | null>(null);

    const fetchNotices = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            // Assuming we pass user systems via header or they are handled by backend session
            // For this implementation, we simulate passing them in header as per plan
            const userStr = localStorage.getItem('auth_user');
            let systems = '';
            let userId = 'admin';
            if (userStr) {
                const user = JSON.parse(userStr);
                systems = user.ssoSystem || '';
                userId = user.empId || 'admin';
            }

            const queryParams = new URLSearchParams({
                current: currentPage.toString(),
                size: '10',
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
        } finally {
            setLoading(false);
        }
    };

    React.useEffect(() => {
        const timer = setTimeout(() => {
            fetchNotices();
        }, 300); // Debounce
        return () => clearTimeout(timer);
    }, [searchTerm, filterType, currentPage]);

    React.useEffect(() => {
        // Deep link handling
        try {
            const hash = window.location.hash;
            console.log('Current hash:', hash);
            const match = hash.match(/[?&]id=([^&]+)/);
            if (match && match[1]) {
                const id = decodeURIComponent(match[1]);
                console.log('Found ID from URL:', id);
                setSelectedId(id);
            }
        } catch (e) {
            console.error('Error parsing URL param', e);
        }
    }, []); // Run once on mount

    const filteredNotices = notices; // Logic moved to backend

    if (selectedId) {
        return <AnnouncementDetail id={selectedId} onBack={() => {
            // Check if we opened via deep link (URL has id)
            const isDeepLink = window.location.hash.includes('?id=') || window.location.hash.includes('&id=');

            setSelectedId(null);

            if (isDeepLink) {
                // If it was a deep link (from Home), go back to Home
                window.location.href = '#/dashboard';
            } else {
                // Otherwise (from List click), just clear state and refresh
                fetchNotices();
            }
        }} />;
    }

    const handleDelete = async (id: string) => {
        Modal.confirm({
            title: '确认删除',
            content: '确定要删除这条公告吗？',
            okText: '确认',
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
                        fetchNotices(); // Refresh list
                    } else {
                        message.error('删除失败，可能无权限');
                    }
                } catch (error) {
                    message.error('删除请求出错');
                }
            }
        });
    };

    return (
        <div className="space-y-4">
            {/* Search and Filter Bar */}
            <div className="flex flex-col sm:flex-row gap-4 justify-between">
                <div className="relative flex-1 max-w-md">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
                    <input
                        type="text"
                        placeholder="搜索公告标题..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500 transition-all text-sm"
                    />
                </div>
                <div className="flex gap-2">
                    <select
                        value={filterType}
                        onChange={(e) => setFilterType(e.target.value)}
                        className="px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-600 focus:outline-none focus:border-red-500 cursor-pointer"
                    >
                        <option value="all">所有类型</option>
                        <option value="urgent">紧急通知</option>
                        <option value="normal">一般公告</option>
                        <option value="update">系统更新</option>
                    </select>
                    <button className="p-2 border border-slate-200 rounded-lg text-slate-500 hover:bg-slate-50">
                        <Filter className="w-4 h-4" />
                    </button>
                </div>
            </div>

            {/* Table */}
            <div className="overflow-x-auto border border-slate-200 rounded-lg">
                <table className="w-full text-sm text-left">
                    <thead className="bg-slate-50 text-slate-500 font-medium border-b border-slate-200">
                        <tr>
                            <th className="px-4 py-3 w-16">状态</th>
                            <th className="px-4 py-3">标题</th>
                            <th className="px-4 py-3 w-32">分类</th>
                            <th className="px-4 py-3 w-48">所属系统</th>
                            <th className="px-4 py-3 w-20">阅读量</th>
                            <th className="px-4 py-3 w-24">发布人</th>
                            <th className="px-4 py-3 w-40">发布时间</th>
                            <th className="px-4 py-3 w-24 text-center">操作</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                        {filteredNotices.length === 0 ? (
                            <tr>
                                <td colSpan={5} className="px-4 py-8 text-center text-slate-400">
                                    未找到相关公告
                                </td>
                            </tr>
                        ) : (
                            filteredNotices.map((notice) => (
                                <tr key={notice.id} className="hover:bg-slate-50 transition-colors group">
                                    <td className="px-4 py-3">
                                        {notice.type === 'urgent' && (
                                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-700">
                                                紧急
                                            </span>
                                        )}
                                        {notice.type === 'normal' && (
                                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-700">
                                                一般
                                            </span>
                                        )}
                                        {notice.type === 'update' && (
                                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-amber-100 text-amber-700">
                                                更新
                                            </span>
                                        )}
                                    </td>
                                    <td className="px-4 py-3 font-medium text-slate-700 group-hover:text-red-600 transition-colors cursor-pointer max-w-md truncate" title={notice.title} onClick={() => setSelectedId(notice.id)}>
                                        <div className="flex items-center gap-2">
                                            {!notice.hasRead && <Badge status="error" />}
                                            <span className="truncate">{notice.title}</span>
                                        </div>
                                    </td>
                                    <td className="px-4 py-3 text-slate-500">
                                        {notice.category === 'Announcement' ? '通知公告' : '更新日志'}
                                    </td>
                                    <td className="px-4 py-3 text-slate-500 text-xs">
                                        {(() => {
                                            try {
                                                const sys = typeof notice.systems === 'string' ? JSON.parse(notice.systems) : notice.systems;
                                                return Array.isArray(sys) ? sys.join(', ') : sys;
                                            } catch (e) {
                                                return notice.systems || '-';
                                            }
                                        })()}
                                    </td>
                                    <td className="px-4 py-3 text-slate-500 text-xs text-center">
                                        {notice.readCount || 0}
                                    </td>
                                    <td className="px-4 py-3 text-slate-500 text-xs">
                                        {notice.createBy || '-'}
                                    </td>
                                    <td className="px-4 py-3 text-slate-500 font-mono text-xs">
                                        {notice.createTime ? new Date(notice.createTime).toLocaleString() : notice.date}
                                    </td>
                                    <td className="px-4 py-3">
                                        <div className="flex items-center justify-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                            <button className="p-1 text-slate-400 hover:text-blue-600 transition-colors" title="查看" onClick={() => setSelectedId(notice.id)}>
                                                <Eye className="w-4 h-4" />
                                            </button>

                                            {/* Only show Edit/Delete if current user is the publisher */}
                                            {(() => {
                                                const userStr = localStorage.getItem('auth_user');
                                                const currentUser = userStr ? JSON.parse(userStr).empId : 'admin';

                                                if (notice.createBy === currentUser) {
                                                    return (
                                                        <>
                                                            <button className="p-1 text-slate-400 hover:text-slate-700 transition-colors" title="编辑">
                                                                <Edit className="w-4 h-4" />
                                                            </button>
                                                            <button
                                                                className="p-1 text-slate-400 hover:text-red-600 transition-colors"
                                                                title="删除"
                                                                onClick={() => handleDelete(notice.id)}
                                                            >
                                                                <Trash2 className="w-4 h-4" />
                                                            </button>
                                                        </>
                                                    );
                                                }
                                                return null;
                                            })()}
                                        </div>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Pagination */}
            <div className="flex items-center justify-between text-sm text-slate-500 pt-2">
                <div>共 {total} 条记录</div>
                <div className="flex gap-1">
                    <button
                        onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                        disabled={currentPage === 1 || loading}
                        className="px-3 py-1 border border-slate-200 rounded hover:bg-slate-50 disabled:opacity-50"
                    >
                        上一页
                    </button>
                    <span className="px-3 py-1 bg-red-600 text-white rounded shadow-sm">{currentPage}</span>
                    <button
                        onClick={() => setCurrentPage(p => p + 1)}
                        disabled={notices.length < 10 || loading} // Simple check, better to use total pages
                        className="px-3 py-1 border border-slate-200 rounded hover:bg-slate-50 disabled:opacity-50"
                    >
                        下一页
                    </button>
                </div>
            </div>
        </div>
    );
};

export default AnnouncementList;
