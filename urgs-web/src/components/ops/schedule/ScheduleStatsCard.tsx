import React from 'react';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface ScheduleStatsCardProps {
    title: string;
    value: number | string;
    icon: React.ReactNode;
    trend?: 'up' | 'down' | 'neutral';
    trendValue?: string;
    color?: 'blue' | 'green' | 'red' | 'amber' | 'purple';
}

const colorMap = {
    blue: {
        indicator: 'bg-blue-500',
        lightBg: 'bg-blue-50',
        iconColor: 'text-blue-600',
    },
    green: {
        indicator: 'bg-emerald-500',
        lightBg: 'bg-emerald-50',
        iconColor: 'text-emerald-600',
    },
    red: {
        indicator: 'bg-rose-500',
        lightBg: 'bg-rose-50',
        iconColor: 'text-rose-600',
    },
    amber: {
        indicator: 'bg-amber-500',
        lightBg: 'bg-amber-50',
        iconColor: 'text-amber-600',
    },
    purple: {
        indicator: 'bg-indigo-500',
        lightBg: 'bg-indigo-50',
        iconColor: 'text-indigo-600',
    }
};

const ScheduleStatsCard: React.FC<ScheduleStatsCardProps> = ({
    title,
    value,
    icon,
    trend,
    trendValue,
    color = 'blue'
}) => {
    const colors = colorMap[color];

    return (
        <div className="relative group bg-white rounded-2xl border border-slate-200/60 p-5 transition-all duration-300 hover:shadow-xl hover:border-slate-300/50">
            {/* Minimal left indicator */}
            <div className={`absolute left-0 top-6 bottom-6 w-1 rounded-r-full ${colors.indicator} opacity-80`} />

            <div className="flex items-center justify-between">
                <div>
                    <p className="text-[13px] font-semibold text-slate-500 uppercase tracking-wider mb-1">
                        {title}
                    </p>
                    <div className="flex items-baseline gap-2">
                        <span className="text-3xl font-bold text-slate-900 tabular-nums">
                            {value}
                        </span>
                        {trend && trendValue && (
                            <div className={`flex items-center gap-0.5 px-1.5 py-0.5 rounded-full text-[11px] font-bold ${trend === 'up' ? 'bg-emerald-50 text-emerald-600' :
                                trend === 'down' ? 'bg-rose-50 text-rose-600' : 'bg-slate-50 text-slate-500'
                                }`}>
                                {trend === 'up' && <TrendingUp size={10} />}
                                {trend === 'down' && <TrendingDown size={10} />}
                                {trendValue}
                            </div>
                        )}
                    </div>
                </div>

                <div className={`flex items-center justify-center w-12 h-12 rounded-2xl ${colors.lightBg} ${colors.iconColor} transition-transform group-hover:scale-110 duration-500 shadow-sm`}>
                    {React.cloneElement(icon as any, { size: 24, strokeWidth: 2.5 })}
                </div>
            </div>
        </div>
    );
};

export default ScheduleStatsCard;
