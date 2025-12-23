import React, { useState, useEffect } from 'react';
import { Terminal, Plus, Trash2 } from 'lucide-react';
import BasicSettings from './components/BasicSettings';
import FormHeader from './components/FormHeader';

interface ScriptFormProps {
    formData: any;
    type: string;
    handleChange: (field: string, value: any) => void;
    handleParamChange: (index: number, key: string, value: string) => void;
    addParam: () => void;
    removeParam: (index: number) => void;
    isMaximized: boolean;
    toggleMaximize: () => void;
    availableTasks?: { label: string; value: string }[];
}

const ScriptForm: React.FC<ScriptFormProps> = ({
    formData, type, handleChange, handleParamChange, addParam, removeParam, isMaximized, toggleMaximize, availableTasks = []
}) => {
    const [sshResources, setSshResources] = useState<any[]>([]);

    useEffect(() => {
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

                const sshMeta = metaRes.find((m: any) => m.code === 'ssh');
                if (sshMeta) {
                    const sshConfigs = configRes.filter((c: any) => c.metaId === sshMeta.id);
                    setSshResources(sshConfigs);
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
                type={type}
                isMaximized={isMaximized}
                toggleMaximize={toggleMaximize}
            />

            <div className="flex-1 overflow-y-auto p-6 space-y-6">
                {/* Basic Settings */}
                <BasicSettings formData={formData} handleChange={handleChange} availableTasks={availableTasks} />

                {/* Script Content */}
                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">
                        <span className="text-red-500 mr-1">*</span>脚本
                    </label>
                    <div className={`flex border border-slate-200 rounded-lg overflow-hidden ${isMaximized ? 'h-[600px]' : 'h-64'} transition-all duration-300`}>
                        <div className="w-10 bg-slate-50 border-r border-slate-200 flex flex-col items-center py-2 text-xs text-slate-400 select-none">
                            <div>1</div>
                        </div>
                        <textarea
                            value={formData.rawScript || ''}
                            onChange={(e) => handleChange('rawScript', e.target.value)}
                            className="flex-1 p-3 text-sm font-mono focus:outline-none resize-none"
                            placeholder={type === 'SHELL' ? '#!/bin/bash\necho "Hello"' : 'import os\nprint("Hello")'}
                        />
                    </div>
                </div>

                {/* Resources */}
                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">资源</label>
                    <select
                        value={formData.resource || ''}
                        onChange={(e) => handleChange('resource', e.target.value)}
                        className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                    >
                        <option value="">请选择资源</option>
                        {sshResources.map(res => (
                            <option key={res.id} value={res.id}>{res.name}</option>
                        ))}
                    </select>
                </div>

                {/* Custom Params */}
                <div className="space-y-4">
                    <div className="flex items-center gap-2">
                        <label className="w-24 text-xs font-medium text-slate-500">自定义参数</label>
                        <button
                            onClick={addParam}
                            className="px-2 py-1 text-xs border border-teal-500 text-teal-600 rounded hover:bg-teal-50 transition-colors"
                        >
                            添加
                        </button>
                    </div>

                    <div className="space-y-2">
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
                </div>
            </div>
        </div>
    );
};

export default ScriptForm;
