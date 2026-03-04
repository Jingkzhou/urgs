import React from 'react';
import { useForm, useFieldArray, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { X, Plus, Trash2 } from 'lucide-react';
import { createWork } from '../../api/marketplace';
import UserSelect from './UserSelect';

const taskSchema = z.object({
    title: z.string().min(2, '任务标题至少2个字符'),
    description: z.string().min(10, '任务描述至少10个字符'),
    points: z.number().min(0, '积分不能为负数'),
    requiredSkills: z.string().optional().or(z.literal('')),
    assignMode: z.enum(['OPEN', 'ASSIGN', 'COMPETE']),
    assigneeId: z.string().optional().or(z.literal('')),
    maxApplicants: z.number().optional().or(z.literal('')),
    deadline: z.string().optional().or(z.literal('')).refine((val) => !val || new Date(val) > new Date(), {
        message: '截止日期必须在将来',
    }),
});

const workSchema = z.object({
    title: z.string().min(2, '工作标题至少2个字符'),
    description: z.string().min(10, '工作描述至少10个字符'),
    category: z.string().min(2, '请输入分类'),
    priority: z.enum(['P0', 'P1', 'P2', 'P3', 'P4']),
    deadline: z.string().optional().or(z.literal('')).refine((val) => !val || new Date(val) > new Date(), {
        message: '截止日期必须在将来',
    }),
    tasks: z.array(taskSchema).min(1, '至少需要添加一个工作任务'),
});

type WorkFormValues = z.infer<typeof workSchema>;

interface CreateWorkDrawerProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
}

