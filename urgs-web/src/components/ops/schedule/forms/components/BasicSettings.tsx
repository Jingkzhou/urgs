import React from 'react';
import { Select } from 'antd';
import CronPicker from './CronPicker';

interface BasicSettingsProps {
    formData: any;
    handleChange: (field: string, value: any) => void;
    availableTasks?: { label: string; value: string }[];
}

const BasicSettings: React.FC<BasicSettingsProps> = ({ formData, handleChange, availableTasks = [] }) => {
    return (
        <div className="space-y-4">
            {/* Row 1: Node Name */}
            <div>
                <label className="block text-xs font-medium text-slate-500 mb-1.5">
                    <span className="text-red-500 mr-1">*</span>节点名称
                </label>
                <input
                    type="text"
                    value={formData.label || ''}
                    onChange={(e) => handleChange('label', e.target.value)}
                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                    placeholder="请输入名称(必填)"
                />
            </div>

            {/* Row 2: Timeout Alarm & Run Flag */}
            <div className="grid grid-cols-2 gap-6 items-center">
                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">超时告警</label>
                    <div className="flex items-center gap-2">
                        <div
                            className={`w-8 h-4 rounded-full p-0.5 cursor-pointer transition-colors ${formData.timeoutFlag ? 'bg-blue-600' : 'bg-slate-300'}`}
                            onClick={() => handleChange('timeoutFlag', !formData.timeoutFlag)}
                        >
                            <div className={`w-3 h-3 bg-white rounded-full shadow-sm transform transition-transform ${formData.timeoutFlag ? 'translate-x-4' : 'translate-x-0'}`} />
                        </div>
                        {formData.timeoutFlag && (
                            <div className="flex items-center gap-1 text-xs text-slate-400">
                                <span className="text-slate-300">——</span>
                                <span>表通报送</span>
                            </div>
                        )}
                    </div>
                </div>
                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">运行标志</label>
                    <div className="flex items-center gap-4">
                        <label className="flex items-center gap-2 cursor-pointer">
                            <input
                                type="radio"
                                name="runFlag"
                                checked={formData.runFlag !== 'FORBIDDEN'}
                                onChange={() => handleChange('runFlag', 'NORMAL')}
                                className="w-4 h-4 text-teal-600 border-slate-300 focus:ring-teal-500"
                            />
                            <span className="text-xs text-teal-600 font-medium">正常</span>
                        </label>
                        <label className="flex items-center gap-2 cursor-pointer">
                            <input
                                type="radio"
                                name="runFlag"
                                checked={formData.runFlag === 'FORBIDDEN'}
                                onChange={() => handleChange('runFlag', 'FORBIDDEN')}
                                className="w-4 h-4 text-slate-400 border-slate-300 focus:ring-slate-500"
                            />
                            <span className="text-xs text-slate-500">禁止运行</span>
                        </label>
                    </div>
                </div>
            </div>

            {/* Row 3: Description */}
            <div>
                <label className="block text-xs font-medium text-slate-500 mb-1.5">描述</label>
                <div className="relative">
                    <textarea
                        value={formData.description || ''}
                        onChange={(e) => handleChange('description', e.target.value)}
                        className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all resize-none h-20"
                        placeholder="请输入描述"
                        maxLength={255}
                    />
                    <span className="absolute bottom-2 right-2 text-xs text-slate-400">
                        {formData.description?.length || 0}/255
                    </span>
                </div>
            </div>

            {/* Row 5: Schedule Strategy */}
            <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 space-y-4">
                <div className="flex items-center justify-between">
                    <label className="text-sm font-bold text-slate-700">调度策略</label>
                </div>

                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">依赖任务</label>
                    <Select
                        mode="multiple"
                        allowClear
                        style={{ width: '100%' }}
                        placeholder="请选择依赖任务"
                        value={formData.dependentTasks || []}
                        onChange={(value) => handleChange('dependentTasks', value)}
                        options={availableTasks}
                    />
                    <p className="mt-1 text-[10px] text-slate-400">
                        * 任务将在所有选中的前置任务执行成功后触发
                    </p>
                </div>

                <div className="border-t border-slate-200 pt-4">
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">
                        <span className="text-red-500 mr-1">*</span>Cron 表达式
                    </label>
                    <CronPicker
                        value={formData.cronExpression || '0 0 * * * ?'}
                        onChange={(value) => handleChange('cronExpression', value)}
                        offset={formData.offset || 0}
                        onOffsetChange={(val) => handleChange('offset', val)}
                    />
                </div>
            </div>

            {/* Row 7: Intra-group Priority & Retry Times */}
            <div className="grid grid-cols-2 gap-6">
                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">失败重试次数</label>
                    <input
                        type="number"
                        value={formData.retryTimes || 0}
                        onChange={(e) => handleChange('retryTimes', parseInt(e.target.value))}
                        className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                        min="0"
                    />
                </div>
                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">失败重试间隔(分)</label>
                    <input
                        type="number"
                        value={formData.retryInterval || 1}
                        onChange={(e) => handleChange('retryInterval', parseInt(e.target.value))}
                        className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                        min="1"
                    />
                </div>
            </div>

            {/* Row 8: Notification Settings */}
            <div className="grid grid-cols-2 gap-6">
                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">成功时通知</label>
                    <Select
                        mode="multiple"
                        allowClear
                        style={{ width: '100%' }}
                        placeholder="请选择通知人员"
                        value={formData.notifySuccess || []}
                        onChange={(value) => handleChange('notifySuccess', value)}
                        options={[
                            { label: 'User A', value: 'user_a' },
                            { label: 'User B', value: 'user_b' },
                            { label: 'User C', value: 'user_c' },
                        ]}
                    />
                </div>
                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">失败时通知</label>
                    <Select
                        mode="multiple"
                        allowClear
                        style={{ width: '100%' }}
                        placeholder="请选择通知人员"
                        value={formData.notifyFailure || []}
                        onChange={(value) => handleChange('notifyFailure', value)}
                        options={[
                            { label: 'User A', value: 'user_a' },
                            { label: 'User B', value: 'user_b' },
                            { label: 'User C', value: 'user_c' },
                        ]}
                    />
                </div>
            </div>
        </div>
    );
};

export default BasicSettings;
