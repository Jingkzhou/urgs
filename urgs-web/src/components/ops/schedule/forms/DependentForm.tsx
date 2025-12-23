import React, { useState, useEffect } from 'react';
import { Select, Input, Switch } from 'antd';
import FormHeader from './components/FormHeader';

interface DependentFormProps {
    formData: any;
    handleChange: (field: string, value: any) => void;
    isMaximized: boolean;
    toggleMaximize: () => void;
}

const DependentForm: React.FC<DependentFormProps> = ({
    formData,
    handleChange,
    isMaximized,
    toggleMaximize
}) => {
    const [workflows, setWorkflows] = useState<any[]>([]);
    const [tasks, setTasks] = useState<any[]>([]);

    useEffect(() => {
        fetchWorkflows();
    }, []);

    useEffect(() => {
        if (formData.workflowId && workflows.length > 0) {
            // Use String comparison to handle potential type mismatches
            const selectedWorkflow = workflows.find(w => String(w.id) === String(formData.workflowId));

            if (selectedWorkflow && selectedWorkflow.content) {
                try {
                    // content might be a JSON string or already an object
                    const content = typeof selectedWorkflow.content === 'string'
                        ? JSON.parse(selectedWorkflow.content)
                        : selectedWorkflow.content;

                    if (content && content.nodes && Array.isArray(content.nodes)) {
                        const workflowTasks = content.nodes.map((node: any) => ({
                            label: node.data?.label || node.data?.name || node.id,
                            value: node.data?.id || node.id
                        }));
                        setTasks(workflowTasks);
                    } else {
                        console.warn('Workflow content has no nodes:', selectedWorkflow);
                        setTasks([]);
                    }
                } catch (e) {
                    console.error('Failed to parse workflow content', e);
                    setTasks([]);
                }
            } else {
                console.warn('Selected workflow not found or has no content', formData.workflowId);
                setTasks([]);
            }
        } else {
            setTasks([]);
        }
    }, [formData.workflowId, workflows]);

    const fetchWorkflows = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/workflow/list', {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            if (res.ok) {
                const data = await res.json();
                // Map backend data to frontend format
                const mapped = data.map((w: any) => ({
                    ...w,
                    // Use realId for value if available, or id if it's the numeric ID
                    value: w.id,
                    label: w.name
                }));
                setWorkflows(mapped);
            }
        } catch (error) {
            console.error('Failed to fetch workflows:', error);
        }
    };
    return (
        <div className={`flex flex-col h-full bg-white ${isMaximized ? 'fixed inset-0 z-50' : ''}`}>
            <FormHeader
                type="DEPENDENT"
                isMaximized={isMaximized}
                toggleMaximize={toggleMaximize}
            />

            <div className="flex-1 overflow-y-auto p-6">
                <div className="space-y-6 max-w-4xl mx-auto">
                    {/* Basic Info */}
                    <div className="bg-slate-50 p-4 rounded-lg border border-slate-200">
                        <h3 className="text-sm font-bold text-slate-700 mb-4 uppercase tracking-wider">基础信息</h3>
                        <div className="grid grid-cols-1 gap-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">节点名称</label>
                                <Input
                                    value={formData.label}
                                    onChange={(e) => handleChange('label', e.target.value)}
                                    placeholder="请输入节点名称"
                                    className="w-full"
                                />
                            </div>
                        </div>
                    </div>

                    {/* Dependency Config */}
                    <div className="bg-slate-50 p-4 rounded-lg border border-slate-200">
                        <h3 className="text-sm font-bold text-slate-700 mb-4 uppercase tracking-wider">依赖配置</h3>
                        <div className="grid grid-cols-1 gap-4">

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">依赖工作流</label>
                                <Select
                                    value={formData.workflowId}
                                    onChange={(val) => {
                                        // Use batch update to prevent race conditions
                                        // @ts-ignore - TaskConfigForm supports object for batch update
                                        handleChange({ workflowId: val, taskId: undefined });
                                    }}
                                    className="w-full"
                                    placeholder="请选择工作流"
                                    showSearch
                                    filterOption={(input, option) =>
                                        (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                                    }
                                    options={workflows.map(w => ({ label: w.name, value: w.id }))}
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">依赖任务</label>
                                <Select
                                    value={formData.taskId}
                                    onChange={(val) => handleChange('taskId', val)}
                                    className="w-full"
                                    placeholder="请选择任务 (可选，默认依赖整个工作流)"
                                    allowClear
                                    showSearch
                                    filterOption={(input, option) =>
                                        (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                                    }
                                    options={tasks}
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default DependentForm;
