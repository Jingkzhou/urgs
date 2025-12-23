import React, { useEffect, useState } from 'react';
import { Select, InputNumber } from 'antd';
import { Clock, Calendar, Repeat, ArrowRightLeft } from 'lucide-react';

interface CronPickerProps {
    value?: string;
    onChange: (value: string) => void;
    offset?: number;
    onOffsetChange?: (value: number) => void;
}

const CronPicker: React.FC<CronPickerProps> = ({ value, onChange, offset, onOffsetChange }) => {
    // Default: 0 0 * * * ? (Daily at 00:00:00)
    const [parts, setParts] = useState<string[]>(['0', '0', '*', '*', '*', '?']);

    useEffect(() => {
        if (value) {
            const split = value.split(' ');
            if (split.length >= 6) {
                setParts(split);
            } else if (split.length === 5) {
                // Handle 5-part cron (min hour day month week) -> convert to 6-part (sec min hour day month week)
                setParts(['0', ...split]);
            }
        }
    }, [value]);

    const updatePart = (index: number, val: string) => {
        const newParts = [...parts];
        newParts[index] = val;

        // Smart handling for Day (index 3) vs Week (index 5)
        // If Day is specified (not * and not ?), Week must be ?
        if (index === 3 && val !== '?' && val !== '*') {
            newParts[5] = '?';
        }
        // If Week is specified (not * and not ?), Day must be ?
        if (index === 5 && val !== '?' && val !== '*') {
            newParts[3] = '?';
        }

        // If both are * or ?, ensure one is ? to be valid Quartz (usually)
        if (newParts[3] === '*' && newParts[5] === '*') {
            newParts[5] = '?';
        }

        setParts(newParts);
        onChange(newParts.join(' '));
    };

    const range = (start: number, end: number) => {
        return Array.from({ length: end - start + 1 }, (_, i) => {
            const val = (start + i).toString();
            return { label: val.padStart(2, '0'), value: val };
        });
    };

    // Custom styles for Select to look cleaner
    const selectProps = {
        size: 'small' as const,
        variant: 'borderless' as const,
        className: "font-mono text-xs text-slate-600 bg-slate-50/50 hover:bg-slate-100 rounded transition-colors",
        style: { width: '100%' }
    };

    return (
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
            <div className="flex divide-x divide-slate-100">
                {/* Time Section */}
                <div className="flex-1 p-3 space-y-3">
                    <div className="flex items-center gap-2 text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                        <Clock size={12} />
                        时间配置
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                        <div className="space-y-1">
                            <label className="text-[10px] text-slate-400 font-medium ml-1">分钟</label>
                            <Select
                                {...selectProps}
                                value={parts[1]}
                                onChange={(v) => updatePart(1, v)}
                                options={[
                                    { label: '每分钟 (*)', value: '*' },
                                    { label: '每5分钟 (*/5)', value: '*/5' },
                                    { label: '每10分钟 (*/10)', value: '*/10' },
                                    { label: '每15分钟 (*/15)', value: '*/15' },
                                    { label: '每30分钟 (*/30)', value: '*/30' },
                                    { label: '0分', value: '0' },
                                    { label: '15分', value: '15' },
                                    { label: '30分', value: '30' },
                                    { label: '45分', value: '45' },
                                    ...range(0, 59)
                                        .filter(o => !['0', '15', '30', '45'].includes(o.value))
                                        .map(o => ({ label: `${o.label}分`, value: o.value }))
                                ]}
                            />
                        </div>
                        <div className="space-y-1">
                            <label className="text-[10px] text-slate-400 font-medium ml-1">小时</label>
                            <Select
                                {...selectProps}
                                value={parts[2]}
                                onChange={(v) => updatePart(2, v)}
                                options={[
                                    { label: '每小时 (*)', value: '*' },
                                    { label: '每2小时 (*/2)', value: '*/2' },
                                    { label: '每4小时 (*/4)', value: '*/4' },
                                    { label: '每6小时 (*/6)', value: '*/6' },
                                    { label: '每12小时 (*/12)', value: '*/12' },
                                    ...range(0, 23).map(o => ({ label: `${o.label}时`, value: o.value }))
                                ]}
                            />
                        </div>
                    </div>
                </div>

                {/* Date Section */}
                <div className="flex-[1.5] p-3 space-y-3 bg-slate-50/30">
                    <div className="flex items-center gap-2 text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                        <Calendar size={12} />
                        日期配置
                    </div>

                    <div className="grid grid-cols-3 gap-3">
                        <div className="space-y-1">
                            <label className="text-[10px] text-slate-400 font-medium ml-1">日</label>
                            <Select
                                {...selectProps}
                                value={parts[3]}
                                onChange={(v) => updatePart(3, v)}
                                options={[
                                    { label: '每天 (*)', value: '*' },
                                    { label: '不指定 (?)', value: '?' },
                                    ...range(1, 31).map(o => ({ label: `${o.label}日`, value: o.value }))
                                ]}
                            />
                        </div>
                        <div className="space-y-1">
                            <label className="text-[10px] text-slate-400 font-medium ml-1">月</label>
                            <Select
                                {...selectProps}
                                value={parts[4]}
                                onChange={(v) => updatePart(4, v)}
                                options={[
                                    { label: '每月 (*)', value: '*' },
                                    ...range(1, 12).map(o => ({ label: `${o.label}月`, value: o.value }))
                                ]}
                            />
                        </div>
                        <div className="space-y-1">
                            <label className="text-[10px] text-slate-400 font-medium ml-1">周</label>
                            <Select
                                {...selectProps}
                                value={parts[5]}
                                onChange={(v) => updatePart(5, v)}
                                options={[
                                    { label: '每周 (*)', value: '*' },
                                    { label: '不指定 (?)', value: '?' },
                                    { label: '周日 (1)', value: '1' },
                                    { label: '周一 (2)', value: '2' },
                                    { label: '周二 (3)', value: '3' },
                                    { label: '周三 (4)', value: '4' },
                                    { label: '周四 (5)', value: '5' },
                                    { label: '周五 (6)', value: '6' },
                                    { label: '周六 (7)', value: '7' },
                                ]}
                            />
                        </div>
                    </div>
                </div>
            </div>

            {/* Footer: Preview & Offset */}
            <div className="bg-slate-50 px-3 py-2 border-t border-slate-100 flex items-center justify-between">
                <div className="flex items-center gap-4">
                    {/* Preview */}
                    <div className="flex items-center gap-2">
                        <Repeat size={12} className="text-slate-400" />
                        <span className="text-[10px] text-slate-500 font-medium">预览:</span>
                        <code className="text-xs font-mono text-blue-600 bg-blue-50 px-2 py-0.5 rounded border border-blue-100">
                            {parts.join(' ')}
                        </code>
                    </div>

                    {/* Offset (Optional) */}
                    {onOffsetChange && (
                        <div className="flex items-center gap-2 pl-4 border-l border-slate-200">
                            <ArrowRightLeft size={12} className="text-slate-400" />
                            <span className="text-[10px] text-slate-500 font-medium">偏移量:</span>
                            <InputNumber
                                size="small"
                                value={offset}
                                onChange={(val) => onOffsetChange(val || 0)}
                                className="w-16 text-xs"
                                variant="borderless"
                                style={{ backgroundColor: 'rgba(248, 250, 252, 0.5)' }}
                            />
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default CronPicker;
