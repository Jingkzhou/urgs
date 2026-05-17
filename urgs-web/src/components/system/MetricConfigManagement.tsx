import React, { useEffect, useMemo, useState } from 'react';
import { BarChart3, Edit, LineChart, PieChart, Save, Trash2, X } from 'lucide-react';
import {
  createMetricTypeConfig,
  deleteMetricTypeConfig,
  fetchMetricConfigSystems,
  fetchMetricTypeConfigs,
  MetricChartType,
  MetricSystemVO,
  MetricTypeVO,
  updateMetricTypeConfig,
} from '../../api/metrics';
import Auth from '../Auth';
import { ActionToolbar } from './Shared';

const chartTypeOptions: { value: MetricChartType; label: string; icon: React.ElementType }[] = [
  { value: 'area', label: '面积图', icon: LineChart },
  { value: 'line', label: '折线图', icon: LineChart },
  { value: 'bar', label: '柱状图', icon: BarChart3 },
  { value: 'pie', label: '饼状图', icon: PieChart },
];

const defaultForm: MetricTypeVO = {
  systemId: '',
  typeCode: '',
  typeName: '',
  unit: '',
  color: '#ef4444',
  defaultChartType: 'area',
  supportedChartTypes: 'area',
  sortOrder: 0,
  status: 1,
};

function normalizeChartType(value?: string): MetricChartType {
  return ['area', 'line', 'bar', 'pie'].includes(value || '') ? (value as MetricChartType) : 'area';
}

function chartTypeLabel(value?: string) {
  return chartTypeOptions.find((item) => item.value === value)?.label || '面积图';
}

interface MetricConfigManagementProps {
  fixedSystemId?: string;
  fixedSystemName?: string;
  onClose?: () => void;
}

