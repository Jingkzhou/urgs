import React, { useState, useEffect } from 'react';
import { Search, Plus, Edit, Trash2, X, Server, Database, Layers, ArrowLeft, FileText, Target, Code, History, Table2 } from 'lucide-react';
import { assetService, RegulatoryAsset } from '../../services/assetService';
import { systemService, SsoConfig } from '../../services/systemService';
import CodeDirectory from './CodeDirectory';
import MaintenanceRecord from './MaintenanceRecord';
import RegulatoryAssetView from './RegulatoryAssetView';

const AssetManagement: React.FC = () => {
    // Top-level Tabs
    const [activeTab, setActiveTab] = useState<'regulatory' | 'codes' | 'maintenance'>('regulatory');

    // Systems
    const [systems, setSystems] = useState<SsoConfig[]>([]);
    const [selectedSystem, setSelectedSystem] = useState<string | undefined>(undefined);

    // Reports (Parent Assets)
    const [reports, setReports] = useState<RegulatoryAsset[]>([]);
    const [reportKeyword, setReportKeyword] = useState('');

    // Indicators (Child Assets) & Drill-down
    const [activeReport, setActiveReport] = useState<RegulatoryAsset | null>(null); // If set, showing drilling down view
    const [indicators, setIndicators] = useState<RegulatoryAsset[]>([]);

    // Modals & Forms
    const [showModal, setShowModal] = useState(false);
    const [editingAsset, setEditingAsset] = useState<RegulatoryAsset | null>(null);

    const initialForm: RegulatoryAsset = {
        name: '',
        code: '',
        systemCode: '',
        type: '报表',
        description: '',
        owner: '',
        status: 1
    };
    const [form, setForm] = useState<RegulatoryAsset>(initialForm);

    // --- Loading Data ---

    const fetchSystems = async () => {
        try {
            const data = await systemService.list();
            setSystems(data);
        } catch (e) {
            console.error('Failed to fetch systems', e);
        }
    };

    const fetchReports = async () => {
        try {
            // Fetch only Reports (type='报表') for the selected system
            const data = await assetService.list(reportKeyword, selectedSystem, undefined, '报表');
            setReports(data);
        } catch (e) {
            console.error(e);
        }
    };

    const fetchIndicators = async (parentId: number) => {
        try {
            // Fetch only Indicators (type='指标') for the specific report
            const data = await assetService.list(undefined, undefined, parentId, '指标');
            setIndicators(data);
        } catch (e) {
            console.error(e);
        }
    };

    useEffect(() => {
        fetchSystems();
    }, []);

    useEffect(() => {
        fetchReports();
        setActiveReport(null); // Reset drill-down when filters change
    }, [selectedSystem]);

    useEffect(() => {
        if (activeReport && activeReport.id) {
            fetchIndicators(activeReport.id);
        }
    }, [activeReport]);

    // --- Handlers ---

    const handleSearchReports = () => {
        fetchReports();
    };

    const handleReportClick = (report: RegulatoryAsset) => {
        setActiveReport(report);
    };

    const handleAdd = () => {
        setEditingAsset(null);
        // Context-aware defaults
        if (activeReport) {
            // Adding Indicator
            setForm({
                ...initialForm,
                type: '指标',
                parentId: activeReport.id,
                systemCode: activeReport.systemCode // Inherit system
            });
        } else {
            // Adding Report
            setForm({
                ...initialForm,
                type: '报表',
                systemCode: selectedSystem || '',
            });
        }
        setShowModal(true);
    };

    const handleEdit = (asset: RegulatoryAsset) => {
        setEditingAsset(asset);
        setForm({ ...asset, systemCode: asset.systemCode || '' });
        setShowModal(true);
    };

    const handleDelete = async (id: number) => {
        if (window.confirm('确定要删除该资产吗？删除后不可恢复。')) {
            await assetService.delete(id);
            if (activeReport) {
                fetchIndicators(activeReport.id!);
            } else {
                fetchReports();
            }
        }
    };

    const handleSubmit = async () => {
        try {
            if (editingAsset) {
                await assetService.update(form);
            } else {
                await assetService.add(form);
            }
            setShowModal(false);

            // Refresh logic
            if (activeReport && (form.type === '指标' || form.parentId)) {
                fetchIndicators(activeReport.id!);
            } else {
                fetchReports();
            }
        } catch (e) {
            alert('操作失败');
        }
    };

    // --- Render Helpers ---

    return (
        <div className="flex flex-col h-full bg-slate-50 overflow-hidden">
            {/* Top Level Tabs */}
            <div className="flex bg-white border-b border-slate-200 px-4 pt-1 flex-none shadow-sm z-10">
                <button
                    onClick={() => setActiveTab('regulatory')}
                    className={`pb-3 px-4 text-sm font-bold border-b-2 transition-all flex items-center gap-2 ${activeTab === 'regulatory' ? 'border-indigo-600 text-indigo-700' : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50 rounded-t-lg'}`}
                >
                    <Table2 size={16} />
                    监管资产
                </button>
                <button
                    onClick={() => setActiveTab('codes')}
                    className={`pb-3 px-4 text-sm font-bold border-b-2 transition-all flex items-center gap-2 ${activeTab === 'codes' ? 'border-indigo-600 text-indigo-700' : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50 rounded-t-lg'}`}
                >
                    <Code size={16} />
                    代码目录
                </button>
                <button
                    onClick={() => setActiveTab('maintenance')}
                    className={`pb-3 px-4 text-sm font-bold border-b-2 transition-all flex items-center gap-2 ${activeTab === 'maintenance' ? 'border-indigo-600 text-indigo-700' : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50 rounded-t-lg'}`}
                >
                    <History size={16} />
                    维护记录
                </button>
            </div>

            {/* Tab Content Area */}
            <div className="flex-1 overflow-hidden relative">
                {activeTab === 'regulatory' && (
                    <div className="h-full p-4 overflow-hidden">
                        <RegulatoryAssetView />
                    </div>
                )}

                {activeTab === 'codes' && (
                    <div className="h-full p-4 overflow-hidden">
                        <CodeDirectory />
                    </div>
                )}

                {activeTab === 'maintenance' && (
                    <div className="h-full p-4 overflow-hidden">
                        <MaintenanceRecord />
                    </div>
                )}
            </div>

            {/* Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50">
                    <div className="bg-white rounded-xl shadow-2xl w-[500px] p-6 animate-in zoom-in-95 duration-200 border border-slate-200">
                        <div className="flex justify-between items-center mb-6">
                            <h3 className="text-lg font-bold text-slate-800">
                                {editingAsset ? '编辑' : '新增'}{form.type}
                            </h3>
                            <button onClick={() => setShowModal(false)} className="p-1 hover:bg-slate-100 rounded-full transition-colors">
                                <X size={20} className="text-slate-400 hover:text-slate-600" />
                            </button>
                        </div>
                        <div className="space-y-4">
                            {/* Context Info */}
                            {form.type === '指标' && (
                                <div className="bg-blue-50 p-3 rounded-lg text-xs text-blue-700 mb-2 flex items-center gap-2">
                                    <FileText size={14} /> 所属报表: {activeReport?.name}
                                </div>
                            )}

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1.5">名称</label>
                                <input className="w-full border border-slate-200 rounded-lg p-2.5 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none transition-all" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1.5">代码</label>
                                    <input className="w-full border border-slate-200 rounded-lg p-2.5 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none transition-all" value={form.code} onChange={e => setForm({ ...form, code: e.target.value })} />
                                </div>
                                {/* Only show System select if it's a Report (and not locked by filter/context) or if necessary */}
                                {form.type === '报表' && (
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1.5">所属系统</label>
                                        <select
                                            className="w-full border border-slate-200 rounded-lg p-2.5 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none transition-all bg-white"
                                            value={form.systemCode}
                                            onChange={e => setForm({ ...form, systemCode: e.target.value })}
                                            disabled={!!selectedSystem && !editingAsset} // Lock if creating under a selected system
                                        >
                                            <option value="">-- 请选择 --</option>
                                            {systems.map(sys => (
                                                <option key={sys.id} value={sys.clientId}>{sys.name}</option>
                                            ))}
                                        </select>
                                    </div>
                                )}
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1.5">状态</label>
                                    <select className="w-full border border-slate-200 rounded-lg p-2.5 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none transition-all bg-white" value={form.status} onChange={e => setForm({ ...form, status: Number(e.target.value) })}>
                                        <option value={1}>启用</option>
                                        <option value={0}>停用</option>
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1.5">责任人</label>
                                <input className="w-full border border-slate-200 rounded-lg p-2.5 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none transition-all" value={form.owner} onChange={e => setForm({ ...form, owner: e.target.value })} />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1.5">描述</label>
                                <textarea className="w-full border border-slate-200 rounded-lg p-2.5 text-sm h-24 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none transition-all resize-none" value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
                            </div>
                        </div>
                        <div className="mt-6 flex justify-end gap-3">
                            <button onClick={() => setShowModal(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors">取消</button>
                            <button onClick={handleSubmit} className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 font-medium shadow-md shadow-indigo-200 transition-all">
                                保存{form.type}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default AssetManagement;
