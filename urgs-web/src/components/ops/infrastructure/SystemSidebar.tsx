import React, { useEffect, useMemo, useState } from 'react';
import { Button, Pagination } from 'antd';
import { BookOpen, Layers, Server } from 'lucide-react';
import type { SystemOption } from './types';

interface SystemSidebarProps {
    systems: SystemOption[];
    selectedSystemId: number | 'all';
    selectedEnvType?: string;
    totalAssets: number;
    totalManuals: number;
    onSelect: (systemId: number | 'all') => void;
    onSelectEnvType: (systemId: number, envType: string) => void;
}

const SystemSidebar: React.FC<SystemSidebarProps> = ({
    systems,
    selectedSystemId,
    selectedEnvType,
    totalAssets,
    totalManuals,
    onSelect,
    onSelectEnvType,
}) => {
    const pageSize = 8;
    const [currentPage, setCurrentPage] = useState(1);
    const totalActiveCount = systems.reduce((sum, item) => sum + item.activeCount, 0);
    const pagedSystems = useMemo(() => {
        const start = (currentPage - 1) * pageSize;
        return systems.slice(start, start + pageSize);
    }, [currentPage, systems]);

    useEffect(() => {
        const maxPage = Math.max(1, Math.ceil(systems.length / pageSize));
        if (currentPage > maxPage) {
            setCurrentPage(maxPage);
        }
    }, [currentPage, systems.length]);

    useEffect(() => {
        if (selectedSystemId === 'all') return;
        const selectedIndex = systems.findIndex(system => system.id === selectedSystemId);
        if (selectedIndex >= 0) {
            setCurrentPage(Math.floor(selectedIndex / pageSize) + 1);
        }
    }, [selectedSystemId, systems]);

    const renderCount = (count: number, active: boolean) => (
        <span
            className={`shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold ${active
                ? 'bg-blue-600 text-white'
                : 'bg-slate-100 text-slate-600'
                }`}
        >
            {count > 999 ? '999+' : count}
        </span>
    );

    const renderSystemItem = (
        key: number | 'all',
        name: string,
        assetCount: number,
        activeCount: number,
        manualCount: number,
        envTypes: SystemOption['envTypes'] = [],
    ) => {
        const active = selectedSystemId === key;
        return (
            <div key={key}>
                <button
                    onClick={() => onSelect(key)}
                    className={`w-full rounded-lg border px-3 py-3 text-left transition-colors ${active
                        ? 'border-blue-200 bg-blue-50 shadow-sm'
                        : 'border-slate-100 bg-white hover:border-slate-200 hover:bg-slate-50'
                        }`}
                >
                    <div className="flex items-center justify-between gap-2">
                        <span className={`truncate text-sm font-semibold ${active ? 'text-blue-700' : 'text-slate-800'}`}>
                            {name}
                        </span>
                        {renderCount(assetCount, active)}
                    </div>
                    <div className="mt-2 flex items-center gap-3 text-xs text-slate-500">
                        <span className="flex items-center gap-1">
                            <Server size={12} />
                            运行 {activeCount}
                        </span>
                        <span className="flex items-center gap-1">
                            <BookOpen size={12} />
                            手册 {manualCount}
                        </span>
                    </div>
                </button>

                {active && key !== 'all' && envTypes.length > 0 && (
                    <div className="ml-4 mt-2 space-y-1 border-l border-slate-200 pl-3">
                        {envTypes.map(envType => {
                            const envActive = selectedEnvType === envType.name;
                            return (
                                <button
                                    key={envType.name}
                                    onClick={() => onSelectEnvType(key, envType.name)}
                                    className={`flex w-full items-center justify-between rounded-md px-2 py-1.5 text-left text-xs transition-colors ${envActive
                                        ? 'bg-cyan-50 text-cyan-700'
                                        : 'text-slate-500 hover:bg-slate-50 hover:text-slate-700'
                                        }`}
                                >
                                    <span className="truncate">{envType.name}</span>
                                    <span className={`rounded-full px-1.5 py-0.5 font-semibold ${envActive ? 'bg-cyan-100 text-cyan-700' : 'bg-slate-100 text-slate-500'}`}>
                                        {envType.assetCount}
                                    </span>
                                </button>
                            );
                        })}
                    </div>
                )}
            </div>
        );
    };

    return (
        <aside className="w-full shrink-0 lg:w-72">
            <div className="rounded-lg border border-slate-200 bg-white p-3 shadow-sm">
                <div className="mb-3 flex items-center justify-between">
                    <div className="flex items-center gap-2 text-sm font-bold text-slate-800">
                        <Layers size={16} className="text-blue-600" />
                        系统视图
                    </div>
                    <Button size="small" type="text" onClick={() => onSelect('all')}>
                        全部
                    </Button>
                </div>
                <div className="space-y-2">
                    {renderSystemItem('all', '全部系统', totalAssets, totalActiveCount, totalManuals)}
                    {pagedSystems.map(system => renderSystemItem(
                        system.id,
                        system.name,
                        system.assetCount,
                        system.activeCount,
                        system.manualCount,
                        system.envTypes,
                    ))}
                </div>
                {systems.length > pageSize && (
                    <div className="mt-3 flex justify-center border-t border-slate-100 pt-3">
                        <Pagination
                            size="small"
                            simple
                            current={currentPage}
                            pageSize={pageSize}
                            total={systems.length}
                            onChange={setCurrentPage}
                        />
                    </div>
                )}
            </div>
        </aside>
    );
};

export default SystemSidebar;
