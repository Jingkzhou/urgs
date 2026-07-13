import React from 'react';
import { CheckCircle, TrendingUp, CircleDashed } from 'lucide-react';

export const getAutoFetchStatusBadge = (status?: string) => {
    const map: Record<string, { bg: string; text: string; icon: React.ReactNode; color: string; label: string }> = {
        '已上线': { bg: 'bg-emerald-50', text: 'text-emerald-600', icon: <CheckCircle size={12} />, color: 'emerald', label: '已上线' },
        '开发中': { bg: 'bg-amber-50', text: 'text-amber-600', icon: <TrendingUp size={12} />, color: 'amber', label: '开发中' },
        '未开发': { bg: 'bg-slate-100', text: 'text-slate-500', icon: <CircleDashed size={12} />, color: 'slate', label: '未开发' },
    };
    const s = map[status || ''] || map['未开发'];
    return (
        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold tracking-wide uppercase ${s.bg} ${s.text} border border-transparent hover:border-${s.color}-200 transition-colors`}>
            {s.icon} {s.label}
        </span>
    );
};

export const TableSkeleton = () => (
    <div className="flex flex-col h-full overflow-hidden bg-white">
        {[...Array(8)].map((_, i) => (
            <div key={i} className="flex items-center px-4 py-4 border-b border-slate-50 animate-pulse">
                <div className="w-8 h-4 bg-slate-100 rounded mr-2" />
                <div className="w-10 h-10 bg-slate-50 rounded-lg mr-4" />
                <div className="flex-1 space-y-2">
                    <div className="h-4 bg-slate-100 rounded w-1/4" />
                    <div className="h-3 bg-slate-50 rounded w-1/3" />
                </div>
                <div className="w-24 h-4 bg-slate-50 rounded mr-4" />
                <div className="w-24 h-6 bg-slate-50 rounded-full" />
            </div>
        ))}
    </div>
);

export const CardSkeleton = () => (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6 overflow-y-auto">
        {[...Array(6)].map((_, i) => (
            <div key={i} className="bg-white border border-slate-200 rounded-2xl p-5 space-y-4 animate-pulse shadow-sm">
                <div className="flex justify-between items-start">
                    <div className="w-12 h-12 bg-slate-100 rounded-xl" />
                    <div className="w-20 h-6 bg-slate-50 rounded-full" />
                </div>
                <div className="space-y-3">
                    <div className="h-5 bg-slate-100 rounded w-3/4" />
                    <div className="h-4 bg-slate-50 rounded w-1/2" />
                </div>
                <div className="pt-4 border-t border-slate-50 grid grid-cols-2 gap-3">
                    <div className="h-6 bg-slate-100 rounded-md" />
                    <div className="h-6 bg-slate-100 rounded-md" />
                </div>
            </div>
        ))}
    </div>
);


export const FormField: React.FC<{ label: string; value?: string; onChange: (v: string) => void }> = ({ label, value, onChange }) => (
    <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">{label}</label>
        <input type="text" className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={value || ''} onChange={e => onChange(e.target.value)} />
    </div>
);
