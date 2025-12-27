import React, { useEffect, useState } from 'react';
import { Server } from 'lucide-react';
import PageHeader from '../common/PageHeader';
import StatusTag from '../common/StatusTag';
import StateBlock from '../common/StateBlock';

type SsoSystem = {
    id: string;
    name: string;
    status?: string;
    owner?: string;
    url?: string;
};

import AppSystemDetail from './AppSystemDetail';

const AppSystemList: React.FC = () => {
    const [systems, setSystems] = useState<SsoSystem[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [selectedSystem, setSelectedSystem] = useState<SsoSystem | null>(null);

    const loadSystems = async () => {
        setLoading(true);
        setError(null);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/system', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.status === 401) {
                setError('未登录或登录已过期');
                return;
            }
            if (!res.ok) {
                throw new Error(`加载系统列表失败: ${res.status}`);
            }
            const data = await res.json();
            setSystems(Array.isArray(data) ? data : []);
        } catch (err: any) {
            setError(err.message || '加载失败');
            setSystems([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadSystems();
    }, []);

    return (
        <div className="space-y-4">
            <PageHeader
                title="应用系统库"
                icon={Server}
                extra={
                    <button onClick={loadSystems} className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
                        刷新
                    </button>
                }
            />

            {error ? (
                <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-3 py-2 rounded">
                    {error}
                </div>
            ) : null}

            {loading ? (
                <StateBlock type="loading" message="正在加载监管系统..." height="300px" />
            ) : systems.length === 0 ? (
                <StateBlock type="empty" message="暂无监管系统数据" height="300px" />
            ) : (
                <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {systems.map(sys => (
                        <div
                            key={sys.id}
                            onClick={() => setSelectedSystem(sys)}
                            className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm hover:shadow-md transition-all cursor-pointer group"
                        >
                            <div className="flex items-center justify-between mb-2">
                                <h3 className="text-sm font-semibold text-slate-800 truncate group-hover:text-blue-600 transition-colors">{sys.name}</h3>
                                {sys.status && <StatusTag status={sys.status} />}
                            </div>
                            {sys.owner && <p className="text-xs text-slate-500 mb-1">责任人：{sys.owner}</p>}
                            {sys.url && (
                                <a href={sys.url} target="_blank" rel="noreferrer" onClick={e => e.stopPropagation()} className="text-xs text-blue-600 hover:underline">
                                    {sys.url}
                                </a>
                            )}
                        </div>
                    ))}
                </div>
            )}

            {selectedSystem && (
                <AppSystemDetail system={selectedSystem} onClose={() => setSelectedSystem(null)} />
            )}
        </div>
    );
};

export default AppSystemList;