const CreateWorkDrawer: React.FC<CreateWorkDrawerProps> = ({ isOpen, onClose, onSuccess }) => {
    const {
        register,
        control,
        handleSubmit,
        watch,
        reset,
        formState: { errors, isSubmitting }
    } = useForm<WorkFormValues>({
        resolver: zodResolver(workSchema),
        defaultValues: {
            priority: 'P2',
            tasks: [{ assignMode: 'OPEN', points: 10 }]
        }
    });

    const { fields, append, remove } = useFieldArray({
        control,
        name: "tasks"
    });

    // Close drawer on escape key
    React.useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === 'Escape') onClose();
        };
        if (isOpen) window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [isOpen, onClose]);

    if (!isOpen) return null;

    const onSubmit = async (data: WorkFormValues) => {
        try {
            const payload = {
                ...data,
                deadline: data.deadline || undefined,
                tasks: data.tasks.map(t => ({
                    ...t,
                    requiredSkills: t.requiredSkills || undefined,
                    assigneeId: t.assigneeId || undefined,
                    maxApplicants: t.maxApplicants === '' ? undefined : t.maxApplicants,
                    deadline: t.deadline || undefined,
                }))
            };
            await createWork(payload as any);
            reset();
            onSuccess();
        } catch (error) {
            console.error('Create work failed:', error);
            alert('创建工作失败，请重试');
        }
    };

    const onError = (errors: any) => {
        console.log('Form validation failed:', errors);
    };

    return (
        <>
            {/* Backdrop */}
            <div
                className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-40 transition-opacity"
                onClick={onClose}
            />

            {/* Drawer */}
            <div className={`fixed inset-y-0 right-0 w-full max-w-2xl bg-white shadow-2xl z-50 transform transition-transform duration-300 ease-in-out flex flex-col ${isOpen ? 'translate-x-0' : 'translate-x-full'}`}>
                <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-white">
                    <div>
                        <h2 className="text-xl font-bold text-slate-800">发布新工作</h2>
                        <p className="text-sm text-slate-500 mt-1">创建一个包含多个子任务的工作集市包</p>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-full transition-colors"
                    >
                        <X size={20} />
                    </button>
                </div>

                <div className="flex-1 overflow-y-auto p-6 bg-slate-50/50">
                    <form id="create-work-form" onSubmit={handleSubmit(onSubmit, onError)} className="space-y-8">
                        {/* 基础信息 */}
                        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4">
                            <h3 className="text-base font-bold text-slate-800 border-b border-slate-100 pb-2 mb-4">基础信息</h3>

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">
                                    工作标题 <span className="text-red-500">*</span>
                                </label>
                                <input
                                    {...register("title")}
                                    className="w-full px-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none transition-all"
                                    placeholder="例如：2026 Q1 前端性能优化专项"
                                />
                                {errors.title && <p className="text-red-500 text-xs mt-1">{errors.title.message}</p>}
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">
                                        分类目录 <span className="text-red-500">*</span>
                                    </label>
                                    <input
                                        {...register("category")}
                                        className="w-full px-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none transition-all"
                                        placeholder="如：研发、设计、市场"
                                    />
                                    {errors.category && <p className="text-red-500 text-xs mt-1">{errors.category.message}</p>}
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">
                                        优先级 <span className="text-red-500">*</span>
                                    </label>
                                    <select
                                        {...register("priority")}
                                        className="w-full px-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none transition-all bg-white"
                                    >
                                        <option value="P0">P0 (最高/紧急)</option>
                                        <option value="P1">P1 (高/重要)</option>
                                        <option value="P2">P2 (中等/常规)</option>
                                        <option value="P3">P3 (低/计划内)</option>
                                    </select>
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">
                                    详细描述 <span className="text-red-500">*</span>
                                </label>
                                <textarea
                                    {...register("description")}
                                    rows={3}
                                    className="w-full px-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none transition-all resize-none"
                                    placeholder="详细描述该工作的大致背景与目标..."
                                />
                                {errors.description && <p className="text-red-500 text-xs mt-1">{errors.description.message}</p>}
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">
                                    总截止日期 <span className="text-slate-400 text-xs font-normal">(可选)</span>
                                </label>
                                <input
                                    type="datetime-local"
                                    {...register("deadline")}
                                    className="w-full px-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none transition-all"
                                />
                                {errors.deadline && <p className="text-red-500 text-xs mt-1">{errors.deadline.message}</p>}
                            </div>
                        </div>

                        {/* 任务拆分 */}
                        <div className="space-y-4">
                            <div className="flex items-center justify-between">
                                <h3 className="text-base font-bold text-slate-800">任务拆分 <span className="text-red-500">*</span></h3>
                                <button
                                    type="button"
                                    onClick={() => append({ title: '', description: '', points: 5, assignMode: 'OPEN', deadline: '' })}
                                    className="flex items-center gap-1.5 text-sm font-medium text-red-600 hover:text-red-700 hover:bg-red-50 px-3 py-1.5 rounded-md transition-colors"
                                >
                                    <Plus size={16} /> 添加任务
                                </button>
                            </div>

                            {errors.tasks?.message && <p className="text-red-500 text-sm font-medium">{errors.tasks.message}</p>}

                            {fields.map((field, index) => {
                                const assignMode = watch(`tasks.${index}.assignMode`);

                                return (
                                    <div key={field.id} className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm relative group overflow-hidden">
                                        <div className="absolute top-0 left-0 w-1 h-full bg-slate-200 group-hover:bg-red-400 transition-colors" />

                                        <div className="flex justify-between items-start mb-4">
                                            <h4 className="text-sm font-bold text-slate-700 flex items-center gap-2">
                                                <span className="bg-slate-100 text-slate-500 w-6 h-6 rounded-full flex items-center justify-center text-xs">
                                                    {index + 1}
                                                </span>
                                                子任务细节
                                            </h4>
                                            {fields.length > 1 && (
                                                <button
                                                    type="button"
                                                    onClick={() => remove(index)}
                                                    className="text-slate-400 hover:text-red-500 transition-colors p-1 rounded-md hover:bg-red-50"
                                                >
                                                    <Trash2 size={16} />
                                                </button>
                                            )}
                                        </div>

                                        <div className="space-y-4 pl-2">
                                            <div>
                                                <input
                                                    {...register(`tasks.${index}.title` as const)}
                                                    className="w-full px-3 py-1.5 border-b border-slate-200 focus:border-red-500 outline-none transition-colors font-medium text-slate-800 placeholder:font-normal placeholder:text-slate-400"
                                                    placeholder="任务标题（如：首页UI重构） *"
                                                />
                                                {errors.tasks?.[index]?.title && <p className="text-red-500 text-xs mt-1">{errors.tasks[index]?.title?.message}</p>}
                                            </div>

                                            <div className="grid grid-cols-2 gap-4">
                                                <div>
                                                    <label className="block text-xs font-medium text-slate-500 mb-1">分发模式 *</label>
                                                    <select
                                                        {...register(`tasks.${index}.assignMode` as const)}
                                                        className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 focus:border-red-500 outline-none bg-white"
                                                    >
                                                        <option value="OPEN">公开认领 (抢单)</option>
                                                        <option value="COMPETE">竞争上岗 (需审批)</option>
                                                        <option value="ASSIGN">指定委派 (直接分派)</option>
                                                    </select>
                                                </div>
                                                <div>
                                                    <label className="block text-xs font-medium text-slate-500 mb-1">任务积分/工时 *</label>
                                                    <input
                                                        type="number"
                                                        {...register(`tasks.${index}.points` as const, { valueAsNumber: true })}
                                                        className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 focus:border-red-500 outline-none"
                                                        placeholder="例如: 10"
                                                    />
                                                    {errors.tasks?.[index]?.points && <p className="text-red-500 text-xs mt-1">{errors.tasks[index]?.points?.message}</p>}
                                                </div>
                                            </div>

                                            {/* 根据所选模式显示不同字段 */}
                                            {assignMode === 'ASSIGN' && (
                                                <div>
                                                    <label className="block text-xs font-medium text-slate-500 mb-1">被指派人 ID *</label>
                                                    <Controller
                                                        name={`tasks.${index}.assigneeId` as const}
                                                        control={control}
                                                        render={({ field }) => (
                                                            <UserSelect
                                                                value={field.value}
                                                                onChange={field.onChange}
                                                            />
                                                        )}
                                                    />
                                                </div>
                                            )}

                                            {assignMode === 'COMPETE' && (
                                                <div>
                                                    <label className="block text-xs font-medium text-slate-500 mb-1">最大申请组数 (0为不限)</label>
                                                    <input
                                                        type="number"
                                                        {...register(`tasks.${index}.maxApplicants` as const, { valueAsNumber: true })}
                                                        className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 focus:border-red-500 outline-none bg-amber-50/50"
                                                        placeholder="10"
                                                    />
                                                </div>
                                            )}

                                            <div>
                                                <label className="block text-xs font-medium text-slate-500 mb-1">技能要求补充 (可选)</label>
                                                <input
                                                    {...register(`tasks.${index}.requiredSkills` as const)}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 focus:border-red-500 outline-none"
                                                    placeholder="例如: React, SpringBoot"
                                                />
                                            </div>

                                            <div>
                                                <textarea
                                                    {...register(`tasks.${index}.description` as const)}
                                                    rows={2}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 focus:border-red-500 outline-none resize-none"
                                                    placeholder="子任务具体工作内容..."
                                                />
                                                {errors.tasks?.[index]?.description && <p className="text-red-500 text-xs mt-1">{errors.tasks[index]?.description?.message}</p>}
                                            </div>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </form>
                </div>

                {/* 底部操作区 */}
                <div className="p-4 border-t border-slate-100 bg-white flex justify-end gap-3 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
                    <button
                        type="button"
                        onClick={onClose}
                        className="px-5 py-2.5 text-sm font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors"
                    >
                        取消
                    </button>
                    <button
                        type="submit"
                        form="create-work-form"
                        disabled={isSubmitting}
                        className="px-6 py-2.5 text-sm font-bold text-white bg-slate-800 hover:bg-slate-900 rounded-lg transition-colors disabled:opacity-70 disabled:cursor-not-allowed flex items-center gap-2"
                    >
                        {isSubmitting ? '正在保存...' : '创建并保存为草稿'}
                    </button>
                </div>
            </div>
        </>
    );
};

export default CreateWorkDrawer;
