import React from 'react';
import { Tag, Calendar, FileText } from 'lucide-react';
import { AiOptimizeButton } from '../common/AiOptimizeButton';

export interface ReqInfo {
    reqId: string;
    plannedDate: string;
    changeDescription: string;
}

interface ReqInfoFormGroupProps {
    data: ReqInfo;
    onChange: (data: ReqInfo) => void;
    title?: string; // override title
    className?: string;
}

const ReqInfoFormGroup: React.FC<ReqInfoFormGroupProps> = ({ data, onChange, title = "需求变更管理", className = "" }) => {

    const handleChange = (field: keyof ReqInfo, value: string) => {
        onChange({ ...data, [field]: value });
    };

    return (
        <div className={`bg-amber-50 rounded-xl p-4 border border-amber-100 space-y-3 ${className}`}>
            <div className="flex items-center gap-2 mb-1">
                <Tag size={16} className="text-amber-600" />
                <h4 className="text-sm font-bold text-amber-800">{title}</h4>
            </div>

            <div className="grid grid-cols-2 gap-4">
                {/* 需求编号 */}
                <div>
                    <label className="block text-xs font-medium text-amber-800/80 mb-1.5">
                        需求编号 (Req ID)
                    </label>
                    <div className="relative">
                        <Tag size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            type="text"
                            placeholder="REQ-2024001"
                            className="w-full pl-9 pr-3 py-2 text-sm border border-amber-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-200 bg-white text-slate-800 placeholder:text-slate-400"
                            value={data.reqId || ''}
                            onChange={(e) => handleChange('reqId', e.target.value)}
                        />
                    </div>
                </div>

                {/* 计划上线时间 */}
                <div>
                    <label className="block text-xs font-medium text-amber-800/80 mb-1.5">
                        计划上线日期
                    </label>
                    <div className="relative">
                        <Calendar size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            type="date"
                            className="w-full pl-9 pr-3 py-2 text-sm border border-amber-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-200 bg-white text-slate-800"
                            value={data.plannedDate || ''}
                            onChange={(e) => handleChange('plannedDate', e.target.value)}
                        />
                    </div>
                </div>
            </div>

            {/* 需求变更描述 */}
            <div>
                <label className="block text-xs font-medium text-amber-800/80 mb-1.5 flex justify-between items-center">
                    需求变更描述
                    <AiOptimizeButton
                        value={data.changeDescription || ''}
                        onApply={(val) => handleChange('changeDescription', val)}
                        promptGenerator={(val) => `你是一个项目经理。请优化以下【需求变更描述】，清晰阐述变更背景、变更内容及影响分析，格式规范。内容：${val}`}
                        className="scale-90 origin-right"
                    />
                </label>
                <div className="relative">
                    <FileText size={14} className="absolute left-3 top-3 text-slate-400" />
                    <textarea
                        rows={3}
                        placeholder="请描述本次变更的原因、背景或影响..."
                        className="w-full pl-9 pr-3 py-2.5 text-sm border border-amber-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-200 resize-none bg-white text-slate-800 placeholder:text-slate-400"
                        value={data.changeDescription || ''}
                        onChange={(e) => handleChange('changeDescription', e.target.value)}
                    />
                </div>
            </div>
        </div>
    );
};

export default ReqInfoFormGroup;
