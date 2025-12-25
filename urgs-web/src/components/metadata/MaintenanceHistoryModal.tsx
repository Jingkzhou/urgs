import React, { useEffect, useState } from 'react';
import { X, Calendar, User, Tag, Clock } from 'lucide-react';
import axios from 'axios';

interface MaintenanceRecord {
    id: string;
    tableName: string;
    tableCnName: string;
    fieldName: string;
    fieldCnName: string;
    reqId?: string; // Added
    plannedDate?: string; // Added
    modType: string;
    description: string;
    operator: string;
    time: string;
}

interface MaintenanceHistoryModalProps {
    isOpen: boolean;
    onClose: () => void;
    tableId?: number | string;
    tableName: string;
    tableCnName?: string;
    fieldName?: string;
    fieldCnName?: string;
}

const MaintenanceHistoryModal: React.FC<MaintenanceHistoryModalProps> = ({
    isOpen,
    onClose,
    tableId,
    tableName,
    tableCnName,
    fieldName,
    fieldCnName,
}) => {
    const [records, setRecords] = useState<MaintenanceRecord[]>([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (isOpen && (tableName || tableId)) {
            fetchRecords();
        }
    }, [isOpen, tableName, tableId, fieldName]);

    const fetchRecords = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            const params: any = {
                tableName,
                size: 100,
            };
            if (tableId) {
                params.tableId = tableId;
            }
            if (fieldName) {
                params.fieldName = fieldName;
            }
            const response = await axios.get('/api/metadata/maintenance-record', {
                params,
                headers: { 'Authorization': `Bearer ${token}` }
            });
            setRecords(response.data.records);
        } catch (error) {
            console.error('Failed to fetch maintenance history', error);
            setRecords([]);
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-xl shadow-2xl w-full max-w-4xl max-h-[80vh] flex flex-col animate-in fade-in zoom-in duration-200">

                {/* Header */}
                <div className="flex items-center justify-between p-6 border-b border-gray-100">
                    <div>
                        <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
                            <Clock className="w-5 h-5 text-blue-600" />
                            变更历史记录
                        </h2>
                        <p className="text-sm text-gray-500 mt-1">
                            {tableCnName || tableName}
                            {fieldName && (
                                <span className="ml-2 px-2 py-0.5 bg-blue-50 text-blue-700 rounded-full text-xs">
                                    {fieldCnName || fieldName}
                                </span>
                            )}
                        </p>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-gray-100 rounded-full transition-colors text-gray-500 hover:text-gray-700"
                    >
                        <X className="w-5 h-5" />
                    </button>
                </div>

                {/* Content */}
                <div className="flex-1 overflow-y-auto p-6">
                    {loading ? (
                        <div className="flex items-center justify-center h-40">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                        </div>
                    ) : records.length === 0 ? (
                        <div className="text-center py-12 text-gray-500">
                            暂无变更记录
                        </div>
                    ) : (
                        <div className="relative border-l-2 border-gray-200 ml-4 space-y-8">
                            {records.map((record, index) => (
                                <div key={record.id} className="relative pl-6">
                                    {/* Timeline Dot */}
                                    <div className={`absolute -left-[9px] top-1 w-4 h-4 rounded-full border-2 border-white ${record.modType === 'CREATE' ? 'bg-green-500' :
                                        record.modType === 'DELETE' ? 'bg-red-500' : 'bg-blue-500'
                                        }`}></div>

                                    <div className="bg-gray-50 rounded-lg p-4 hover:bg-gray-100 transition-colors">
                                        <div className="flex flex-wrap items-center gap-3 text-sm text-gray-500 mb-2">
                                            <span className="flex items-center gap-1">
                                                <Calendar className="w-4 h-4" />
                                                {new Date(record.time).toLocaleString()}
                                            </span>
                                            <span className="flex items-center gap-1">
                                                <User className="w-4 h-4" />
                                                {record.operator}
                                            </span>
                                            <span className={`px-2 py-0.5 rounded text-xs font-medium ${record.modType === 'CREATE' ? 'bg-green-100 text-green-700' :
                                                record.modType === 'DELETE' ? 'bg-red-100 text-red-700' :
                                                    'bg-blue-100 text-blue-700'
                                                }`}>
                                                {record.modType}
                                            </span>
                                        </div>

                                        {/* Requirement Info */}
                                        {(record.reqId || record.plannedDate) && (
                                            <div className="flex flex-wrap gap-3 mb-2 text-xs">
                                                {record.reqId && (
                                                    <span className="flex items-center gap-1 bg-amber-50 text-amber-700 px-2 py-0.5 rounded border border-amber-100">
                                                        <Tag className="w-3 h-3" />
                                                        需求: {record.reqId}
                                                    </span>
                                                )}
                                                {record.plannedDate && (
                                                    <span className="flex items-center gap-1 bg-purple-50 text-purple-700 px-2 py-0.5 rounded border border-purple-100">
                                                        <Calendar className="w-3 h-3" />
                                                        计划上线: {record.plannedDate}
                                                    </span>
                                                )}
                                            </div>
                                        )}

                                        <p className="text-gray-800 text-base leading-relaxed">
                                            {record.description}
                                        </p>

                                        {/* Context Info */}
                                        <div className="mt-2 text-xs text-gray-400 flex gap-4">
                                            {/* Only show field name if we are viewing the whole table history and this record is about a field */}
                                            {!fieldName && record.fieldName && (
                                                <span>字段: {record.fieldCnName || record.fieldName}</span>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className="p-4 border-t border-gray-100 flex justify-end">
                    <button
                        onClick={onClose}
                        className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transaction-colors"
                    >
                        关闭
                    </button>
                </div>
            </div>
        </div>
    );
};

export default MaintenanceHistoryModal;
