import React from 'react';
import { Modal } from 'antd';
import { QuartzTaskStatus } from '../mockData';

interface TaskInstanceRerunOptionModalProps {
    instance: QuartzTaskStatus | null;
    taskName: string;
    onClose: () => void;
    onExecuteCurrent: (instance: QuartzTaskStatus) => void;
    onOpenDependencyList: (instance: QuartzTaskStatus) => void;
}

const TaskInstanceRerunOptionModal: React.FC<TaskInstanceRerunOptionModalProps> = ({
    instance,
    taskName,
    onClose,
    onExecuteCurrent,
    onOpenDependencyList,
}) => (
    <Modal
        title="选择重跑方式"
        open={!!instance}
        onCancel={onClose}
        footer={null}
        destroyOnHidden
    >
        {instance && (
            <div className="space-y-4">
                <div className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3">
                    <div className="text-sm font-semibold text-slate-800">
                        {taskName || `任务 #${instance.plan_id}`}
                    </div>
                    <div className="mt-1 font-mono text-xs text-slate-500">
                        实例 #{instance.id} · 数据日期 {instance.data_date}
                    </div>
                </div>
                <div className="grid gap-3 md:grid-cols-2">
                    <button
                        type="button"
                        onClick={() => onExecuteCurrent(instance)}
                        className="rounded-xl border border-blue-200 bg-blue-50 px-4 py-4 text-left transition hover:bg-blue-100"
                    >
                        <div className="text-sm font-semibold text-blue-700">仅当前节点重跑</div>
                        <div className="mt-2 text-xs leading-5 text-blue-600">
                            只重置并触发当前实例，不自动沿依赖关系传播。
                        </div>
                    </button>
                    <button
                        type="button"
                        onClick={() => onOpenDependencyList(instance)}
                        className="rounded-xl border border-slate-200 bg-white px-4 py-4 text-left transition hover:border-blue-200 hover:bg-blue-50"
                    >
                        <div className="text-sm font-semibold text-slate-800">进入依赖列表</div>
                        <div className="mt-2 text-xs leading-5 text-slate-500">
                            单独打开执行页面，查看当前任务及需要一起重跑的影响任务。
                        </div>
                    </button>
                </div>
            </div>
        )}
    </Modal>
);

export default TaskInstanceRerunOptionModal;
