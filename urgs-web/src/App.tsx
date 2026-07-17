import React, { useEffect, useState } from 'react';
import { hasPermission } from './utils/permission';
import { LayoutDashboard, Bell, UserCircle, LogOut, Settings, PanelTop, PanelLeft, Megaphone, Database, GitBranch, Activity, Lock, User, Sparkles, Award, BookOpen, ChevronDown, Wrench, BriefcaseBusiness, Code2 } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import Login from './components/Login';
import Dashboard from './components/home/Dashboard';
import SystemManagement from './components/SystemManagement';
import AnnouncementManagement from './components/announcement/AnnouncementManagement';
import VersionManagement from './components/VersionManagement';
import MetadataManagement from './components/MetadataManagement';
import OpsManagement from './components/OpsManagement';
import ChangePasswordModal from './components/ChangePasswordModal';
import ChatWidget from './components/home/ChatWidget';
import BasicInfo from './components/BasicInfo';
import ArkPage from './components/ark/ArkPage';
import KnowledgeCenter from './components/knowledge/KnowledgeCenter';
import MarketplacePage from './components/marketplace/MarketplacePage';
import ToolsPage from './components/tools/ToolsPage';
import { DashboardViewDefinition, DashboardViewKey, dashboardViewDefinitions } from './components/home/dashboardViews';
import { LOGO_URL } from './constants';
import { resolveServiceUrl } from './config';

const NAV_ITEMS = [
    { id: 'dashboard', label: '工作台', icon: LayoutDashboard, permission: 'dashboard' },
    { id: 'ark', label: 'Ark (方舟)', icon: Sparkles, permission: 'ark' },
    { id: 'announcement', label: '公告', icon: Megaphone, permission: 'announcement' },
    { id: 'version', label: '版本', icon: GitBranch, permission: 'version' },
    { id: 'marketplace', label: '任务中心', icon: Award, permission: 'marketplace' },
    { id: 'tools', label: '工具', icon: Wrench, permission: 'tools' },
    { id: 'metadata', label: '数据', icon: Database, permission: 'metadata' },
    { id: 'ops', label: '运维', icon: Activity, permission: 'ops' },
    { id: 'knowledge', label: '知识中心', icon: BookOpen, permission: 'knowledge' },
    { id: 'sys', label: '系统管理', icon: Settings, permission: 'sys' },
];

const dashboardViewIcons: Record<DashboardViewKey, React.ReactNode> = {
    business: <BriefcaseBusiness size={15} strokeWidth={2.5} />,
    dev: <Code2 size={15} strokeWidth={2.5} />,
    ops: <Activity size={15} strokeWidth={2.5} />,
};

