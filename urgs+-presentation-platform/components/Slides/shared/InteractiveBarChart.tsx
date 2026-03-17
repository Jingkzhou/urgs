import React, { useState } from 'react';
import { Zap, ShieldCheck, ShieldAlert, BookOpen } from 'lucide-react';

export const InteractiveBarChart = () => {
    const [data, setData] = useState([
        { label: '交付效率', value: 65, color: 'bg-indigo-500', icon: <Zap className="w-3 h-3" /> },
        { label: '合规覆盖率', value: 85, color: 'bg-teal-500', icon: <ShieldCheck className="w-3 h-3" /> },
        { label: '变更风险降幅', value: 45, color: 'bg-rose-500', icon: <ShieldAlert className="w-3 h-3" /> },
        { label: '知识转化率', value: 40, color: 'bg-amber-500', icon: <BookOpen className="w-3 h-3" /> },
    ]);

    const handleInteraction = (index: number, e: React.MouseEvent | React.TouchEvent) => {
        const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
        const clientX = 'touches' in e ? (e as React.TouchEvent).touches[0].clientX : (e as React.MouseEvent).clientX;
        const percent = Math.round(((clientX - rect.left) / rect.width) * 100);
        const nextData = [...data];
        nextData[index].value = Math.min(100, Math.max(0, percent));
        setData(nextData);
    };

    return (
        <div className="flex flex-col gap-5 w-full bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
            <div className="flex justify-between items-center mb-2">
                <h4 className="text-sm font-bold text-slate-800 uppercase tracking-wider">效能指标模拟</h4>
                <div className="text-[10px] text-slate-400 bg-slate-50 px-2 py-1 rounded">实时模拟 URGS+ 赋能增益</div>
            </div>
            {data.map((item, i) => (
                <div key={i} className="space-y-2 group">
                    <div className="flex justify-between text-xs font-bold text-slate-500 group-hover:text-slate-800 transition-colors">
                        <div className="flex items-center gap-1.5">
                            {item.icon}
                            <span>{item.label}</span>
                        </div>
                        <span className="font-mono">{item.value}%</span>
                    </div>
                    <div
                        className="h-3 bg-slate-100 rounded-full overflow-hidden cursor-pointer relative"
                        onMouseDown={(e) => handleInteraction(i, e)}
                        onTouchStart={(e) => handleInteraction(i, e)}
                    >
                        <div
                            className={`h-full ${item.color} transition-all duration-500 ease-out shadow-sm`}
                            style={{ width: `${item.value}%` }}
                        />
                    </div>
                </div>
            ))}
        </div>
    );
};
