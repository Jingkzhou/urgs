import React, { useEffect, useMemo, useState } from 'react';
import { Check, Edit3, Plus, RefreshCw, Trash2, X } from 'lucide-react';
import {
    createPointRule,
    deletePointRule,
    listPointRules,
    MarketplacePointRule,
    updatePointRule,
} from '../../api/marketplace';

const defaultRule: MarketplacePointRule = {
    taskType: '开发',
    difficulty: '中等',
    suggestedPoints: 10,
    description: '',
    enabled: true,
};

const PointRuleConfig: React.FC = () => {
    const [rules, setRules] = useState<MarketplacePointRule[]>([]);
    const [form, setForm] = useState<MarketplacePointRule>(defaultRule);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        fetchRules();
    }, []);

    const taskTypes = useMemo(() => {
        const values = Array.from(new Set(['开发', '测试', '数据', '文档', ...rules.map(rule => rule.taskType).filter(Boolean)]));
        return values;
    }, [rules]);

    const difficulties = useMemo(() => {
        const values = Array.from(new Set(['简单', '中等', '复杂', ...rules.map(rule => rule.difficulty).filter(Boolean)]));
        return values;
    }, [rules]);

    const fetchRules = async () => {
        setLoading(true);
        try {
            const res = await listPointRules();
            setRules(res || []);
        } catch (error) {
            console.error('Failed to fetch point rules', error);
        } finally {
            setLoading(false);
        }
    };

    const resetForm = () => {
        setForm(defaultRule);
        setEditingId(null);
    };

    const handleSubmit = async () => {
        if (!form.taskType.trim() || !form.difficulty.trim() || form.suggestedPoints < 0) {
            alert('请填写任务类型、难度和有效积分');
            return;
        }
        setSaving(true);
        try {
            if (editingId) {
                await updatePointRule(editingId, form);
            } else {
                await createPointRule(form);
            }
            resetForm();
            await fetchRules();
        } catch (error) {
            console.error('Failed to save point rule', error);
            alert('保存积分规则失败，请检查是否已存在相同类型和难度');
        } finally {
            setSaving(false);
        }
    };

    const handleEdit = (rule: MarketplacePointRule) => {
        setEditingId(rule.id || null);
        setForm({
            taskType: rule.taskType,
            difficulty: rule.difficulty,
            suggestedPoints: rule.suggestedPoints,
            description: rule.description || '',
            enabled: rule.enabled !== false,
        });
    };

    const handleDelete = async (rule: MarketplacePointRule) => {
        if (!rule.id || !window.confirm(`确认删除 ${rule.taskType}/${rule.difficulty} 的积分规则吗？`)) {
            return;
        }
        await deletePointRule(rule.id);
        await fetchRules();
    };

    return (
        <div className="h-full flex flex-col p-6 overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
                <div>
                    <h2 className="text-xl font-bold text-slate-800">规则配置</h2>
                    <p className="text-sm text-slate-500 mt-1">按任务类型和难度维护建议积分，减少人工估分偏差</p>
                </div>
                <button
                    onClick={fetchRules}
                    className="inline-flex items-center gap-2 px-3 py-2 text-sm font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg"
                >
                    <RefreshCw size={15} /> 刷新
                </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-[360px_1fr] gap-6">
                <section className="bg-slate-50 rounded-xl border border-slate-200 p-5">
                    <div className="flex items-center gap-2 mb-4">
                        {editingId ? <Edit3 size={17} className="text-red-500" /> : <Plus size={17} className="text-red-500" />}
                        <h3 className="font-bold text-slate-800">{editingId ? '编辑规则' : '新增规则'}</h3>
                    </div>

                    <div className="space-y-4">
                        <div>
                            <label className="block text-xs font-bold text-slate-500 mb-1">任务类型</label>
                            <input
                                list="marketplace-task-types"
                                value={form.taskType}
                                onChange={e => setForm(prev => ({ ...prev, taskType: e.target.value }))}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-red-500 outline-none"
                            />
                            <datalist id="marketplace-task-types">
                                {taskTypes.map(type => <option value={type} key={type} />)}
                            </datalist>
                        </div>

                        <div>
                            <label className="block text-xs font-bold text-slate-500 mb-1">难度</label>
                            <input
                                list="marketplace-difficulties"
                                value={form.difficulty}
                                onChange={e => setForm(prev => ({ ...prev, difficulty: e.target.value }))}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-red-500 outline-none"
                            />
                            <datalist id="marketplace-difficulties">
                                {difficulties.map(item => <option value={item} key={item} />)}
                            </datalist>
                        </div>

                        <div>
                            <label className="block text-xs font-bold text-slate-500 mb-1">建议积分</label>
                            <input
                                type="number"
                                value={form.suggestedPoints}
                                onChange={e => setForm(prev => ({ ...prev, suggestedPoints: Number(e.target.value) || 0 }))}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-red-500 outline-none"
                            />
                        </div>

                        <div>
                            <label className="block text-xs font-bold text-slate-500 mb-1">说明</label>
                            <textarea
                                value={form.description || ''}
                                onChange={e => setForm(prev => ({ ...prev, description: e.target.value }))}
                                rows={3}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-red-500 outline-none resize-none"
                                placeholder="说明适用范围，便于项目经理估分"
                            />
                        </div>

                        <label className="flex items-center gap-2 text-sm text-slate-600">
                            <input
                                type="checkbox"
                                checked={form.enabled !== false}
                                onChange={e => setForm(prev => ({ ...prev, enabled: e.target.checked }))}
                            />
                            启用该规则
                        </label>

                        <div className="flex justify-end gap-2">
                            {editingId && (
                                <button
                                    type="button"
                                    onClick={resetForm}
                                    className="inline-flex items-center gap-1 px-3 py-2 text-sm font-bold text-slate-500 hover:bg-white rounded-lg"
                                >
                                    <X size={15} /> 取消
                                </button>
                            )}
                            <button
                                type="button"
                                onClick={handleSubmit}
                                disabled={saving}
                                className="inline-flex items-center gap-1 px-4 py-2 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg disabled:opacity-60"
                            >
                                <Check size={15} /> {saving ? '保存中...' : '保存规则'}
                            </button>
                        </div>
                    </div>
                </section>

                <section>
                    {loading ? (
                        <div className="text-center py-12 text-slate-400">正在加载规则...</div>
                    ) : (
                        <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
                            {rules.map(rule => (
                                <div key={rule.id} className="rounded-xl border border-slate-200 bg-white p-4">
                                    <div className="flex items-start justify-between gap-3">
                                        <div>
                                            <div className="flex items-center gap-2">
                                                <span className="font-black text-slate-800">{rule.taskType}</span>
                                                <span className="text-xs px-2 py-0.5 rounded bg-slate-100 text-slate-500">{rule.difficulty}</span>
                                                <span className={`text-xs px-2 py-0.5 rounded ${rule.enabled === false ? 'bg-slate-100 text-slate-400' : 'bg-green-50 text-green-600'}`}>
                                                    {rule.enabled === false ? '停用' : '启用'}
                                                </span>
                                            </div>
                                            <div className="text-sm text-slate-500 mt-2 line-clamp-2">{rule.description || '暂无说明'}</div>
                                        </div>
                                        <div className="text-right shrink-0">
                                            <div className="text-2xl font-black text-orange-600">{rule.suggestedPoints}</div>
                                            <div className="text-xs text-slate-400">建议积分</div>
                                        </div>
                                    </div>
                                    <div className="flex justify-end gap-2 mt-4">
                                        <button
                                            onClick={() => handleEdit(rule)}
                                            className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg"
                                        >
                                            <Edit3 size={13} /> 编辑
                                        </button>
                                        <button
                                            onClick={() => handleDelete(rule)}
                                            className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-red-600 bg-red-50 hover:bg-red-100 rounded-lg"
                                        >
                                            <Trash2 size={13} /> 删除
                                        </button>
                                    </div>
                                </div>
                            ))}
                            {rules.length === 0 && (
                                <div className="text-center py-12 text-slate-400 bg-slate-50 rounded-xl border border-slate-200">
                                    暂无积分规则
                                </div>
                            )}
                        </div>
                    )}
                </section>
            </div>
        </div>
    );
};

export default PointRuleConfig;