const App: React.FC = () => {
    const initialToken = typeof localStorage !== 'undefined' ? localStorage.getItem('auth_token') : null;
    const initialUser = (() => {
        const storedUser = typeof localStorage !== 'undefined' ? localStorage.getItem('auth_user') : null;
        if (storedUser && storedUser !== 'undefined') {
            try {
                return JSON.parse(storedUser);
            } catch (e) {
                console.error("Failed to parse user info", e);
                localStorage.removeItem('auth_user');
            }
        }
        return null;
    })();

    const [isAuthenticated, setIsAuthenticated] = useState(!!initialToken);
    const [userInfo, setUserInfo] = useState<{
        id?: string;
        name?: string;
        empId?: string;
        roleName?: string;
        roleId?: number; 
        avatarUrl?: string;
        system?: string;
        orgName?: string;
        phone?: string;
    } | null>(initialUser);
    const [layoutMode, setLayoutMode] = useState<'sidebar' | 'topbar'>(() => {
        if (typeof window !== 'undefined') {
            const savedMode = localStorage.getItem('user_layout_preference');
            if (savedMode === 'sidebar' || savedMode === 'topbar') {
                return savedMode;
            }
        }
        return 'sidebar';
    });
    const [activeTab, setActiveTab] = useState('dashboard');
    const [showUserMenu, setShowUserMenu] = useState(false);
    const [showMoreNavMenu, setShowMoreNavMenu] = useState(false);
    const [changePasswordVisible, setChangePasswordVisible] = useState(false);

    const userMenuRef = React.useRef<HTMLDivElement>(null);
    const moreMenuRef = React.useRef<HTMLDivElement>(null);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (showUserMenu && userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
                setShowUserMenu(false);
            }
            if (showMoreNavMenu && moreMenuRef.current && !moreMenuRef.current.contains(event.target as Node)) {
                setShowMoreNavMenu(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [showUserMenu, showMoreNavMenu]);

    useEffect(() => {
        if (isAuthenticated) {
            setShowUserMenu(false);
        }
    }, [isAuthenticated]);

    useEffect(() => {
        if (typeof window !== 'undefined') {
            localStorage.setItem('user_layout_preference', layoutMode);
        }
    }, [layoutMode]);

    useEffect(() => {
        const params = new URLSearchParams(window.location.search);
        const ssoLoginToken = params.get('sso_login_token');
        if (ssoLoginToken) {
            const target = params.get('sso_target');
            params.delete('sso_login_token');
            params.delete('sso_target');
            const cleanUrl = `${window.location.pathname}${params.toString() ? `?${params.toString()}` : ''}${window.location.hash}`;
            window.history.replaceState({}, document.title, cleanUrl);

            fetch(`/api/auth/profile?token=${encodeURIComponent(ssoLoginToken)}`)
                .then(res => {
                    if (!res.ok) {
                        throw new Error(`SSO profile failed ${res.status}`);
                    }
                    return res.json();
                })
                .then(async data => {
                    const user = {
                        id: data.id,
                        empId: data.empId,
                        name: data.name,
                        roleName: data.roleName,
                        roleId: data.roleId,
                        system: data.system,
                        orgName: data.orgName,
                        phone: data.phone,
                        avatarUrl: data.avatarUrl,
                    };
                    localStorage.setItem('auth_token', data.token);
                    localStorage.setItem('auth_user', JSON.stringify(user));
                    setUserInfo(user);
                    await fetchPermissions(data.token);
                    setIsAuthenticated(true);
                    if (target) {
                        window.location.hash = target.startsWith('#/') ? target : `#/${target.replace(/^\//, '')}`;
                    }
                })
                .catch(err => {
                    console.error('SSO login error', err);
                    handleLogout();
                });
        }

        if (!ssoLoginToken && initialToken) {
            fetchPermissions(initialToken);
        }

        const handleHashChange = () => {
            const hash = window.location.hash;
            const path = hash.split('?')[0].replace('#/', ''); 
            const navIds = NAV_ITEMS.map(n => n.id);
            const topLevelPath = path.split('/')[0];
            if (navIds.includes(path)) {
                setActiveTab(path);
            } else if (navIds.includes(topLevelPath)) {
                setActiveTab(topLevelPath);
            } else if (path === 'basic_info') {
                setActiveTab('basic_info');
            } else if (path === '' || path === 'dashboard') {
                setActiveTab('dashboard');
            }
        };

        handleHashChange();
        window.addEventListener('hashchange', handleHashChange);

        const handleStorageChange = () => {
            const storedUser = localStorage.getItem('auth_user');
            if (storedUser) {
                setUserInfo(JSON.parse(storedUser));
            }
        };
        window.addEventListener('storage', handleStorageChange);

        return () => {
            window.removeEventListener('hashchange', handleHashChange);
            window.removeEventListener('storage', handleStorageChange);
        };
    }, []);

    const fetchPermissions = async (token: string) => {
        try {
            const res = await fetch('/api/users/permissions', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const perms = await res.json();
                localStorage.setItem('user_permissions', JSON.stringify(perms));
            } else if (res.status === 401) {
                handleLogout();
            }
        } catch (err) {
            console.error(err);
        }
    };

    const handleLogin = async (token: string, user: any) => {
        localStorage.setItem('auth_token', token);
        localStorage.setItem('auth_user', JSON.stringify(user));
        setUserInfo(user);
        await fetchPermissions(token);
        setIsAuthenticated(true);
    };

    const handleLogout = () => {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('auth_user');
        setIsAuthenticated(false);
        setUserInfo(null);
        setShowUserMenu(false);
    };

    const handleChangePassword = () => {
        setChangePasswordVisible(true);
        setShowUserMenu(false);
    };

    const allowedDashboardViews = dashboardViewDefinitions.filter(view => hasPermission(view.permission));
    const handleDashboardViewSelect = (view: DashboardViewDefinition) => {
        localStorage.setItem('urgs_dashboard_view', view.key);
        setActiveTab('dashboard');
        window.location.hash = `#/dashboard?view=${view.key}`;
    };

    if (!isAuthenticated) {
        return <Login onLogin={handleLogin} />;
    }

    const renderUserMenuContent = () => (
        <>
            <div className="p-4 mb-2 bg-slate-50/50 rounded-2xl flex flex-col gap-1 md:hidden">
                <p className="text-[12px] font-black text-slate-800">{userInfo?.name}</p>
                <p className="text-[9px] text-slate-400 font-bold uppercase tracking-widest">{userInfo?.roleName}</p>
            </div>

            <div className="px-2 py-2 mb-1">
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 px-2">导航布局偏好</p>
                <div className="flex items-center gap-1 bg-slate-100/50 p-1 rounded-xl">
                    <button
                        onClick={() => { setLayoutMode('topbar'); setShowUserMenu(false); }}
                        className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-lg text-xs font-bold transition-all ${layoutMode === 'topbar'
                            ? 'bg-white text-red-600 shadow-sm border border-slate-100'
                            : 'text-slate-500 hover:text-slate-700 hover:bg-slate-200/50'
                            }`}
                    >
                        <PanelTop size={14} strokeWidth={2.5} /> 顶部
                    </button>
                    <button
                        onClick={() => { setLayoutMode('sidebar'); setShowUserMenu(false); }}
                        className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-lg text-xs font-bold transition-all ${layoutMode === 'sidebar'
                            ? 'bg-white text-red-600 shadow-sm border border-slate-100'
                            : 'text-slate-500 hover:text-slate-700 hover:bg-slate-200/50'
                            }`}
                    >
                        <PanelLeft size={14} strokeWidth={2.5} /> 侧边
                    </button>
                </div>
            </div>

            <div className="h-px bg-slate-100/80 my-1 mx-2"></div>

            {hasPermission('profile') && <button
                onClick={() => { setActiveTab('basic_info'); window.location.hash = '#/basic_info'; setShowUserMenu(false); }}
                className="w-full flex items-center gap-4 px-4 py-3 text-[11px] font-black uppercase tracking-[0.15em] text-slate-500 hover:text-red-600 hover:bg-red-50/50 rounded-xl transition-all group"
            >
                <User size={16} strokeWidth={2.5} className="group-hover:scale-110 transition-transform" />
                <span>个人信息</span>
            </button>}

            {hasPermission('profile:password') && <button
                onClick={handleChangePassword}
                className="w-full flex items-center gap-4 px-4 py-3 text-[11px] font-black uppercase tracking-[0.15em] text-slate-500 hover:text-red-600 hover:bg-red-50/50 rounded-xl transition-all group"
            >
                <Lock size={16} strokeWidth={2.5} className="group-hover:scale-110 transition-transform" />
                <span>修改密码</span>
            </button>}

            <div className="h-px bg-slate-100 my-2 mx-2"></div>

            <button
                onClick={handleLogout}
                className="w-full flex items-center gap-4 px-4 py-3 text-[11px] font-black uppercase tracking-[0.15em] text-red-600 hover:bg-red-50 rounded-xl transition-all group"
            >
                <LogOut size={16} strokeWidth={3} className="group-hover:translate-x-1 transition-transform" />
                <span>退出登录</span>
            </button>
        </>
    );

    return (
        <div className={`flex h-screen bg-slate-50 ${layoutMode === 'topbar' ? 'flex-col' : 'flex-row'}`}>
            {layoutMode === 'sidebar' && (
                <aside
                    className="m-4 mr-0 flex w-[72px] shrink-0 flex-col rounded-[1.5rem] border border-slate-200/70 bg-white/85 text-slate-800 shadow-[0_24px_70px_-38px_rgba(15,23,42,0.45)] backdrop-blur-2xl z-[120] relative overflow-visible"
                >
                    <div className="flex h-20 shrink-0 items-center justify-center border-b border-slate-100">
                        <button
                            onClick={() => { setActiveTab('dashboard'); window.location.hash = '#/dashboard'; }}
                            className="flex h-14 w-14 items-center justify-center p-0.5 transition-opacity hover:opacity-80"
                            aria-label="返回工作台"
                        >
                            <img src="/favicon_large.png" alt="Bank of Jilin" className="max-h-full max-w-full object-contain" />
                        </button>
                    </div>

                    <nav className="flex-1 space-y-2.5 overflow-y-auto px-2 py-5 [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]">
                        {NAV_ITEMS.filter(item => hasPermission(item.permission)).map((item) => {
                            const navItem = (
                                <NavItem
                                    icon={<item.icon size={16} />}
                                    label={item.label}
                                    active={activeTab === item.id}
                                    onClick={() => { setActiveTab(item.id); window.location.hash = '#/' + item.id; }}
                                />
                            );

                            return item.id === 'dashboard' && allowedDashboardViews.length > 1 ? (
                                <DashboardViewMenu key={item.id} views={allowedDashboardViews} onSelect={handleDashboardViewSelect} placement="sidebar">
                                    {navItem}
                                </DashboardViewMenu>
                            ) : <React.Fragment key={item.id}>{navItem}</React.Fragment>;
                        })}
                    </nav>

                    <div className="flex shrink-0 flex-col items-center gap-3 border-t border-slate-100 px-2 py-4">
                        <button className="group relative flex h-10 w-10 items-center justify-center rounded-2xl text-slate-400 transition-all hover:bg-slate-100 hover:text-red-500">
                            <Bell size={17} strokeWidth={2.4} className="transition-transform group-hover:rotate-12" />
                            <span className="absolute right-2.5 top-2.5 h-2 w-2 rounded-full border-2 border-white bg-red-500 shadow-sm"></span>
                        </button>

                        <div className="relative w-full" ref={userMenuRef}>
                            <button
                                onClick={() => setShowUserMenu(!showUserMenu)}
                                className={`group relative mx-auto flex h-10 w-10 items-center justify-center overflow-hidden rounded-2xl border transition-all duration-300 ${
                                    showUserMenu ? 'bg-red-50 border-red-200' : 'bg-slate-50 border-slate-100 hover:bg-slate-100 hover:border-slate-200'
                                }`}
                            >
                                {userInfo?.avatarUrl ? (
                                    <img src={resolveServiceUrl(userInfo.avatarUrl)} alt="Avatar" className="h-full w-full object-cover grayscale-[0.5] transition-all duration-700 group-hover:grayscale-0" />
                                ) : (
                                    <UserCircle size={22} className="text-slate-400" />
                                )}
                                <div className="absolute bottom-1 right-1 h-2 w-2 rounded-full border-2 border-white bg-green-500"></div>
                            </button>

                            <AnimatePresence>
                                {showUserMenu && (
                                    <motion.div
                                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                        className="absolute bottom-0 left-[calc(100%+14px)] w-60 rounded-[2rem] border border-white/60 bg-white/95 p-2 shadow-[0_40px_80px_-15px_rgba(0,0,0,0.2)] backdrop-blur-3xl z-[220]"
                                    >
                                        <div className="absolute inset-0 bg-gradient-to-br from-red-500/[0.02] to-transparent pointer-events-none rounded-[2rem]"></div>
                                        <div className="relative z-10">
                                            {renderUserMenuContent()}
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>
                    </div>
                </aside>
            )}

            <div className="flex-1 flex flex-col min-w-0 overflow-hidden relative">
                {layoutMode === 'topbar' && (
                    <header className="h-[72px] bg-white/92 backdrop-blur-xl border-b border-slate-200/80 px-6 xl:px-8 z-[100] relative shrink-0 shadow-[0_18px_45px_-38px_rgba(15,23,42,0.55)]">
                        <div className="h-full flex items-center justify-between gap-6">
                            <div className="flex items-center gap-7 min-w-0">
                                <div className="flex items-center gap-3 shrink-0">
                                    <img src={LOGO_URL} alt="Bank Logo" className="w-36 h-auto max-w-[9rem] object-contain" />
                                    <div className="hidden xl:flex h-7 w-px bg-slate-200"></div>
                                    <span className="hidden xl:inline-flex text-[11px] font-black text-slate-500 uppercase tracking-[0.18em]">ARK / PORTAL</span>
                                </div>

                                <nav className="hidden lg:flex items-center gap-1 relative min-w-0" ref={moreMenuRef}>
                                    {(() => {
                                        const allowedItems = NAV_ITEMS.filter(item => hasPermission(item.permission));
                                        if (allowedItems.length === 0) return null;

                                        const activeIndex = allowedItems.findIndex(item => item.id === activeTab);
                                        const MAX_VISIBLE = 6; 
                                        let visibleItems = allowedItems.slice(0, MAX_VISIBLE);
                                        let hiddenItems = allowedItems.slice(MAX_VISIBLE);

                                        if (activeIndex >= MAX_VISIBLE) {
                                            const activeItem = allowedItems[activeIndex];
                                            const itemToHide = visibleItems[MAX_VISIBLE - 1];
                                            visibleItems[MAX_VISIBLE - 1] = activeItem;
                                            hiddenItems = hiddenItems.map(item => item.id === activeItem.id ? itemToHide : item);
                                        }

                                        return (
                                            <>
                                                {visibleItems.map((item) => {
                                                    const isActive = activeTab === item.id;
                                                    const navItem = (
                                                        <button
                                                            onClick={() => { setActiveTab(item.id); window.location.hash = '#/' + item.id; }}
                                                            className={`relative flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-[12px] font-black uppercase tracking-wider transition-all duration-300 z-10
                                                            ${isActive ? 'text-red-600' : 'text-slate-500 hover:text-slate-900 hover:bg-slate-100/70'}
                                                        `}
                                                            >
                                                                {isActive && (
                                                                    <motion.div
                                                                        layoutId="topNavTab"
                                                                        className="absolute inset-0 bg-red-50/90 rounded-xl z-[-1]"
                                                                        transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                                                                    />
                                                                )}
                                                                <item.icon size={16} strokeWidth={isActive ? 3 : 2} />
                                                                <span className="whitespace-nowrap">{item.label}</span>
                                                        </button>
                                                    );

                                                    return item.id === 'dashboard' && allowedDashboardViews.length > 1 ? (
                                                        <DashboardViewMenu key={item.id} views={allowedDashboardViews} onSelect={handleDashboardViewSelect} placement="topbar">
                                                            {navItem}
                                                        </DashboardViewMenu>
                                                    ) : <React.Fragment key={item.id}>{navItem}</React.Fragment>;
                                                })}

                                                        {hiddenItems.length > 0 && (
                                                            <div className="relative z-20">
                                                                <button
                                                                    onClick={() => setShowMoreNavMenu(!showMoreNavMenu)}
                                                                    className={`flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-[12px] font-black uppercase tracking-wider transition-all duration-300
                                                                    ${showMoreNavMenu ? 'bg-slate-100 text-slate-900' : 'text-slate-500 hover:text-slate-900 hover:bg-slate-100/70'}
                                                                `}
                                                                >
                                                                    <span>更多应用</span>
                                                                    <motion.div
                                                                        animate={{ rotate: showMoreNavMenu ? 180 : 0 }}
                                                                        transition={{ type: 'spring', stiffness: 200, damping: 20 }}
                                                                    >
                                                                        <ChevronDown size={14} strokeWidth={2.5} />
                                                                    </motion.div>
                                                                </button>

                                                                <AnimatePresence>
                                                                    {showMoreNavMenu && (
                                                                        <motion.div
                                                                            initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                                                            animate={{ opacity: 1, y: 0, scale: 1 }}
                                                                            exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                                                            transition={{ type: "spring", bounce: 0.3, duration: 0.5 }}
                                                                            className="absolute right-0 top-full mt-3 w-56 bg-white/95 backdrop-blur-2xl rounded-2xl shadow-[0_24px_50px_-18px_rgba(15,23,42,0.28)] border border-slate-200/80 p-2 z-50 grid grid-cols-1 gap-1"
                                                                        >
                                                                            {hiddenItems.map((item) => (
                                                                                <button
                                                                                    key={item.id}
                                                                                    onClick={() => {
                                                                                        setActiveTab(item.id);
                                                                                        window.location.hash = '#/' + item.id;
                                                                                        setShowMoreNavMenu(false);
                                                                                    }}
                                                                                    className="flex items-center gap-3 w-full px-4 py-3 rounded-xl text-left transition-all hover:bg-slate-50 hover:text-red-600 group"
                                                                                >
                                                                                    <div className="p-1.5 rounded-lg bg-slate-100/80 text-slate-500 group-hover:bg-red-50 group-hover:text-red-600 transition-colors">
                                                                                        <item.icon size={16} strokeWidth={2.5} />
                                                                                    </div>
                                                                                    <span className="text-[13px] font-bold text-slate-700 group-hover:text-red-600">{item.label}</span>
                                                                                </button>
                                                                            ))}
                                                                        </motion.div>
                                                                    )}
                                                                </AnimatePresence>
                                                            </div>
                                                        )}
                                                    </>
                                                );
                                            })()}
                                        </nav>
                                    </div >

                                <div className="flex items-center gap-4 shrink-0 whitespace-nowrap">
                                    <button className="p-2.5 relative hover:bg-slate-100 rounded-xl text-slate-400 hover:text-red-500 transition-all group">
                                        <Bell size={20} strokeWidth={2.5} className="group-hover:rotate-12 transition-transform" />
                                        <span className="absolute top-2.5 right-2.5 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white shadow-sm"></span>
                                    </button>

                                    <div className="flex items-center gap-4 pl-4 border-l border-slate-200 min-w-0 flex-nowrap">
                                        <div className="text-right hidden xl:block min-w-0 max-w-36 shrink">
                                            <p className="text-[13px] font-black text-slate-800 tracking-tight leading-none mb-1 truncate">{userInfo?.name || '用户'}</p>
                                            <p className="text-[9px] text-slate-400 font-bold uppercase tracking-[0.15em] truncate">{userInfo?.roleName || 'System Admin'}</p>
                                        </div>

                                        <div className="relative shrink-0" ref={userMenuRef}>
                                            <button
                                                onClick={() => setShowUserMenu(!showUserMenu)}
                                                className={`group relative w-11 h-11 rounded-xl border transition-all duration-300 overflow-hidden flex items-center justify-center
                                                ${showUserMenu ? 'bg-red-50 border-red-200' : 'bg-slate-50 border-slate-100 hover:bg-slate-100 hover:border-slate-200'}
                                            `}
                                            >
                                                {userInfo?.avatarUrl ? (
                                                    <img src={resolveServiceUrl(userInfo.avatarUrl)} alt="Avatar" className="w-full h-full object-cover grayscale-[0.5] group-hover:grayscale-0 transition-all duration-700" />
                                                ) : (
                                                    <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-slate-100 to-slate-50 text-slate-400">
                                                        <UserCircle size={28} strokeWidth={1.5} />
                                                    </div>
                                                )}
                                                <div className="absolute bottom-1 right-1 w-2.5 h-2.5 bg-green-500 rounded-full border-2 border-white"></div>
                                            </button>

                                            <AnimatePresence>
                                                {showUserMenu && (
                                                    <motion.div
                                                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                                        className="absolute right-0 top-full mt-4 w-60 bg-white/95 backdrop-blur-2xl rounded-2xl shadow-[0_24px_50px_-18px_rgba(15,23,42,0.28)] border border-slate-200/80 p-2 z-[110] overflow-hidden"
                                                    >
                                                        {renderUserMenuContent()}
                                                    </motion.div>
                                                )}
                                            </AnimatePresence>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            </header>
                        )}

                        <main className="flex-1 overflow-y-auto p-4 lg:p-8 scroll-smooth bg-slate-50/50">
                            <div className="max-w-[98%] mx-auto h-full">
                                {activeTab === 'dashboard' && <Dashboard />}
                                {activeTab === 'ark' && <ArkPage />}
                                {activeTab === 'announcement' && <AnnouncementManagement />}
                                {activeTab === 'sys' && <SystemManagement />}
                                {activeTab === 'version' && <VersionManagement />}
                                {activeTab === 'metadata' && <MetadataManagement />}
                                {activeTab === 'ops' && <OpsManagement />}
                                {activeTab === 'tools' && <ToolsPage />}
                                {activeTab === 'knowledge' && <KnowledgeCenter />}
                                {activeTab === 'marketplace' && <MarketplacePage />}
                                {activeTab === 'basic_info' && hasPermission('profile') && <BasicInfo userInfo={userInfo} />}
                            </div>
                        </main>
                    </div>

                    <ChangePasswordModal
                        visible={changePasswordVisible}
                        onCancel={() => setChangePasswordVisible(false)}
                        onSuccess={() => {
                            setChangePasswordVisible(false);
                            handleLogout();
                        }}
                    />

                    <ChatWidget />
        </div>
    );
};

interface NavItemProps {
    icon: React.ReactNode;
    label: string;
    active?: boolean;
    onClick: () => void;
}

interface DashboardViewMenuProps {
    views: DashboardViewDefinition[];
    onSelect: (view: DashboardViewDefinition) => void;
    placement: 'sidebar' | 'topbar';
    children: React.ReactNode;
}

const DashboardViewMenu: React.FC<DashboardViewMenuProps> = ({ views, onSelect, placement, children }) => {
    const triggerRef = React.useRef<HTMLDivElement>(null);
    const closeTimerRef = React.useRef<number | null>(null);
    const [sidebarMenuOpen, setSidebarMenuOpen] = useState(false);
    const [sidebarMenuPosition, setSidebarMenuPosition] = useState({ left: 0, top: 0 });

    const clearCloseTimer = () => {
        if (closeTimerRef.current !== null) {
            window.clearTimeout(closeTimerRef.current);
            closeTimerRef.current = null;
        }
    };

    const openSidebarMenu = () => {
        clearCloseTimer();
        const rect = triggerRef.current?.getBoundingClientRect();
        if (rect) {
            setSidebarMenuPosition({ left: rect.right + 10, top: rect.top + rect.height / 2 });
            setSidebarMenuOpen(true);
        }
    };

    const closeSidebarMenu = () => {
        clearCloseTimer();
        closeTimerRef.current = window.setTimeout(() => setSidebarMenuOpen(false), 160);
    };

    useEffect(() => () => clearCloseTimer(), []);

    const menuContent = (
        <>
            <p className="px-2 py-1 text-[9px] font-black uppercase tracking-[0.16em] text-slate-400">首页切换</p>
            <div className="mt-1 space-y-1">
                {views.map(view => (
                    <button
                        key={view.key}
                        type="button"
                        onClick={() => onSelect(view)}
                        className="flex w-full items-center gap-2.5 rounded-xl px-2.5 py-2 text-left text-[11px] font-bold text-slate-600 transition-colors hover:bg-red-50 hover:text-red-600"
                    >
                        <span className="text-slate-400 transition-colors group-hover:text-red-500">{dashboardViewIcons[view.key]}</span>
                        <span>{view.label}</span>
                    </button>
                ))}
            </div>
        </>
    );

    if (placement === 'sidebar') {
        return (
            <div ref={triggerRef} className="relative" onMouseEnter={openSidebarMenu} onMouseLeave={closeSidebarMenu}>
                {children}
                {sidebarMenuOpen && typeof document !== 'undefined' && createPortal(
                    <div
                        className="group fixed z-[300] w-44 -translate-y-1/2 rounded-2xl border border-slate-200/80 bg-white/95 p-2 shadow-[0_24px_50px_-18px_rgba(15,23,42,0.28)] backdrop-blur-2xl"
                        style={sidebarMenuPosition}
                        onMouseEnter={openSidebarMenu}
                        onMouseLeave={closeSidebarMenu}
                    >
                        {menuContent}
                    </div>,
                    document.body,
                )}
            </div>
        );
    }

    return (
        <div className="group relative">
            {children}
            <div className="pointer-events-none absolute left-0 top-full z-[180] w-44 rounded-2xl border border-slate-200/80 bg-white/95 p-2 opacity-0 shadow-[0_24px_50px_-18px_rgba(15,23,42,0.28)] backdrop-blur-2xl transition-all duration-200 group-hover:pointer-events-auto group-hover:opacity-100">
                {menuContent}
            </div>
        </div>
    );
};

const NavItem: React.FC<NavItemProps> = ({ icon, label, active, onClick }) => (
    <button
        onClick={onClick}
        className={`group relative flex h-[62px] w-full flex-col items-center justify-center gap-1 rounded-xl px-1 text-center transition-all duration-300
        ${active ? 'text-red-600' : 'text-slate-500 hover:text-slate-900 hover:bg-slate-100/70'}
    `}
        title={label}
    >
        {active && (
            <motion.div
                layoutId="sidebarActivePill"
                className="absolute inset-x-0.5 inset-y-0 bg-white border border-red-100 shadow-sm rounded-xl z-[-1]"
                transition={{ type: "spring", bounce: 0.25, duration: 0.5 }}
            />
        )}

        <div className={`flex h-6 items-center justify-center transition-transform duration-300 ${active ? 'scale-105' : 'group-hover:scale-105'}`}>
            {icon}
        </div>

        <span className={`line-clamp-2 max-w-full text-[9px] font-bold leading-tight tracking-tight transition-all duration-300 ${active ? 'opacity-100' : 'opacity-75 group-hover:opacity-100'}`}>
            {label}
        </span>
    </button>
);

export default App;
