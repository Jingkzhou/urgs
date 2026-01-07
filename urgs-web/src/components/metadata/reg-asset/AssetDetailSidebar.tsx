import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import {
    X, ChevronDown, ChevronRight, Table2, Target, Hash,
    Calendar, FileText, BookOpen, Code, Zap, Info,
    Database, Activity, Server, Shield
} from 'lucide-react';
import { RegTable, RegElement } from './types';
import Editor from '@monaco-editor/react';
import { getAutoFetchStatusBadge } from './components/RegAssetHelper';

interface AssetDetailSidebarProps {
    isOpen: boolean;
    onClose: () => void;
    type: 'TABLE' | 'ELEMENT';
    data: RegTable | RegElement | null;
}

// Helper for Detail Items
const DetailRow: React.FC<{
    label: string;
    value: React.ReactNode;
    icon?: React.ReactNode;
    fullWidth?: boolean;
    className?: string;
}> = ({ label, value, icon, fullWidth, className }) => (
    <div className={`flex flex-col gap-1.5 ${fullWidth ? 'col-span-2' : ''} ${className}`}>
        <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-500 uppercase tracking-wider">
            {icon && <span className="text-indigo-400">{icon}</span>}
            {label}
        </div>
        <div className="text-sm text-slate-700 font-medium break-words leading-relaxed min-h-[20px]">
            {value || <span className="text-slate-300 italic">空</span>}
        </div>
    </div>
);

// Accordion Section Component
const AccordionSection: React.FC<{
    title: string;
    icon: React.ReactNode;
    defaultOpen?: boolean;
    children: React.ReactNode;
}> = ({ title, icon, defaultOpen = true, children }) => {
    const [isOpen, setIsOpen] = useState(defaultOpen);

    return (
        <div className="border border-slate-200 bg-white rounded-xl shadow-sm overflow-hidden transition-all duration-300 hover:shadow-md">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="w-full flex items-center justify-between p-4 bg-slate-50/50 hover:bg-slate-50 transition-colors"
            >
                <div className="flex items-center gap-2.5 font-bold text-slate-700">
                    <span className="p-1.5 bg-indigo-50 text-indigo-600 rounded-lg">{icon}</span>
                    {title}
                </div>
                <div className={`transition-transform duration-300 ${isOpen ? 'rotate-180' : ''}`}>
                    <ChevronDown size={18} className="text-slate-400" />
                </div>
            </button>
            <div
                className={`transition-all duration-300 ease-in-out overflow-hidden ${isOpen ? 'max-h-[2000px] opacity-100' : 'max-h-0 opacity-0'
                    }`}
            >
                <div className="p-5 border-t border-slate-100 grid grid-cols-2 gap-y-6 gap-x-8">
                    {children}
                </div>
            </div>
        </div>
    );
};

