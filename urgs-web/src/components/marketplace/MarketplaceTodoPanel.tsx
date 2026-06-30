import React, { useEffect, useState } from 'react';
import { AlertCircle, Bell, CheckCircle2 } from 'lucide-react';
import { getMarketplaceTodos, MarketplaceTodo } from '../../api/marketplace';

interface MarketplaceTodoPanelProps {
    onSelectTab: (tab: string) => void;
}

const severityClass: Record<MarketplaceTodo['severity'], string> = {
    info: 'border-blue-100 bg-blue-50 text-blue-700',
    warning: 'border-amber-100 bg-amber-50 text-amber-700',
    danger: 'border-red-100 bg-red-50 text-red-700',
};

const MarketplaceTodoPanel: React.FC<MarketplaceTodoPanelProps> = ({ onSelectTab }) => {
    const [todos, setTodos] = useState<MarketplaceTodo[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchTodos();
    }, []);

    const fetchTodos = async () => {
        setLoading(true);
        try {
            const res = await getMarketplaceTodos();
            setTodos(res || []);
        } catch (error) {
            console.error('Failed to fetch marketplace todos', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-400">
                正在刷新待办...
            </div>
        );
    }

    if (todos.length === 0) {
        return (
            <div className="rounded-xl border border-green-100 bg-green-50 px-4 py-3 flex items-center gap-3">
                <CheckCircle2 size={18} className="text-green-600" />
                <div>
                    <div className="text-sm font-bold text-green-700">当前没有待处理事项</div>
                    <div className="text-xs text-green-600 mt-0.5">任务中心流程暂时是清爽的，可以继续领取或发布任务。</div>
                </div>
            </div>
        );
    }

    return (
        <div className="rounded-xl border border-slate-200 bg-white px-4 py-3">
            <div className="flex items-center gap-2 mb-3">
                <Bell size={17} className="text-slate-500" />
                <span className="text-sm font-bold text-slate-800">我的待办</span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                {todos.map(todo => (
                    <button
                        key={todo.type}
                        type="button"
                        onClick={() => onSelectTab(todo.targetTab)}
                        className={`text-left rounded-lg border px-3 py-2 transition-all hover:shadow-sm ${severityClass[todo.severity]}`}
                    >
                        <div className="flex items-center justify-between gap-3">
                            <div className="flex items-center gap-2 min-w-0">
                                <AlertCircle size={15} />
                                <span className="text-sm font-bold truncate">{todo.title}</span>
                            </div>
                            <span className="text-lg font-black">{todo.count}</span>
                        </div>
                        <div className="text-xs opacity-80 mt-1 truncate">{todo.description}</div>
                    </button>
                ))}
            </div>
        </div>
    );
};

export default MarketplaceTodoPanel;
