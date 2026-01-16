import React, { useState } from 'react';
import { X, Trash2, AlertTriangle } from 'lucide-react';
import ReqInfoFormGroup, { ReqInfo } from './ReqInfoFormGroup';

interface DeleteWithReasonModalProps {
    title: string;
    warningMessage: string;
    onClose: () => void;
    onConfirm: (reqInfo: ReqInfo) => Promise<void>;
}

const DeleteWithReasonModal: React.FC<DeleteWithReasonModalProps> = ({ title, warningMessage, onClose, onConfirm }) => {
    const [reqInfo, setReqInfo] = useState<ReqInfo>({
        reqId: '',
        plannedDate: '',
        changeDescription: ''
    });
    const [confirming, setConfirming] = useState(false);

    const handleConfirm = async () => {
        if (!reqInfo.changeDescription) {
            alert('请填写需求变更描述 (删除原因)');
            return;
        }
        setConfirming(true);
        try {
            await onConfirm(reqInfo);
            onClose();
        } catch (e) {
            console.error(e);
            alert('删除失败');
        } finally {
            setConfirming(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[60] flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg md:max-w-xl animate-in fade-in zoom-in-95 duration-200 flex flex-col max-h-[90vh]">
                {/* Header */}
                <div className="flex items-center justify-between p-5 border-b border-red-100 bg-red-50/50 rounded-t-2xl">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-red-100 rounded-lg">
                            <Trash2 className="w-5 h-5 text-red-600" />
                        </div>
                        <h2 className="text-lg font-bold text-red-900">{title}</h2>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-red-100 rounded-full transition-colors">
                        <X className="w-5 h-5 text-red-400" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-6 space-y-6 overflow-y-auto">
                    {/* Warning */}
                    <div className="bg-red-50 border border-red-100 rounded-xl p-4 flex gap-3 text-red-800">
                        <AlertTriangle className="w-5 h-5 flex-shrink-0" />
                        <p className="text-sm font-medium leading-relaxed">
                            {warningMessage}
                        </p>
                    </div>

                    {/* Req Info Form */}
                    <ReqInfoFormGroup
                        data={reqInfo}
                        onChange={setReqInfo}
                        title="删除原因与需求依据"
                        className="bg-white border-slate-200 shadow-sm"
                    />
                </div>

                {/* Footer */}
                <div className="p-4 border-t border-slate-100 flex justify-end gap-3 bg-slate-50/50 rounded-b-2xl">
                    <button
                        onClick={onClose}
                        className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg font-medium transition-colors"
                    >
                        取消
                    </button>
                    <button
                        onClick={handleConfirm}
                        disabled={confirming}
                        className="px-5 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium shadow-lg shadow-red-200 transition-all flex items-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
                    >
                        {confirming ? (
                            <>
                                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                删除中...
                            </>
                        ) : (
                            <>
                                <Trash2 size={16} />
                                确认删除
                            </>
                        )}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default DeleteWithReasonModal;
