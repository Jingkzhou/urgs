import React from 'react';

const ReleaseStats: React.FC = () => {
    return (
        <div className="space-y-4">
            <div className="flex justify-between items-center">
                <h2 className="text-xl font-bold text-slate-800">发布数据统计</h2>
            </div>
            <div className="bg-white rounded-lg border border-slate-200 p-8 text-center text-slate-500">
                暂无统计数据 (Placeholder)
            </div>
        </div>
    );
};

export default ReleaseStats;
