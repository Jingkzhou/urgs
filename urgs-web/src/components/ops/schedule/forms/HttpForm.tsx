import React from 'react';
import FormHeader from './components/FormHeader';
import BasicSettings from './components/BasicSettings';

interface HttpFormProps {
    formData: any;
    handleChange: (field: string, value: any) => void;
    isMaximized: boolean;
    toggleMaximize: () => void;
    availableTasks?: { label: string; value: string }[];
}

const HttpForm: React.FC<HttpFormProps> = ({ formData, handleChange, isMaximized, toggleMaximize, availableTasks = [] }) => {
    const [httpResources, setHttpResources] = React.useState<any[]>([]);

    React.useEffect(() => {
        const fetchResources = async () => {
            try {
                const token = localStorage.getItem('auth_token');
                const [metaList, configList] = await Promise.all([
                    fetch('/api/datasource/meta', {
                        headers: { 'Authorization': `Bearer ${token}` }
                    }).then(res => res.json()),
                    fetch('/api/datasource/config', {
                        headers: { 'Authorization': `Bearer ${token}` }
                    }).then(res => res.json())
                ]);

                const httpMeta = metaList.find((m: any) => m.code?.toUpperCase() === 'HTTP');
                if (httpMeta) {
                    const httpConfigs = configList.filter((c: any) => c.metaId === httpMeta.id);
                    setHttpResources(httpConfigs);
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
                type="HTTP"
                isMaximized={isMaximized}
                toggleMaximize={toggleMaximize}
            />

            <div className="flex-1 overflow-y-auto p-6 space-y-6">
                {/* Basic Settings */}
                <BasicSettings formData={formData} handleChange={handleChange} availableTasks={availableTasks} />

                {/* HTTP Specific Config */}
                <div className="space-y-4 pt-4 border-t border-slate-100">
                    <div className="space-y-4">
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>数据源
                            </label>
                            <select
                                value={formData.datasourceId || ''}
                                onChange={(e) => handleChange('datasourceId', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="">请选择数据源</option>
                                {httpResources.map(res => (
                                    <option key={res.id} value={res.id}>{res.name}</option>
                                ))}
                            </select>
                        </div>

                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>请求地址
                            </label>
                            <input
                                type="text"
                                value={formData.url || ''}
                                onChange={(e) => handleChange('url', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                placeholder="http(s)://..."
                            />
                        </div>

                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">请求类型</label>
                            <select
                                value={formData.httpMethod || 'GET'}
                                onChange={(e) => handleChange('httpMethod', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="GET">GET</option>
                                <option value="POST">POST</option>
                                <option value="HEAD">HEAD</option>
                                <option value="PUT">PUT</option>
                                <option value="DELETE">DELETE</option>
                            </select>
                        </div>

                        <div className="flex items-center gap-2">
                            <label className="w-24 text-xs font-medium text-slate-500">请求参数</label>
                            <button className="px-2 py-1 text-xs border border-teal-500 text-teal-600 rounded hover:bg-teal-50">添加</button>
                        </div>

                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">校验条件</label>
                            <select
                                value={formData.condition || 'STATUS_CODE_DEFAULT'}
                                onChange={(e) => handleChange('condition', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="STATUS_CODE_DEFAULT">默认响应码200</option>
                                <option value="STATUS_CODE_CUSTOM">自定义响应码</option>
                                <option value="BODY_CONTAINS">响应体包含</option>
                                <option value="BODY_NOT_CONTAINS">响应体不包含</option>
                            </select>
                        </div>

                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">校验内容</label>
                            <textarea
                                value={formData.conditionContent || ''}
                                onChange={(e) => handleChange('conditionContent', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 h-20 resize-none"
                                placeholder="请输入校验内容"
                            />
                        </div>

                        <div className="grid grid-cols-2 gap-6">
                            <div>
                                <label className="block text-xs font-medium text-slate-500 mb-1.5">连接超时(毫秒)</label>
                                <input
                                    type="number"
                                    value={formData.connectTimeout || 60000}
                                    onChange={(e) => handleChange('connectTimeout', parseInt(e.target.value))}
                                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-medium text-slate-500 mb-1.5">Socket超时(毫秒)</label>
                                <input
                                    type="number"
                                    value={formData.socketTimeout || 60000}
                                    onChange={(e) => handleChange('socketTimeout', parseInt(e.target.value))}
                                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                />
                            </div>
                        </div>
                    </div>
                </div>

                {/* Custom Params */}
                <div className="space-y-4 pt-4 border-t border-slate-100">
                    <div className="flex items-center gap-2">
                        <label className="w-24 text-xs font-medium text-slate-500">自定义参数</label>
                        <button className="px-2 py-1 text-xs border border-teal-500 text-teal-600 rounded hover:bg-teal-50">添加</button>
                    </div>
                </div>
            </div>


        </div>
    );
};

export default HttpForm;
