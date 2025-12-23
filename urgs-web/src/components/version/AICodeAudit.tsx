import React from 'react';
import Auth from '../Auth';

interface Props {
    ssoId?: number;
    repoId?: number;
}

const AICodeAudit: React.FC<Props> = ({ ssoId, repoId }) => {
    return (
        <div className="space-y-4">
            <div className="flex justify-between items-center">
                <h2 className="text-xl font-bold text-slate-800">AI 代码智查</h2>
                <div className="flex gap-2">
                    <Auth code="version:ai:trigger">
                        <button className="px-4 py-2.5 rounded-lg text-white font-semibold shadow-sm hover:shadow transition-all bg-gradient-to-r from-indigo-500 via-purple-500 to-blue-500 hover:from-indigo-600 hover:via-purple-600 hover:to-blue-600">
                            ⚡ 触发智查
                        </button>
                    </Auth>
                    <Auth code="version:ai:export">
                        <button className="px-4 py-2.5 bg-white border border-indigo-100 text-indigo-600 rounded-lg hover:bg-indigo-50 transition-all shadow-sm">
                            📄 下载审计报告
                        </button>
                    </Auth>
                </div>
            </div>
            <div className="bg-white rounded-lg border border-slate-200 p-8 text-center text-slate-500">
                暂无审计报告 (Placeholder)
            </div>
        </div>
    );
};

export default AICodeAudit;