export const AssetDetailSidebar: React.FC<AssetDetailSidebarProps> = ({ isOpen, onClose, type, data }) => {
    // Handle escape key
    useEffect(() => {
        const handleEsc = (e: KeyboardEvent) => {
            if (e.key === 'Escape') onClose();
        };
        if (isOpen) window.addEventListener('keydown', handleEsc);
        return () => window.removeEventListener('keydown', handleEsc);
    }, [isOpen, onClose]);

    if (!data) return null;

    const isTable = type === 'TABLE';
    const table = data as RegTable;
    const element = data as RegElement;

    // determine icon and color based on type
    const HeaderIcon = isTable ? Table2 : (element.type === 'FIELD' ? Hash : Target);
    const headerColorClass = isTable ? 'text-blue-600 bg-blue-50' : (element.type === 'FIELD' ? 'text-slate-600 bg-slate-100' : 'text-purple-600 bg-purple-50');

    return createPortal(
        <>
            {/* Backdrop */}
            <div
                className={`fixed inset-0 bg-slate-900/20 backdrop-blur-sm z-[9999] transition-opacity duration-300 ${isOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'
                    }`}
                onClick={onClose}
            />

            {/* Sidebar */}
            <div
                className={`fixed top-0 right-0 h-full w-[650px] bg-slate-50 shadow-2xl z-[10000] transform transition-transform duration-300 ease-out flex flex-col border-l border-slate-200 ${isOpen ? 'translate-x-0' : 'translate-x-full'
                    }`}
            >
                {/* Header */}
                <div className="flex-none p-6 bg-white border-b border-slate-200 flex justify-between items-start shadow-sm z-10">
                    <div className="flex gap-4 pr-8">
                        <div className={`p-3.5 rounded-xl shadow-sm h-fit ${headerColorClass}`}>
                            <HeaderIcon size={28} />
                        </div>
                        <div>
                            <div className="flex items-center gap-2 mb-1">
                                <span className={`text-xs font-bold px-2 py-0.5 rounded-full border ${isTable ? 'bg-blue-50 text-blue-700 border-blue-100' :
                                    (element.type === 'FIELD' ? 'bg-slate-100 text-slate-700 border-slate-200' : 'bg-purple-50 text-purple-700 border-purple-100')
                                    }`}>
                                    {isTable ? '报表' : (element.type === 'FIELD' ? '字段' : '指标')}
                                </span>
                                <span className="text-xs font-mono text-slate-400">#{data.id}</span>
                            </div>
                            <h2 className="text-xl font-bold text-slate-800 leading-tight mb-1.5">
                                {data.cnName || data.name}
                            </h2>
                            <div className="text-sm text-slate-500 font-mono bg-slate-100 px-2 py-0.5 rounded-md inline-block">
                                {data.name}
                            </div>
                        </div>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-slate-100 rounded-full text-slate-400 hover:text-slate-600 transition-colors"
                    >
                        <X size={24} />
                    </button>
                </div>

                {/* Content - Scrollable */}
                <div className="flex-1 overflow-y-auto p-6 space-y-6 scrollbar-thin scrollbar-thumb-slate-200 scrollbar-track-transparent">

                    {/* Section 1: Basic Info */}
                    <AccordionSection title="基础信息" icon={<Info size={18} />}>
                        <DetailRow label="中文名称" value={data.cnName} fullWidth />
                        <DetailRow label="英文名称" value={data.name} fullWidth />
                        <DetailRow label="排序序号" value={data.sortOrder} />
                        <DetailRow label="状态" value={
                            data.status === 1 ?
                                <span className="text-emerald-600 flex items-center gap-1"><Activity size={12} /> 启用</span> :
                                <span className="text-slate-400">停用</span>
                        } />
                    </AccordionSection>

                    {/* Section 2: Business Attributes */}
                    <AccordionSection title="业务属性" icon={<BookOpen size={18} />}>
                        {isTable && (
                            <>
                                <DetailRow label="监管主题" value={table.theme} />
                                <DetailRow label="报送频度" value={table.frequency} />
                                <DetailRow label="科目号" value={table.subjectCode} />
                                <DetailRow label="科目名称" value={table.subjectName} />
                            </>
                        )}

                        <DetailRow label="业务口径" value={data.businessCaliber} fullWidth className="bg-amber-50/50 p-3 rounded-lg border border-amber-100/50" />

                        <DetailRow label="发文号" icon={<FileText size={14} />} value={data.dispatchNo} fullWidth />

                        {isTable && (
                            <DetailRow label="填报说明" value={table.fillInstruction} fullWidth className="bg-blue-50/50 p-3 rounded-lg border border-blue-100/50" />
                        )}

                        {!isTable && element.type === 'INDICATOR' && (
                            <DetailRow label="填报说明" value={element.fillInstruction} fullWidth className="bg-blue-50/50 p-3 rounded-lg border border-blue-100/50" />
                        )}

                        <div className="col-span-2 grid grid-cols-2 gap-6 pt-2 border-t border-slate-100 mt-2">
                            <DetailRow label="生效日期" icon={<Calendar size={14} />} value={data.effectiveDate} />
                            <DetailRow label="自动取数" value={getAutoFetchStatusBadge(data.autoFetchStatus)} />
                        </div>

                    </AccordionSection>

                    {/* Section 3: Technical Attributes */}
                    <AccordionSection title="技术属性" icon={<Code size={18} />}>
                        {isTable ? (
                            <>
                                <DetailRow label="所属系统" icon={<Server size={14} />} value={table.systemCode} />
                                <DetailRow label="取数来源" value={table.sourceType} />
                            </>
                        ) : (
                            <>
                                <DetailRow label="类型" value={element.type === 'FIELD' ? '物理字段' : '衍生指标'} />

                                {element.type === 'FIELD' && (
                                    <>
                                        <DetailRow label="数据类型" value={element.dataType} />
                                        <DetailRow label="长度" value={element.length} />
                                        <DetailRow label="是否主键" value={element.isPk ? '是' : '否'} icon={<Shield size={14} />} />
                                        <DetailRow label="允许为空" value={element.nullable ? '是' : '否'} />
                                        <DetailRow label="校验规则" value={element.validationRule} fullWidth />
                                    </>
                                )}

                                {element.type === 'INDICATOR' && (
                                    <>
                                        <DetailRow label="计算公式" icon={<Zap size={14} />} value={element.formula} fullWidth className="font-mono text-xs bg-slate-50 p-2 rounded border border-slate-200" />
                                        <DetailRow label="值域代码表" value={element.codeTableCode} />
                                        <DetailRow label="取值范围" value={element.valueRange} />

                                        <div className="col-span-2 mt-2">
                                            <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                                                <Code size={14} className="text-indigo-400" /> 代码片段
                                            </div>
                                            <div className="border border-slate-200 rounded-lg overflow-hidden shadow-inner">
                                                {element.codeSnippet ? (
                                                    <Editor
                                                        height="200px"
                                                        language="sql"
                                                        value={element.codeSnippet}
                                                        theme="vs-dark"
                                                        options={{
                                                            readOnly: true,
                                                            minimap: { enabled: false },
                                                            scrollBeyondLastLine: false,
                                                            lineNumbers: 'off',
                                                            folding: false,
                                                            fontSize: 12,
                                                            wordWrap: 'on',
                                                            padding: { top: 10, bottom: 10 }
                                                        }}
                                                    />
                                                ) : (
                                                    <div className="p-8 text-center text-slate-400 bg-slate-50 text-sm">暂无代码片段</div>
                                                )}
                                            </div>
                                        </div>
                                    </>
                                )}
                            </>
                        )}
                        <DetailRow label="开发备注" value={data.devNotes} fullWidth className="mt-2" />
                    </AccordionSection>
                </div>
            </div>
        </>,
        document.body
    );
};
