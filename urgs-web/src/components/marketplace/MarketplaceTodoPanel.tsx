import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Bell, CheckCircle2, ChevronDown, Loader2 } from 'lucide-react';
import { getMarketplaceTodos, MarketplaceTodo } from '../../api/marketplace';

interface MarketplaceTodoPanelProps {
    onSelectTodo: (todo: MarketplaceTodo) => void;
}

const severityTone: Record<MarketplaceTodo['severity'], {
    button: string;
    item: string;
    dot: string;
    count: string;
}> = {
    info: {
        button: 'border-blue-100 bg-blue-50 text-blue-700 hover:border-blue-200 hover:bg-blue-100/70',
        item: 'border-blue-100 bg-blue-50/50 text-blue-700 hover:bg-blue-50',
        dot: 'bg-blue-500',
        count: 'text-blue-700',
    },
    warning: {
        button: 'border-amber-100 bg-amber-50 text-amber-700 hover:border-amber-200 hover:bg-amber-100/70',
        item: 'border-amber-100 bg-amber-50/60 text-amber-700 hover:bg-amber-50',
        dot: 'bg-amber-500',
        count: 'text-amber-700',
    },
    danger: {
        button: 'border-red-100 bg-red-50 text-red-700 hover:border-red-200 hover:bg-red-100/70',
        item: 'border-red-100 bg-red-50/60 text-red-700 hover:bg-red-50',
        dot: 'bg-red-500',
        count: 'text-red-700',
    },
};

const MarketplaceTodoPanel: React.FC<MarketplaceTodoPanelProps> = ({ onSelectTodo }) => {
    const [todos, setTodos] = useState<MarketplaceTodo[]>([]);
    const [loading, setLoading] = useState(true);
    const [open, setOpen] = useState(false);
    const wrapperRef = useRef<HTMLDivElement>(null);

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

    useEffect(() => {
        if (!open) return;

        const handleClickOutside = (event: MouseEvent) => {
            if (!wrapperRef.current?.contains(event.target as Node)) {
                setOpen(false);
            }
        };

        document.addEventListener('mousedown', handleClickOutside);
        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [open]);

    const totalCount = useMemo(
        () => todos.reduce((sum, todo) => sum + (todo.count || 0), 0),
        [todos]
    );

    const buttonSeverity = useMemo<MarketplaceTodo['severity']>(() => {
        if (todos.some(todo => todo.severity === 'danger')) return 'danger';
        if (todos.some(todo => todo.severity === 'warning')) return 'warning';
        return 'info';
    }, [todos]);

    if (loading) {
        return (
            <div className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-400 shadow-sm">
                <Loader2 size={14} className="animate-spin" />
                我的待办
            </div>
        );
    }

    if (todos.length === 0) {
        return (
            <div className="inline-flex items-center gap-2 rounded-xl border border-emerald-100 bg-emerald-50 px-3 py-2 text-xs font-bold text-emerald-700 shadow-sm">
                <CheckCircle2 size={14} />
                <span>待办清零</span>
            </div>
        );
    }

    return (
        <div ref={wrapperRef} className="relative">
            <button
                type="button"
                onClick={() => setOpen(value => !value)}
                className={`inline-flex items-center gap-2 rounded-xl border px-3 py-2 text-xs font-bold shadow-sm transition-all ${severityTone[buttonSeverity].button}`}
                aria-expanded={open}
                aria-label="我的待办"
            >
                <Bell size={14} />
                <span>我的待办</span>
                <span className="rounded-full bg-white/80 px-2 py-0.5 text-[11px] leading-none shadow-sm">{totalCount}</span>
                <ChevronDown size={13} className={`transition-transform ${open ? 'rotate-180' : ''}`} />
            </button>

            <div
                className={`absolute right-0 top-full z-30 mt-2 w-80 max-w-[calc(100vw-2rem)] overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xl shadow-slate-200/70 transition-all ${
                    open ? 'pointer-events-auto translate-y-0 opacity-100' : 'pointer-events-none -translate-y-1 opacity-0'
                }`}
            >
                <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
                    <div>
                        <div className="text-sm font-black text-slate-800">我的待办</div>
                        <div className="mt-0.5 text-[11px] font-medium text-slate-400">共 {totalCount} 项待处理</div>
                    </div>
                    <span className={`rounded-full px-2.5 py-1 text-xs font-black ${severityTone[buttonSeverity].button}`}>
                        {totalCount}
                    </span>
                </div>

                <div className="space-y-2 p-2">
                    {todos.map(todo => (
                        <button
                            key={todo.type}
                            type="button"
                            onClick={() => {
                                onSelectTodo(todo);
                                setOpen(false);
                            }}
                            className={`flex w-full items-center gap-3 rounded-lg border px-3 py-2.5 text-left transition-colors ${severityTone[todo.severity].item}`}
                        >
                            <span className={`h-2 w-2 shrink-0 rounded-full ${severityTone[todo.severity].dot}`} />
                            <span className="min-w-0 flex-1">
                                <span className="block truncate text-xs font-black">{todo.title}</span>
                                <span className="mt-0.5 block truncate text-[11px] font-medium opacity-75">{todo.description}</span>
                            </span>
                            <span className={`text-lg font-black leading-none ${severityTone[todo.severity].count}`}>
                                {todo.count}
                            </span>
                        </button>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default MarketplaceTodoPanel;
