import React, { useState } from 'react';
import { Tabs } from 'antd';
import { ApiOutlined, RobotOutlined, DatabaseOutlined } from '@ant-design/icons';
import AiApiManager from './AiApiManager';
import AiAgentManager from './AiAgentManager';
import AiKnowledgeManager from './AiKnowledgeManager';
import Auth from '../../Auth';

const AiManagement: React.FC = () => {
    const [activeTab, setActiveTab] = useState('agent');

    const items = [
        {
            key: 'agent',
            label: (
                <span className="px-2">
                    <RobotOutlined /> 助手管理
                </span>
            ),
            children: (
                <Auth code="sys:ai:agent:list">
                    <AiAgentManager />
                </Auth>
            ),
        },
        {
            key: 'api',
            label: (
                <span className="px-2">
                    <ApiOutlined /> API 管理
                </span>
            ),
            children: (
                <Auth code="sys:ai:api:list">
                    <AiApiManager />
                </Auth>
            ),
        },
        {
            key: 'knowledge',
            label: (
                <span className="px-2">
                    <DatabaseOutlined /> 知识库管理
                </span>
            ),
            children: (
                <Auth code="sys:ai:knowledge:list">
                    <AiKnowledgeManager />
                </Auth>
            ),
        },
    ];

    return (
        <div className="bg-white rounded-lg shadow-sm min-h-[600px]">
            {/* Use Ant Design Tabs for sub-navigation */}
            <Tabs
                activeKey={activeTab}
                onChange={setActiveTab}
                items={items}
                type="card"
                className="pt-4 px-4"
                tabBarStyle={{ marginBottom: 0 }}
            />
            <div className="p-0 bg-slate-50 border-t border-slate-200">
                {/* Content Rendered by Tabs */}
            </div>
        </div>
    );
};

export default AiManagement;
