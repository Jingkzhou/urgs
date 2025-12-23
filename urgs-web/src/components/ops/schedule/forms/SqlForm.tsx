import React from 'react';
import { Settings, Database, Plus, Trash2 } from 'lucide-react';
import BasicSettings from './components/BasicSettings';
import FormHeader from './components/FormHeader';

interface SqlFormProps {
    formData: any;
    handleChange: (field: string, value: any) => void;
    handleParamChange: (index: number, key: string, value: string) => void;
    addParam: () => void;
    removeParam: (index: number) => void;
    isMaximized: boolean;
    toggleMaximize: () => void;
    availableTasks?: { label: string; value: string }[];
}

const SqlForm: React.FC<SqlFormProps> = ({
    formData, handleChange, handleParamChange, addParam, removeParam, isMaximized, toggleMaximize, availableTasks = []
}) => {
    return (
        <div className={`flex flex-col h-full bg-white transition-all duration-300 ${isMaximized ? 'fixed inset-0 z-50' : ''}`}>
            <FormHeader
                type="SQL"
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
                                    <span className="text-red-500 mr-1">*</span>数据源类型
                                </label>
                                <select
                                    value={formData.datasourceType || 'MYSQL'}
                                    onChange={(e) => handleChange('datasourceType', e.target.value)}
                                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                                >
                                    <option value="MYSQL">MYSQL</option>
                                    <option value="POSTGRESQL">POSTGRESQL</option>
                                    <option value="HIVE">HIVE</option>
                                    <option value="SPARK">SPARK</option>
                                </select>
                            </div>
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
                                    <option value="1">Local MySQL</option>
                                    <option value="2">Prod Hive</option>
                                </select>
                            </div>
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>SQL 语句
                            </label>
                            <div className="border border-slate-200 rounded-lg overflow-hidden">
                                <div className="bg-slate-50 px-3 py-1.5 border-b border-slate-200 flex items-center gap-2 text-xs text-slate-500">
                                    <Database size={12} />
                                    SQL Editor
                                </div>
                                <textarea
                                    value={formData.sql || ''}
                                    onChange={(e) => handleChange('sql', e.target.value)}
                                    className="w-full p-3 text-sm font-mono focus:outline-none h-48 resize-y"
                                    placeholder="SELECT * FROM table..."
                                />
                            </div>
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

export default SqlForm;
