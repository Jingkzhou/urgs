import React from 'react';
import { Database, HardDrive, Settings, Plus, Trash2 } from 'lucide-react';
import FormHeader from './components/FormHeader';
import BasicSettings from './components/BasicSettings';
import { DataXFieldRenderer } from './components/DataXFieldRenderer';

interface DataXFormProps {
    formData: any;
    handleChange: (field: string | Record<string, any>, value?: any) => void;
    isMaximized: boolean;
    toggleMaximize: () => void;
    availableTasks?: { label: string; value: string }[];
}

const DataXForm: React.FC<DataXFormProps> = ({ formData, handleChange, isMaximized, toggleMaximize, availableTasks = [] }) => {
    const [metaList, setMetaList] = React.useState<any[]>([]);
    const [configList, setConfigList] = React.useState<any[]>([]);

    React.useEffect(() => {
        const fetchData = async () => {
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
                setMetaList(metaRes);
                setConfigList(configRes);
            } catch (error) {
                console.error('Failed to fetch datasource info:', error);
            }
        };
        fetchData();
    }, []);

    const getDataSourceOptions = (type: string) => {
        if (!type) return [];
        const meta = metaList.find(m => m.code?.toUpperCase() === type);
        if (!meta) return [];
        return configList.filter(c => c.metaId === meta.id);
    };

    const sourceOptions = React.useMemo(() => getDataSourceOptions(formData.sourceType), [formData.sourceType, metaList, configList]);
    const targetOptions = React.useMemo(() => getDataSourceOptions(formData.targetType), [formData.targetType, metaList, configList]);

    return (
        <div className={`flex flex-col h-full bg-white transition-all duration-300 ${isMaximized ? 'fixed inset-0 z-50' : ''}`}>
            <FormHeader
                type="DataX"
                isMaximized={isMaximized}
                toggleMaximize={toggleMaximize}
            />

            <div className="flex-1 overflow-y-auto p-6 space-y-8">
                {/* 1. Basic Settings */}
                <section className="space-y-4">
                    <div className="flex items-center gap-2 text-sm font-bold text-slate-800 pb-2 border-b border-slate-100">
                        <div className="w-1 h-4 bg-slate-600 rounded-full"></div>
                        基础设置
                    </div>
                    <BasicSettings formData={formData} handleChange={handleChange} availableTasks={availableTasks} />
                </section>

                {/* 2. Reader Config (Source) */}
                <section className="space-y-4">
                    <div className="flex items-center gap-2 text-sm font-bold text-slate-800 pb-2 border-b border-slate-100">
                        <div className="w-1 h-4 bg-blue-600 rounded-full"></div>
                        <span className="flex items-center gap-2">
                            <Database size={16} className="text-blue-600" />
                            Reader 设置 (数据来源)
                        </span>
                    </div>

                    <div className="grid grid-cols-2 gap-6">
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>数据源类型
                            </label>
                            <select
                                value={formData.sourceType || ''}
                                onChange={(e) => {
                                    handleChange({
                                        sourceType: e.target.value,
                                        sourceId: '' // Reset instance when type changes
                                    });
                                }}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="">请选择</option>
                                {metaList.map(meta => (
                                    <option key={meta.id} value={meta.code?.toUpperCase()}>{meta.name || meta.code}</option>
                                ))}
                            </select>
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>数据源实例
                            </label>
                            <select
                                value={formData.sourceId || ''}
                                onChange={(e) => handleChange('sourceId', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="">请选择</option>
                                {sourceOptions.map(opt => (
                                    <option key={opt.id} value={opt.id}>{opt.name}</option>
                                ))}
                            </select>
                        </div>
                        <div className="col-span-2">
                            <DataXFieldRenderer
                                mode="reader"
                                dataSourceType={formData.sourceType}
                                formData={formData}
                                handleChange={handleChange}
                            />
                        </div>
                    </div>
                </section>

                {/* 3. Writer Config (Target) */}
                <section className="space-y-4">
                    <div className="flex items-center gap-2 text-sm font-bold text-slate-800 pb-2 border-b border-slate-100">
                        <div className="w-1 h-4 bg-green-600 rounded-full"></div>
                        <span className="flex items-center gap-2">
                            <HardDrive size={16} className="text-green-600" />
                            Writer 设置 (数据去向)
                        </span>
                    </div>

                    <div className="grid grid-cols-3 gap-6">
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>数据源类型
                            </label>
                            <select
                                value={formData.targetType || ''}
                                onChange={(e) => {
                                    handleChange({
                                        targetType: e.target.value,
                                        targetId: '' // Reset instance when type changes
                                    });
                                }}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="">请选择</option>
                                {metaList.map(meta => (
                                    <option key={meta.id} value={meta.code?.toUpperCase()}>{meta.name || meta.code}</option>
                                ))}
                            </select>
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>数据源实例
                            </label>
                            <select
                                value={formData.targetId || ''}
                                onChange={(e) => handleChange('targetId', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="">请选择</option>
                                {targetOptions.map(opt => (
                                    <option key={opt.id} value={opt.id}>{opt.name}</option>
                                ))}
                            </select>
                        </div>
                        <div className="col-span-2">
                            <DataXFieldRenderer
                                mode="writer"
                                dataSourceType={formData.targetType}
                                formData={formData}
                                handleChange={handleChange}
                            />
                        </div>
                    </div>


                </section>

                {/* 4. System Config */}
                <section className="space-y-4">
                    <div className="flex items-center gap-2 text-sm font-bold text-slate-800 pb-2 border-b border-slate-100">
                        <div className="w-1 h-4 bg-purple-600 rounded-full"></div>
                        <span className="flex items-center gap-2">
                            <Settings size={16} className="text-purple-600" />
                            系统参数
                        </span>
                    </div>

                    <div className="grid grid-cols-4 gap-6">
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">CPU配额(%)</label>
                            <input
                                type="number"
                                value={formData.cpuQuota || -1}
                                onChange={(e) => handleChange('cpuQuota', parseInt(e.target.value))}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                            />
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">最大内存(MB)</label>
                            <input
                                type="number"
                                value={formData.maxMemoryMB || -1}
                                onChange={(e) => handleChange('maxMemoryMB', parseInt(e.target.value))}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                            />
                        </div>
                        <div className="col-span-2 flex items-center gap-2 pt-6">
                            <label className="text-xs font-medium text-slate-500">自定义模板</label>
                            <div
                                className={`w-8 h-4 rounded-full p-0.5 cursor-pointer transition-colors ${formData.customTemplate ? 'bg-blue-600' : 'bg-slate-300'}`}
                                onClick={() => handleChange('customTemplate', !formData.customTemplate)}
                            >
                                <div className={`w-3 h-3 bg-white rounded-full shadow-sm transform transition-transform ${formData.customTemplate ? 'translate-x-4' : 'translate-x-0'}`} />
                            </div>
                        </div>
                    </div>

                    <div className="grid grid-cols-4 gap-6">
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">限流(字节数)</label>
                            <select
                                value={formData.byteLimit || 0}
                                onChange={(e) => handleChange('byteLimit', parseInt(e.target.value))}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value={0}>0(不限制)</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">限流(记录数)</label>
                            <select
                                value={formData.recordLimit || 1000}
                                onChange={(e) => handleChange('recordLimit', parseInt(e.target.value))}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value={1000}>1000</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">最小内存</label>
                            <select
                                value={formData.minMemory || '1G'}
                                onChange={(e) => handleChange('minMemory', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="1G">1G</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">最大内存</label>
                            <select
                                value={formData.maxMemory || '1G'}
                                onChange={(e) => handleChange('maxMemory', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="1G">1G</option>
                            </select>
                        </div>
                    </div>
                </section>

                {/* 5. Custom Params */}
                <section className="space-y-4">
                    <div className="flex items-center justify-between text-sm font-bold text-slate-800 pb-2 border-b border-slate-100">
                        <div className="flex items-center gap-2">
                            <div className="w-1 h-4 bg-orange-500 rounded-full"></div>
                            自定义参数
                        </div>
                        <button className="p-1 text-blue-600 hover:bg-blue-50 rounded transition-colors" title="添加参数">
                            <Plus size={16} />
                        </button>
                    </div>
                    <div className="text-center py-4 text-slate-400 text-xs italic">
                        暂无自定义参数
                    </div>
                </section>
            </div>
        </div>
    );
};

export default DataXForm;
