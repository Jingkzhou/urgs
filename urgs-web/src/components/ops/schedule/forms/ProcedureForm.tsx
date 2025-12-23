import React from 'react';
import { Plus, Trash2 } from 'lucide-react';
import BasicSettings from './components/BasicSettings';
import FormHeader from './components/FormHeader';

interface ProcedureFormProps {
    formData: any;
    handleChange: (field: string, value: any) => void;
    handleParamChange: (index: number, key: string, value: string) => void;
    addParam: () => void;
    removeParam: (index: number) => void;
    isMaximized: boolean;
    toggleMaximize: () => void;
    availableTasks?: { label: string; value: string }[];
}

const ProcedureForm: React.FC<ProcedureFormProps> = ({
    formData, handleChange, handleParamChange, addParam, removeParam, isMaximized, toggleMaximize, availableTasks = []
}) => {
    const [dbResources, setDbResources] = React.useState<any[]>([]);

    React.useEffect(() => {
        const fetchResources = async () => {
            try {
                const token = localStorage.getItem('auth_token');
                const [metaRes, configRes] = await Promise.all([
                    fetch('/api/datasource/meta', {
                        headers: { 'Authorization': `Bearer ${token}` }
                    }).then(res => res.json()),
                    fetch('/api/datasource/config', {
                        headers: { 'Authorization': `Bearer ${token}` }
                    }).then(res => res.json())
                ]);

                // Filter for RDBMS types
                const targetTypes = ['MYSQL', 'POSTGRESQL', 'ORACLE', 'SQLSERVER', 'DB2'];
                const targetMetas = metaRes.filter((m: any) =>
                    targetTypes.includes(m.code?.toUpperCase())
                );

                if (targetMetas.length > 0) {
                    const targetMetaIds = targetMetas.map((m: any) => m.id);
                    const dbConfigs = configRes.filter((c: any) => targetMetaIds.includes(c.metaId));
                    setDbResources(dbConfigs);
                }
            } catch (error) {
                console.error('Failed to fetch resources:', error);
            }
        };

        fetchResources();
    }, []);

    return (
        <div className={`flex flex-col h-full bg-white transition-all duration-300 ${isMaximized ? 'fixed inset-0 z-50' : ''}`}>
            <FormHeader
                type="PROCEDURE"
                isMaximized={isMaximized}
                toggleMaximize={toggleMaximize}
            />

            <div className="flex-1 overflow-y-auto p-6 space-y-8">
                {/* 1. Basic Settings */}
                <section className="space-y-4">
                    <div className="flex items-center gap-2 text-sm font-bold text-slate-800 pb-2 border-b border-slate-100">
                        <div className="w-1 h-4 bg-blue-600 rounded-full"></div>
                        基础设置
                    </div>
                    <BasicSettings formData={formData} handleChange={handleChange} availableTasks={availableTasks} />
                </section>

                {/* 2. Task Specific Settings */}
                <section className="space-y-4">
                    <div className="flex items-center gap-2 text-sm font-bold text-slate-800 pb-2 border-b border-slate-100">
                        <div className="w-1 h-4 bg-green-600 rounded-full"></div>
                        任务参数
                    </div>

                    <div className="space-y-4">
                        <div className="grid grid-cols-2 gap-6">

                            <div>
                                <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                    <span className="text-red-500 mr-1">*</span>数据源实例
                                </label>
                                <select
                                    value={formData.datasourceId || ''}
                                    onChange={(e) => handleChange('datasourceId', e.target.value)}
                                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                                >
                                    <option value="">请选择数据源</option>
                                    {dbResources.map(res => (
                                        <option key={res.id} value={res.id}>{res.name}</option>
                                    ))}
                                </select>
                            </div>
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>方法
                            </label>
                            <input
                                type="text"
                                value={formData.method || ''}
                                onChange={(e) => handleChange('method', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                placeholder="请输入存储过程名称, 如: pkg_test.proc_demo"
                            />
                        </div>
                    </div>
                </section>

                {/* 3. Custom Params */}
                <section className="space-y-4">
                    <div className="flex items-center justify-between text-sm font-bold text-slate-800 pb-2 border-b border-slate-100">
                        <div className="flex items-center gap-2">
                            <div className="w-1 h-4 bg-purple-600 rounded-full"></div>
                            自定义参数
                        </div>
                        <button
                            onClick={addParam}
                            className="p-1 text-blue-600 hover:bg-blue-50 rounded transition-colors"
                            title="添加参数"
                        >
                            <Plus size={16} />
                        </button>
                    </div>

                    <div className="space-y-2">
                        {(!formData.localParams || formData.localParams.length === 0) && (
                            <div className="text-center py-4 text-slate-400 text-xs italic">
                                暂无自定义参数
                            </div>
                        )}
                        {formData.localParams?.map((param: any, idx: number) => (
                            <div key={idx} className="flex items-center gap-2">
                                <input
                                    type="text"
                                    value={param.prop}
                                    onChange={(e) => handleParamChange(idx, 'prop', e.target.value)}
                                    placeholder="prop"
                                    className="flex-1 px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                />
                                <select
                                    value={param.direct || 'IN'}
                                    onChange={(e) => handleParamChange(idx, 'direct', e.target.value)}
                                    className="w-24 px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                                >
                                    <option value="IN">IN</option>
                                    <option value="OUT">OUT</option>
                                    <option value="INOUT">INOUT</option>
                                </select>
                                <select
                                    value={param.type || 'VARCHAR'}
                                    onChange={(e) => handleParamChange(idx, 'type', e.target.value)}
                                    className="w-28 px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                                >
                                    <option value="VARCHAR">VARCHAR</option>
                                    <option value="INTEGER">INTEGER</option>
                                    <option value="LONG">LONG</option>
                                    <option value="FLOAT">FLOAT</option>
                                    <option value="DOUBLE">DOUBLE</option>
                                    <option value="DATE">DATE</option>
                                    <option value="TIME">TIME</option>
                                    <option value="TIMESTAMP">TIMESTAMP</option>
                                    <option value="BOOLEAN">BOOLEAN</option>
                                </select>
                                <input
                                    type="text"
                                    value={param.value}
                                    onChange={(e) => handleParamChange(idx, 'value', e.target.value)}
                                    placeholder="value"
                                    className="flex-1 px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                />
                                <button
                                    onClick={() => removeParam(idx)}
                                    className="p-2 text-slate-400 hover:text-red-600 transition-colors"
                                >
                                    <Trash2 size={16} />
                                </button>
                            </div>
                        ))}
                    </div>
                </section>
            </div>
        </div>
    );
};

export default ProcedureForm;
