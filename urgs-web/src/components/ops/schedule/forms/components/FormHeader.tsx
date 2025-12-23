import React from 'react';
import { Settings, Maximize2, Minimize2 } from 'lucide-react';

interface FormHeaderProps {
    type: string;
    isMaximized: boolean;
    toggleMaximize: () => void;
    onClose?: () => void;
}

const FormHeader: React.FC<FormHeaderProps> = ({ type, isMaximized, toggleMaximize, onClose }) => {
    return (
        <div className="p-4 border-b border-slate-200 bg-slate-50/50 flex items-center justify-between">
            <h3 className="font-bold text-slate-800 flex items-center gap-2">
                <Settings size={16} className="text-slate-500" />
                当前节点设置
            </h3>
            <div className="flex items-center gap-2">
                <span className="text-xs px-2 py-1 bg-blue-100 text-blue-700 rounded border border-blue-200 font-mono">
                    {type}
                </span>

            </div>
        </div>
    );
};

export default FormHeader;