const MetricConfigManagement: React.FC<MetricConfigManagementProps> = ({ fixedSystemId, fixedSystemName, onClose }) => {
  const isFixedSystem = Boolean(fixedSystemId);
  const [systems, setSystems] = useState<MetricSystemVO[]>([]);
  const [selectedSystemId, setSelectedSystemId] = useState(fixedSystemId || '');
  const [items, setItems] = useState<MetricTypeVO[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<MetricTypeVO | null>(null);
  const [formData, setFormData] = useState<MetricTypeVO>(defaultForm);

  const systemNameMap = useMemo(() => {
    return new Map(systems.map((system) => [system.clientId, system.name]));
  }, [systems]);

  const filteredItems = useMemo(() => {
    const keyword = searchTerm.trim().toLowerCase();
    return items.filter((item) => {
      const matchesSystem = !selectedSystemId || item.systemId === selectedSystemId;
      if (!matchesSystem) return false;
      if (!keyword) return true;
      return [item.typeCode, item.typeName, item.unit, systemNameMap.get(item.systemId || '')]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(keyword));
    });
  }, [items, searchTerm, selectedSystemId, systemNameMap]);

  const loadSystems = async () => {
    const list = await fetchMetricConfigSystems();
    setSystems(list);
    if (fixedSystemId) {
      setSelectedSystemId(fixedSystemId);
    } else if (!selectedSystemId && list.length > 0) {
      setSelectedSystemId(list[0].clientId);
    }
  };

  const loadItems = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fetchMetricTypeConfigs(fixedSystemId);
      setItems(data || []);
    } catch (err) {
      setError('指标配置加载失败，请稍后重试');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSystems();
    loadItems();
  }, [fixedSystemId]);

  const openForm = (item?: MetricTypeVO | null) => {
    const next = item
      ? { ...item, defaultChartType: normalizeChartType(item.defaultChartType), supportedChartTypes: normalizeChartType(item.defaultChartType) }
      : { ...defaultForm, systemId: fixedSystemId || selectedSystemId || systems[0]?.clientId || '' };
    setEditing(item || null);
    setFormData(next);
    setShowForm(true);
  };

  const closeForm = () => {
    setShowForm(false);
    setEditing(null);
    setFormData(defaultForm);
  };

  const handleSave = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!formData.systemId || !formData.typeCode || !formData.typeName) {
      setError('系统、指标编码、指标名称不能为空');
      return;
    }
    const chartType = normalizeChartType(formData.defaultChartType);
    const payload = {
      systemId: formData.systemId,
      typeCode: formData.typeCode,
      typeName: formData.typeName,
      unit: formData.unit,
      color: formData.color,
      supportedChartTypes: chartType,
      defaultChartType: chartType,
      sortOrder: Number(formData.sortOrder || 0),
      status: Number(formData.status ?? 1),
    };

    try {
      if (editing?.id) {
        await updateMetricTypeConfig(editing.id, payload);
      } else {
        await createMetricTypeConfig(payload);
      }
      await loadItems();
      closeForm();
    } catch (err: any) {
      setError(err?.message || '保存失败，请检查指标编码是否重复');
    }
  };

  const handleDelete = async (item: MetricTypeVO) => {
    if (!item.id || !window.confirm(`确认删除指标配置「${item.typeName}」吗？`)) return;
    try {
      await deleteMetricTypeConfig(item.id);
      await loadItems();
    } catch (err) {
      setError('删除失败，请稍后重试');
    }
  };

  return (
    <div className="space-y-4 animate-fade-in">
      <ActionToolbar
        title={isFixedSystem ? `${fixedSystemName || fixedSystemId} / 指标走势配置` : '首页指标走势配置'}
        placeholder="搜索系统、指标编码或名称..."
        codePrefix="sys:metric"
        onAdd={() => openForm(null)}
        onSearch={setSearchTerm}
      >
        {isFixedSystem && onClose && (
          <button
            type="button"
            onClick={onClose}
            className="px-3 py-2 rounded-md text-sm font-bold text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-colors"
          >
            关闭
          </button>
        )}
        {!isFixedSystem && (
          <select
            value={selectedSystemId}
            onChange={(event) => setSelectedSystemId(event.target.value)}
            className="px-3 py-2 border border-slate-200 rounded-md text-sm bg-white focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none"
          >
            <option value="">全部系统</option>
            {systems.map((system) => (
              <option key={system.clientId} value={system.clientId}>{system.name}</option>
            ))}
          </select>
        )}
      </ActionToolbar>

      {error && <div className="text-sm text-red-600 bg-red-50 border border-red-200 px-3 py-2 rounded">{error}</div>}
      {loading && <div className="text-sm text-slate-500 bg-slate-50 border border-slate-200 px-3 py-2 rounded">加载中...</div>}

      <div className="bg-white rounded-lg border border-slate-200 overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="bg-slate-50 text-slate-700 font-semibold border-b border-slate-200">
            <tr>
              <th className="px-4 py-3 whitespace-nowrap">所属系统</th>
              <th className="px-4 py-3 whitespace-nowrap">指标编码</th>
              <th className="px-4 py-3 whitespace-nowrap">指标名称</th>
              <th className="px-4 py-3 whitespace-nowrap">单位</th>
              <th className="px-4 py-3 whitespace-nowrap">颜色</th>
              <th className="px-4 py-3 whitespace-nowrap">图表类型</th>
              <th className="px-4 py-3 whitespace-nowrap">排序</th>
              <th className="px-4 py-3 whitespace-nowrap">状态</th>
              <th className="px-4 py-3 whitespace-nowrap text-right">操作</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {filteredItems.map((item) => (
              <tr key={item.id || `${item.systemId}-${item.typeCode}`} className="hover:bg-slate-50 transition-colors">
                <td className="px-4 py-3 font-medium text-slate-900">{systemNameMap.get(item.systemId || '') || item.systemId}</td>
                <td className="px-4 py-3 font-mono text-xs text-slate-600">{item.typeCode}</td>
                <td className="px-4 py-3 text-slate-700">{item.typeName}</td>
                <td className="px-4 py-3 text-slate-500">{item.unit || '-'}</td>
                <td className="px-4 py-3">
                  <span className="inline-flex items-center gap-2 text-xs font-mono text-slate-600">
                    <span className="w-4 h-4 rounded border border-slate-200" style={{ backgroundColor: item.color || '#ef4444' }} />
                    {item.color || '#ef4444'}
                  </span>
                </td>
                <td className="px-4 py-3 text-slate-600">{chartTypeLabel(item.defaultChartType)}</td>
                <td className="px-4 py-3 text-slate-500">{item.sortOrder ?? 0}</td>
                <td className="px-4 py-3">
                  {item.status === 0 ? (
                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-500">停用</span>
                  ) : (
                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">启用</span>
                  )}
                </td>
                <td className="px-4 py-3 text-right">
                  <div className="flex items-center justify-end gap-2">
                    <Auth code="sys:metric:edit">
                      <button onClick={() => openForm(item)} className="p-1.5 text-slate-400 hover:text-blue-600 bg-slate-100 hover:bg-blue-50 rounded transition-colors" title="编辑">
                        <Edit size={14} />
                      </button>
                    </Auth>
                    <Auth code="sys:metric:del">
                      <button onClick={() => handleDelete(item)} className="p-1.5 text-slate-400 hover:text-red-600 bg-slate-100 hover:bg-red-50 rounded transition-colors" title="删除">
                        <Trash2 size={14} />
                      </button>
                    </Auth>
                  </div>
                </td>
              </tr>
            ))}

            {filteredItems.length === 0 && !loading && (
              <tr>
                <td colSpan={9} className="px-4 py-6 text-center text-slate-400">暂无指标配置，可点击新增</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/20 backdrop-blur-sm animate-fade-in">
          <div className="bg-white w-full max-w-2xl rounded-xl shadow-2xl pointer-events-auto relative flex flex-col max-h-[90vh]">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
              <h3 className="text-lg font-bold text-slate-800">{editing ? '编辑指标配置' : '新增指标配置'}</h3>
              <button onClick={closeForm} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSave} className="p-6 overflow-y-auto space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <label className="block">
                  <span className="block text-sm font-bold text-slate-700 mb-1">所属系统</span>
                  <select
                    required
                    value={formData.systemId}
                    onChange={(event) => setFormData({ ...formData, systemId: event.target.value })}
                    disabled={isFixedSystem}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 bg-white"
                  >
                    <option value="">请选择系统</option>
                    {systems.map((system) => (
                      <option key={system.clientId} value={system.clientId}>{system.name}</option>
                    ))}
                  </select>
                </label>
                <label className="block">
                  <span className="block text-sm font-bold text-slate-700 mb-1">指标编码</span>
                  <input
                    required
                    value={formData.typeCode}
                    onChange={(event) => setFormData({ ...formData, typeCode: event.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 font-mono text-sm"
                    placeholder="如 txn_volume"
                  />
                </label>
                <label className="block">
                  <span className="block text-sm font-bold text-slate-700 mb-1">指标名称</span>
                  <input
                    required
                    value={formData.typeName}
                    onChange={(event) => setFormData({ ...formData, typeName: event.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="如 交易量"
                  />
                </label>
                <label className="block">
                  <span className="block text-sm font-bold text-slate-700 mb-1">单位</span>
                  <input
                    value={formData.unit || ''}
                    onChange={(event) => setFormData({ ...formData, unit: event.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
                    placeholder="笔 / ms / %"
                  />
                </label>
                <label className="block">
                  <span className="block text-sm font-bold text-slate-700 mb-1">颜色</span>
                  <div className="flex gap-2">
                    <input
                      type="color"
                      value={formData.color || '#ef4444'}
                      onChange={(event) => setFormData({ ...formData, color: event.target.value })}
                      className="h-10 w-12 rounded border border-slate-300 bg-white"
                    />
                    <input
                      value={formData.color || '#ef4444'}
                      onChange={(event) => setFormData({ ...formData, color: event.target.value })}
                      className="flex-1 px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 font-mono text-sm"
                    />
                  </div>
                </label>
                <label className="block">
                  <span className="block text-sm font-bold text-slate-700 mb-1">排序</span>
                  <input
                    type="number"
                    value={formData.sortOrder ?? 0}
                    onChange={(event) => setFormData({ ...formData, sortOrder: Number(event.target.value) })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
                  />
                </label>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <label className="block">
                  <span className="block text-sm font-bold text-slate-700 mb-1">图表类型</span>
                  <select
                    value={formData.defaultChartType || 'area'}
                    onChange={(event) => {
                      const chartType = event.target.value as MetricChartType;
                      setFormData({ ...formData, defaultChartType: chartType, supportedChartTypes: chartType });
                    }}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 bg-white"
                  >
                    {chartTypeOptions.map(({ value, label }) => (
                      <option key={value} value={value}>{label}</option>
                    ))}
                  </select>
                </label>
                <label className="block">
                  <span className="block text-sm font-bold text-slate-700 mb-1">状态</span>
                  <select
                    value={formData.status ?? 1}
                    onChange={(event) => setFormData({ ...formData, status: Number(event.target.value) })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 bg-white"
                  >
                    <option value={1}>启用</option>
                    <option value={0}>停用</option>
                  </select>
                </label>
              </div>

              <div className="pt-4 border-t border-slate-100 bg-white rounded-b-xl flex justify-end gap-3">
                <button type="button" onClick={closeForm} className="px-4 py-2 text-sm font-bold text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">取消</button>
                <button type="submit" className="px-4 py-2 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg shadow-md shadow-red-200 transition-colors flex items-center gap-2">
                  <Save className="w-4 h-4" />
                  保存
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default MetricConfigManagement;
