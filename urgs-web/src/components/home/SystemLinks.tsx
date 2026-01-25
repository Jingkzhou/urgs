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
    <div className="relative bg-white/70 backdrop-blur-md pt-6 pb-8 px-6 rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200/50 overflow-hidden">
      {/* Decorative Top Line */}
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-red-500 via-red-600 to-transparent opacity-80" />

      <div className="flex items-center justify-between mb-8 border-b border-slate-100/50 pb-5">
        <h2 className="text-xl font-extrabold text-slate-800 flex items-center gap-3">
          <div className="p-2 bg-gradient-to-br from-red-50 to-red-100/50 rounded-xl border border-red-100 shadow-sm transition-transform duration-500 group-hover:rotate-12">
            <Globe className="w-5 h-5 text-red-600" />
          </div>
          <div className="flex flex-col">
            <span className="tracking-tight">系统跳转区</span>
            <span className="text-[10px] text-slate-400 font-medium uppercase tracking-widest mt-0.5">System Navigation</span>
          </div>
        </h2>
        <div className="flex items-center gap-2 bg-slate-50/80 px-4 py-2 rounded-xl border border-slate-100 shadow-inner">
          <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_8px_rgba(16,185,129,0.5)]" />
          <span className="text-[11px] font-bold text-slate-500">
            已接入: <span className="text-slate-900 ml-1 font-black">{systems.length}</span>
          </span>
        </div>
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
                  group relative flex flex-col p-4 rounded-2xl border transition-all duration-500 min-w-[170px] w-44 shrink-0 overflow-hidden
                  ${isDisabled
                    ? 'bg-slate-50/50 border-slate-100 cursor-not-allowed grayscale'
                    : 'bg-white border-slate-200/60 cursor-pointer hover:shadow-[0_15px_35px_-5px_rgba(239,68,68,0.08)] hover:-translate-y-2 hover:border-red-200/50 active:scale-[0.98]'
                  }
                `}
              >
                {/* Background Glow on Hover */}
                {!isDisabled && (
                  <div className="absolute -inset-1 bg-gradient-to-br from-red-50/50 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-700" />
                )}

                <div className="relative flex items-start justify-between mb-4">
                  <div className={`
                    flex items-center justify-center w-10 h-10 rounded-xl transition-all duration-500
                    ${isDisabled
                      ? 'bg-slate-200 text-slate-400'
                      : 'bg-red-50/80 text-red-600 group-hover:bg-red-600 group-hover:text-white group-hover:rotate-6 group-hover:shadow-lg group-hover:shadow-red-500/20'
                    }
                  `}>
                    <Icon strokeWidth={2.5} className="w-5 h-5" />
                  </div>

                  {link.status !== 'active' && (
                    <div className={`
                      flex items-center gap-1.5 px-2 py-0.5 rounded-lg text-[9px] font-bold uppercase tracking-wider
                      ${link.status === 'maintenance'
                        ? 'bg-amber-50 text-amber-600 border border-amber-100'
                        : 'bg-slate-100 text-slate-500 border border-slate-200'
                      }
                    `}>
                      <div className={`w-1 h-1 rounded-full ${link.status === 'maintenance' ? 'bg-amber-500 animate-pulse' : 'bg-slate-400'}`} />
                      {link.status === 'maintenance' ? '维护中' : '已停用'}
                    </div>
                  )}
                </div>

                <div className="relative mt-auto">
                  <h3 className={`
                    text-[15px] font-black truncate transition-colors duration-300 tracking-tight
                    ${isDisabled ? 'text-slate-400' : 'text-slate-800 group-hover:text-red-700'}
                  `}>
                    {link.name}
                  </h3>
                  <p className={`
                    text-[11px] mt-1 line-clamp-1 transition-colors duration-300 font-medium
                    ${isDisabled ? 'text-slate-300' : 'text-slate-500 group-hover:text-slate-600'}
                  `}>
                    点击进入办理业务
                  </p>
                </div>

                <div className={`
                  flex items-center gap-1 mt-4 text-[10px] font-black transition-all duration-500
                  ${isDisabled ? 'hidden' : 'text-red-600 opacity-0 group-hover:opacity-100 -translate-x-2 group-hover:translate-x-0'}
                `}>
                  <span className="uppercase tracking-widest">Entry</span>
                  <svg className="w-3 h-3 transition-transform duration-300 group-hover:translate-x-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
