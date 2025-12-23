import React, { useState } from 'react';
import OrgManagement from './system/OrgManagement';
import RoleManagement from './system/RoleManagement';
import UserManagement from './system/UserManagement';
import MenuManagement from './system/MenuManagement';
import RegSystemManagement from './system/RegSystemManagement';
import DataSourceManager from './DataSourceManager';
import AiManagement from './system/ai/AiManagement';
import Auth from './Auth';

type SubModule = 'org' | 'role' | 'user' | 'menu' | 'sso' | 'datasource' | 'ai';

const SystemManagement: React.FC = () => {
  const [activeModule, setActiveModule] = useState<SubModule>('org');

  const tabs = [
    { id: 'org', label: '机构管理', permission: 'sys:org' },
    { id: 'role', label: '角色管理', permission: 'sys:role' },
    { id: 'user', label: '用户管理', permission: 'sys:user' },
    { id: 'menu', label: '菜单功能', permission: 'sys:menu' },
    { id: 'system', label: '监管系统', permission: 'sys:system' },
    { id: 'datasource', label: '数据源配置', permission: 'sys:datasource' },
    { id: 'ai', label: 'AI 管理', permission: 'sys:ai' },
  ];

  return (
    <div className="p-6 max-w-7xl mx-auto animate-fade-in">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-slate-800">系统管理</h2>
          <p className="text-slate-500 mt-1">配置系统基础数据、权限及外部系统集成</p>
        </div>
      </div>

      {/* Module Tabs */}
      <div className="flex gap-1 bg-slate-100 p-1 rounded-lg w-fit mb-6">
        {tabs.map(tab => (
          <Auth key={tab.id} code={tab.permission}>
            <button
              onClick={() => setActiveModule(tab.id as SubModule)}
              className={`
                  px-4 py-2 rounded-md text-sm font-medium transition-all
                  ${activeModule === tab.id
                  ? 'bg-white text-red-600 shadow-sm'
                  : 'text-slate-500 hover:text-slate-700 hover:bg-slate-200/50'}
                `}
            >
              {tab.label}
            </button>
          </Auth>
        ))}
      </div>

      {/* Module Content */}
      <div className="min-h-[500px]">
        {activeModule === 'org' && (
          <Auth code="sys:org:query">
            <OrgManagement />
          </Auth>
        )}
        {activeModule === 'role' && (
          <Auth code="sys:role:query">
            <RoleManagement />
          </Auth>
        )}
        {activeModule === 'user' && (
          <Auth code="sys:user:query">
            <UserManagement />
          </Auth>
        )}
        {activeModule === 'menu' && (
          <Auth code="sys:menu">
            <MenuManagement />
          </Auth>
        )}
        {activeModule === 'system' && (
          <Auth code="sys:system:query">
            <RegSystemManagement />
          </Auth>
        )}
        {activeModule === 'datasource' && (
          <Auth code="datasource:list">
            <DataSourceManager />
          </Auth>
        )}
        {activeModule === 'ai' && (
          <Auth code="sys:ai">
            <AiManagement />
          </Auth>
        )}
      </div>
    </div>
  );
};

export default SystemManagement;
