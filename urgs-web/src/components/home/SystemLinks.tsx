import React, { useEffect, useState } from 'react';
import { Shield, BarChart2, FileText, Globe, Users, Database, Activity, Lock, AlertCircle } from 'lucide-react';
import { getIcon } from '../../utils/icons';

// IconMap removed, using dynamic icons from backend

interface SsoSystem {
  id: string;
  name: string;
  status: string;
  icon?: string;
}

interface AuthUser {
  ssoSystem?: string;
  roleName?: string;
  // other properties
}

const SystemLinks: React.FC = () => {
  const [systems, setSystems] = useState<SsoSystem[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false); // Added isAdmin state

  useEffect(() => {
    const token = localStorage.getItem('auth_token');
    const userStr = localStorage.getItem('auth_user');
    let user: AuthUser | null = null;
    let allowedSystems: string[] = [];

    if (userStr && userStr !== "undefined") {
      try {
        user = JSON.parse(userStr);
        if (user && user.roleName === 'admin') {
          setIsAdmin(true);
        }
        allowedSystems = user?.ssoSystem ? user.ssoSystem.split(',') : [];
      } catch (e) {
        console.error("Failed to parse user info in SystemLinks", e);
        // If parsing fails, treat as no user or no allowed systems
        user = null;
        allowedSystems = [];
      }
    }

    fetch('/api/system', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(async res => {
        if (res.status === 401) {
          localStorage.removeItem('auth_token');
          localStorage.removeItem('auth_user');
          window.location.href = '/login';
          throw new Error('Unauthorized');
        }
        if (!res.ok) {
          throw new Error(`Sso list failed: ${res.status}`);
        }
        try {
          return await res.json();
        } catch (e) {
          throw new Error('Invalid SSO JSON');
        }
      })
      .then(data => {
        const filtered = data.filter((sys: SsoSystem) => allowedSystems.includes(sys.name));
        setSystems(filtered);
        setLoading(false);
      })
      .catch(err => {
        console.error('Failed to load systems', err);
        setSystems([]);
        setLoading(false);
      });
  }, []);

  const handleJump = async (id: string, name: string) => {
    try {
      const token = localStorage.getItem('auth_token');
      const res = await fetch(`/api/system/${id}/jump`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.status === 401) {
        window.location.href = '/login';
        return;
      }
      if (!res.ok) throw new Error('Jump failed');
      const data = await res.json();
      // Open in new tab
      window.open(data.targetUrl, '_blank');
    } catch (err) {
      alert(`无法跳转到 ${name}，请检查网络或联系管理员`);
    }
  };

  if (loading) {
    return (
      <div className="bg-white pt-6 pb-8 px-6 rounded-xl shadow-sm border border-slate-200 animate-pulse">
        <div className="h-8 bg-slate-100 rounded w-1/3 mb-8"></div>
        <div className="flex gap-8 overflow-hidden">
          {[1, 2, 3, 4, 5].map(i => (
            <div key={i} className="flex flex-col items-center gap-3">
              <div className="w-12 h-12 bg-slate-100 rounded-full"></div>
              <div className="w-16 h-4 bg-slate-100 rounded"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white pt-6 pb-8 px-6 rounded-xl shadow-sm border border-slate-200">
      <div className="flex items-center justify-between mb-8 border-b border-slate-100 pb-4">
        <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2">
          <div className="p-1.5 bg-red-100 rounded-md">
            <Globe className="w-5 h-5 text-red-600" />
          </div>
          系统跳转区 (System Navigation)
        </h2>
        <span className="text-xs font-medium text-slate-500 bg-slate-100 px-3 py-1.5 rounded-full border border-slate-200">
          已接入: <span className="text-slate-900 font-bold">{systems.length}</span>
        </span>
      </div>

      {/* Apple-style Navigation Bar */}
      <div className="w-full overflow-x-auto custom-scrollbar pb-2">
        <div className="flex items-start justify-between min-w-max md:min-w-0 gap-8 px-4">
          {systems.map((link) => {
            const Icon = getIcon(link.icon);
            const isMaintenance = link.status === 'maintenance';
            const isInactive = link.status === 'inactive';

            return (
              <div
                key={link.id}
                onClick={() => !isMaintenance && !isInactive && handleJump(link.id, link.name)}
                className={`
                  group flex flex-col items-center gap-3 w-20 md:w-24 transition-all duration-300
                  ${(isMaintenance || isInactive)
                    ? 'cursor-not-allowed opacity-60 grayscale'
                    : 'cursor-pointer hover:-translate-y-1'
                  }
                `}
              >
                {/* Icon Container */}
                <div className={`
                    relative flex items-center justify-center w-12 h-12 rounded-full transition-all duration-300
                    ${(isMaintenance || isInactive) ? 'bg-slate-100' : 'group-hover:bg-slate-50'}
                `}>
                  <Icon
                    strokeWidth={1.5} // Thinner stroke for elegant Apple look
                    className={`
                            w-8 h-8 transition-colors duration-300
                            ${(isMaintenance || isInactive)
                        ? 'text-slate-400'
                        : 'text-slate-600 group-hover:text-red-600'
                      }
                        `}
                  />
                  {/* Status Dot */}
                  {link.status !== 'active' && (
                    <div className={`
                            absolute top-0 right-0 w-3 h-3 rounded-full border-2 border-white flex items-center justify-center
                            ${link.status === 'maintenance' ? 'bg-amber-400' : 'bg-slate-400'}
                        `}>
                    </div>
                  )}
                </div>

                {/* Label */}
                <div className="text-center">
                  <h3 className={`
                        text-xs font-medium leading-tight transition-colors duration-300
                        ${(isMaintenance || isInactive)
                      ? 'text-slate-400'
                      : 'text-slate-600 group-hover:text-slate-900'
                    }
                    `}>
                    {link.name}
                  </h3>
                  {/* Status Text */}
                  {isMaintenance && (
                    <span className="text-[10px] text-amber-600 block mt-1">维护中</span>
                  )}
                  {isInactive && (
                    <span className="text-[10px] text-slate-400 block mt-1">已停用</span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default SystemLinks;
