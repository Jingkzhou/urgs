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
  system?: string;
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
        allowedSystems = user?.system ? user.system.split(',') : [];
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

      {/* Horizontal Scroll Layout */}
      <div className="w-full overflow-x-auto custom-scrollbar pb-4 -mx-2 px-2">
        <div className="flex flex-nowrap gap-3">
          {systems.map((link) => {
            const Icon = getIcon(link.icon);
            const isMaintenance = link.status === 'maintenance';
            const isInactive = link.status === 'inactive';
            const isDisabled = isMaintenance || isInactive;

            return (
              <div
                key={link.id}
                onClick={() => !isDisabled && handleJump(link.id, link.name)}
                className={`
                  group relative flex flex-col p-3 rounded-xl border transition-all duration-300 min-w-[160px] w-40 shrink-0
                  ${isDisabled
                    ? 'bg-slate-50 border-slate-100 cursor-not-allowed grayscale'
                    : 'bg-white border-slate-200 cursor-pointer hover:shadow-lg hover:shadow-red-500/5 hover:-translate-y-1 hover:border-red-100 active:scale-[0.97]'
                  }
                `}
              >
                {/* Background Glow on Hover */}
                {!isDisabled && (
                  <div className="absolute inset-0 bg-gradient-to-br from-red-50/30 to-transparent opacity-0 group-hover:opacity-100 transition-opacity rounded-xl duration-500" />
                )}

                <div className="relative flex items-start justify-between mb-2">
                  <div className={`
                    flex items-center justify-center w-8 h-8 rounded-lg transition-all duration-300
                    ${isDisabled
                      ? 'bg-slate-200 text-slate-400'
                      : 'bg-red-50 text-red-600 group-hover:bg-red-600 group-hover:text-white shadow-sm'
                    }
                  `}>
                    <Icon strokeWidth={2} className="w-5 h-5" />
                  </div>

                  {link.status !== 'active' && (
                    <div className={`
                      flex items-center gap-1 px-1.5 py-0.5 rounded-md text-[9px] font-bold
                      ${link.status === 'maintenance'
                        ? 'bg-amber-50 text-amber-600 border border-amber-100'
                        : 'bg-slate-100 text-slate-500 border border-slate-200'
                      }
                    `}>
                      <div className={`w-1 h-1 rounded-full ${link.status === 'maintenance' ? 'bg-amber-500 animate-pulse' : 'bg-slate-400'}`} />
                      {link.status === 'maintenance' ? '维护' : '停用'}
                    </div>
                  )}
                </div>

                <div className="relative">
                  <h3 className={`
                    text-sm font-bold truncate transition-colors duration-300
                    ${isDisabled ? 'text-slate-400' : 'text-slate-800 group-hover:text-red-700'}
                  `}>
                    {link.name}
                  </h3>
                  <p className={`
                    text-[10px] mt-0.5 line-clamp-1 transition-colors duration-300
                    ${isDisabled ? 'text-slate-300' : 'text-slate-400'}
                  `}>
                    进入系统办理业务
                  </p>
                </div>

                <div className={`
                  flex items-center gap-0.5 mt-2.5 text-[9px] font-extrabold transition-all duration-300
                  ${isDisabled ? 'hidden' : 'text-red-600 opacity-0 group-hover:opacity-100 translate-x-[-4px] group-hover:translate-x-0'}
                `}>
                  <span>进入</span>
                  <svg className="w-2.5 h-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M14 5l7 7m0 0l-7 7m7-7H3" />
                  </svg>
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
