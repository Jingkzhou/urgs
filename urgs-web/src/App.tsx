import React, { useEffect, useState } from 'react';
import { hasPermission } from './utils/permission';
import { LayoutDashboard, Menu, Bell, Search, UserCircle, LogOut, Settings, PanelTop, PanelLeft, Megaphone, Timer, Database, GitBranch, Activity, Lock, Palette, User, Sparkles, Award } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Login from './components/Login';
import Dashboard from './components/home/Dashboard';
import SystemManagement from './components/SystemManagement';
import AnnouncementManagement from './components/announcement/AnnouncementManagement';
import SqlConsole from './components/SqlConsole';
import VersionManagement from './components/VersionManagement';
import MetadataManagement from './components/MetadataManagement';
import OpsManagement from './components/OpsManagement';
import ChangePasswordModal from './components/ChangePasswordModal';
import ChatWidget from './components/home/ChatWidget';
import BasicInfo from './components/BasicInfo';
import ArkPage from './components/ark/ArkPage';
import KnowledgeCenter from './components/knowledge/KnowledgeCenter';
import MarketplacePage from './components/marketplace/MarketplacePage';
import { LOGO_URL } from './constants';

const NAV_ITEMS = [
    { id: 'dashboard', label: '工作台', icon: LayoutDashboard, permission: 'dashboard' },
    { id: 'ark', label: 'Ark (方舟)', icon: Sparkles, permission: 'ark' },
    { id: 'announcement', label: '公告', icon: Megaphone, permission: 'announcement' },
    { id: 'version', label: '版本', icon: GitBranch, permission: 'version' },
    { id: 'marketplace', label: '工作市场', icon: Award, permission: 'marketplace' },
    { id: 'metadata', label: '数据', icon: Database, permission: 'metadata' },
    { id: 'ops', label: '运维', icon: Activity, permission: 'ops' },
    { id: 'knowledge', label: '知识中心', icon: Database, permission: 'knowledge' },
    { id: 'sys', label: '系统管理', icon: Settings, permission: 'sys' },
];

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
        roleId?: number; // Added roleId
        avatarUrl?: string;
        system?: string;
    } | null>(initialUser);
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const [layoutMode, setLayoutMode] = useState<'sidebar' | 'topbar'>(() => {
        if (typeof window !== 'undefined') {
            const savedMode = localStorage.getItem('user_layout_preference');
            if (savedMode === 'sidebar' || savedMode === 'topbar') {
                return savedMode;
            }
        }
        return 'topbar';
    });
    const [activeTab, setActiveTab] = useState('dashboard');
    const [showUserMenu, setShowUserMenu] = useState(false);
    const [showMoreNavMenu, setShowMoreNavMenu] = useState(false);
    const [changePasswordVisible, setChangePasswordVisible] = useState(false);

    // Click outside handler for user menu
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
        // Use mousedown to capture the event before click (optional, but robust)
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

    // Save layout mode preference
    useEffect(() => {
        if (typeof window !== 'undefined') {
            localStorage.setItem('user_layout_preference', layoutMode);
        }
    }, [layoutMode]);

    useEffect(() => {
        if (initialToken) {
            fetchPermissions(initialToken);
        }

        // Basic Hash Routing
        const handleHashChange = () => {
            const hash = window.location.hash;
            const path = hash.split('?')[0].replace('#/', ''); // #/announcement -> announcement

            const navIds = NAV_ITEMS.map(n => n.id);
            if (navIds.includes(path)) {
                setActiveTab(path);
            } else if (path === '' || path === 'dashboard') {
                setActiveTab('dashboard');
            }
        };

        // Check on mount
        handleHashChange();

        window.addEventListener('hashchange', handleHashChange);

        // Listen for user info updates
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

    const handleMenuSettings = () => {
        console.log("Menu Settings clicked");
        setShowUserMenu(false);
    };

    const handleChangePassword = () => {
        setChangePasswordVisible(true);
        setShowUserMenu(false);
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

            {/* Layout Mode Toggles */}
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

            <button
                onClick={() => { setActiveTab('basic_info'); setShowUserMenu(false); }}
                className="w-full flex items-center gap-4 px-4 py-3 text-[11px] font-black uppercase tracking-[0.15em] text-slate-500 hover:text-red-600 hover:bg-red-50/50 rounded-xl transition-all group"
            >
                <User size={16} strokeWidth={2.5} className="group-hover:scale-110 transition-transform" />
                <span>个人信息</span>
            </button>

            <button
                onClick={handleChangePassword}
                className="w-full flex items-center gap-4 px-4 py-3 text-[11px] font-black uppercase tracking-[0.15em] text-slate-500 hover:text-red-600 hover:bg-red-50/50 rounded-xl transition-all group"
            >
                <Lock size={16} strokeWidth={2.5} className="group-hover:scale-110 transition-transform" />
                <span>修改密码</span>
            </button>

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
                    className={`${sidebarOpen ? 'w-64' : 'w-24'
                        } m-4 mr-0 rounded-[2.5rem] bg-white/70 backdrop-blur-3xl border border-white/40 text-slate-800 transition-all duration-500 flex flex-col shadow-[0_40px_100px_-20px_rgba(0,0,0,0.1)] z-20 shrink-0 relative`}
                >
                    <div className="h-24 flex items-center justify-between px-6 border-b border-slate-100/30 bg-white/10 overflow-hidden shrink-0">
                        {sidebarOpen && (
                            <motion.div
                                initial={{ opacity: 0, x: -20 }}
                                animate={{ opacity: 1, x: 0 }}
                                className="flex flex-col items-center pl-1"
                            >
                                <img src={LOGO_URL} alt="Bank of Jilin" className="h-7 object-contain brightness-110" />
                            </motion.div>
                        )}
                        <button
                            onClick={() => setSidebarOpen(!sidebarOpen)}
                            className={`p-3 bg-slate-100/50 hover:bg-white rounded-[1.25rem] text-slate-500 hover:text-red-600 transition-all border border-transparent hover:border-slate-200/50 flex-shrink-0 ${!sidebarOpen ? 'mx-auto' : ''}`}
                        >
                            <Menu size={18} strokeWidth={2.5} />
                        </button>
                    </div>

                    <nav className="flex-1 p-3 pt-6 space-y-1.5 overflow-y-auto [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]">
                        {NAV_ITEMS.filter(item => hasPermission(item.permission)).map((item) => (
                            <NavItem
                                key={item.id}
                                icon={<item.icon size={19} />}
                                label={item.label}
                                active={activeTab === item.id}
                                isOpen={sidebarOpen}
                                onClick={() => setActiveTab(item.id)}
                            />
                        ))}
                    </nav>

                    <div className="p-3 border-t border-slate-100 flex flex-col gap-4 shrink-0">
                        {/* Notifications */}
                        <div className={`flex ${sidebarOpen ? 'justify-start px-2' : 'justify-center'}`}>
                            <button className="p-2.5 relative bg-slate-50 hover:bg-white rounded-xl text-slate-400 hover:text-red-500 transition-all border border-slate-100/50 shadow-sm group">
                                <Bell size={20} strokeWidth={2.5} className="group-hover:rotate-12 transition-transform" />
                                <span className="absolute top-2.5 right-2.5 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white shadow-sm"></span>
                            </button>
                        </div>

                        {/* User Profile */}
                        <div className="relative" ref={userMenuRef}>
                            <button
                                onClick={() => setShowUserMenu(!showUserMenu)}
                                className={`group relative w-full flex items-center gap-3 rounded-xl p-2 transition-all duration-300
                                    ${showUserMenu ? 'bg-slate-50 border-slate-200' : 'hover:bg-slate-50 border-transparent'}
                                    border
                                    ${!sidebarOpen ? 'justify-center' : ''}
                                `}
                            >
                                <div className="relative w-10 h-10 rounded-xl overflow-hidden shrink-0 bg-slate-100 border border-slate-200 flex items-center justify-center">
                                    {userInfo?.avatarUrl ? (
                                        <img src={userInfo.avatarUrl} alt="Avatar" className="w-full h-full object-cover grayscale-[0.5] group-hover:grayscale-0 transition-all duration-700" />
                                    ) : (
                                        <UserCircle size={24} className="text-slate-400" />
                                    )}
                                    <div className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-green-500 rounded-full border border-white"></div>
                                </div>
                                {sidebarOpen && (
                                    <div className="text-left flex-1 min-w-0 pr-1">
                                        <p className="text-[13px] font-black text-slate-800 tracking-tight leading-none truncate mb-1">{userInfo?.name || '用户'}</p>
                                        <p className="text-[9px] text-slate-400 font-bold uppercase truncate">{userInfo?.roleName || 'System Admin'}</p>
                                    </div>
                                )}
                            </button>

                            <AnimatePresence>
                                {showUserMenu && (
                                    <motion.div
                                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                        className="absolute left-0 bottom-[calc(100%+15px)] w-60 bg-white/95 backdrop-blur-3xl rounded-[2rem] shadow-[0_40px_80px_-15px_rgba(0,0,0,0.2)] border border-white/60 p-2 z-[150]"
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

            {/* Main Content Area */}
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden relative">

                {/* 1. Global Header - Premium Floating Glass (Topbar layout only) */}
                {layoutMode === 'topbar' && (
                    <header className="bg-white/80 backdrop-blur-xl border-b border-slate-200/50 h-20 flex items-center justify-between px-8 z-[100] relative shrink-0">
                        {/* Subtle bottom glow line */}
                        <div className="absolute bottom-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-red-500/20 to-transparent"></div>

                        <div className="flex items-center gap-10">
                            {/* Logo & Platform Title */}
                            <div className="flex items-center gap-10">
                                <div className="flex items-center gap-4 py-1 px-3 bg-slate-50 rounded-2xl border border-slate-100 shadow-inner">
                                    <img src={LOGO_URL} alt="Bank Logo" className="h-8 w-auto object-contain" />
                                    <div className="h-6 w-px bg-slate-200"></div>
                                    <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest italic pr-1">ARK / PORTAL</span>
                                </div>

                                {/* Top Navigation Tabs - Dynamic Capsule Style */}
                                <nav className="hidden lg:flex items-center bg-slate-100/50 p-1.5 rounded-[1.25rem] relative" ref={moreMenuRef}>
                                    {(() => {
                                        const allowedItems = NAV_ITEMS.filter(item => hasPermission(item.permission));
                                        if (allowedItems.length === 0) return null;

                                        // Find active item index
                                        const activeIndex = allowedItems.findIndex(item => item.id === activeTab);

                                        // Decide which items to show directly
                                        const MAX_VISIBLE = 4;
                                        let visibleItems = allowedItems.slice(0, MAX_VISIBLE);
                                        let hiddenItems = allowedItems.slice(MAX_VISIBLE);

                                        // If active item is in hidden, swap it up to visible (replacing the last visible one)
                                        if (activeIndex >= MAX_VISIBLE) {
                                            const activeItem = allowedItems[activeIndex];
                                            const itemToHide = visibleItems[MAX_VISIBLE - 1];

                                            visibleItems[MAX_VISIBLE - 1] = activeItem;

                                            // Replace activeitem in hiddenItems with the itemToHide so it visually swaps instead of just pushing
                                            hiddenItems = hiddenItems.map(item => item.id === activeItem.id ? itemToHide : item);
                                        }

                                        return (
                                            <>
                                                {visibleItems.map((item) => {
                                                    const isActive = activeTab === item.id;
                                                    return (
                                                        <button
                                                            key={item.id}
                                                            onClick={() => setActiveTab(item.id)}
                                                            className={`relative flex items-center gap-2.5 px-5 py-2.5 rounded-xl text-[12px] font-black uppercase tracking-wider transition-all duration-300 z-10
                                                            ${isActive ? 'text-red-600' : 'text-slate-500 hover:text-slate-800'}
                                                        `}
                                                        >
                                                            {isActive && (
                                                                <motion.div
                                                                    layoutId="topNavTab"
                                                                    className="absolute inset-0 bg-white shadow-xl shadow-black/[0.03] rounded-xl z-[-1] border border-slate-100"
                                                                    transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                                                                />
                                                            )}
                                                            <item.icon size={16} strokeWidth={isActive ? 3 : 2} />
                                                            <span className="whitespace-nowrap">{item.label}</span>
                                                        </button>
                                                    );
                                                })}

                                                {/* More Dropdown */}
                                                {hiddenItems.length > 0 && (
                                                    <div className="relative z-20 ml-1">
                                                        <button
                                                            onClick={() => setShowMoreNavMenu(!showMoreNavMenu)}
                                                            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-[12px] font-black uppercase tracking-wider transition-all duration-300
                                                            ${showMoreNavMenu ? 'bg-white text-slate-800 shadow-sm border border-slate-100' : 'text-slate-500 hover:text-slate-800'}
                                                        `}
                                                        >
                                                            <span>更多应用</span>
                                                            <motion.div
                                                                animate={{ rotate: showMoreNavMenu ? 180 : 0 }}
                                                                transition={{ type: 'spring', stiffness: 200, damping: 20 }}
                                                            >
                                                                <svg width="10" height="6" viewBox="0 0 10 6" fill="none" xmlns="http://www.w3.org/2000/svg">
                                                                    <path d="M1 1L5 5L9 1" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                                                                </svg>
                                                            </motion.div>
                                                        </button>

                                                        <AnimatePresence>
                                                            {showMoreNavMenu && (
                                                                <motion.div
                                                                    initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                                                    animate={{ opacity: 1, y: 0, scale: 1 }}
                                                                    exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                                                    transition={{ type: "spring", bounce: 0.3, duration: 0.5 }}
                                                                    className="absolute right-0 top-full mt-3 w-56 bg-white/90 backdrop-blur-2xl rounded-[1.25rem] shadow-[0_20px_40px_-10px_rgba(0,0,0,0.1)] border border-white p-2 z-50 grid grid-cols-1 gap-1"
                                                                >
                                                                    {hiddenItems.map((item) => (
                                                                        <button
                                                                            key={item.id}
                                                                            onClick={() => {
                                                                                setActiveTab(item.id);
                                                                                setShowMoreNavMenu(false);
                                                                            }}
                                                                            className="flex items-center gap-3 w-full px-4 py-3 rounded-xl text-left transition-all hover:bg-slate-50 hover:text-red-600 group"
                                                                        >
                                                                            <div className="p-1.5 rounded-lg bg-slate-100/80 text-slate-500 group-hover:bg-red-100/50 group-hover:text-red-600 transition-colors">
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
                            </div>
                        </div>

                        {/* Right Utilities Section */}
                        <div className="flex items-center gap-6">

                            <button className="p-3 relative bg-slate-50 hover:bg-white rounded-2xl text-slate-400 hover:text-red-500 transition-all border border-slate-100/50 shadow-sm group">
                                <Bell size={20} strokeWidth={2.5} className="group-hover:rotate-12 transition-transform" />
                                <span className="absolute top-2.5 right-2.5 w-3 h-3 bg-red-500 rounded-full border-[3px] border-white shadow-sm"></span>
                            </button>

                            <div className="flex items-center gap-5 pl-4 border-l border-slate-200/60">
                                <div className="text-right hidden xl:block">
                                    <p className="text-[13px] font-black text-slate-800 tracking-tight leading-none mb-1">{userInfo?.name || '用户'}</p>
                                    <p className="text-[9px] text-slate-400 font-bold uppercase tracking-[0.15em]">{userInfo?.roleName || 'System Admin'}</p>
                                </div>

                                <div className="relative" ref={userMenuRef}>
                                    <button
                                        onClick={() => setShowUserMenu(!showUserMenu)}
                                        className={`group relative w-12 h-12 rounded-[1.25rem] bg-slate-50 border transition-all duration-500 overflow-hidden flex items-center justify-center
                                        ${showUserMenu ? 'border-red-400 shadow-lg shadow-red-500/10' : 'border-slate-100 hover:border-red-200 hover:shadow-md'}
                                    `}
                                    >
                                        {userInfo?.avatarUrl ? (
                                            <img src={userInfo.avatarUrl} alt="Avatar" className="w-full h-full object-cover grayscale-[0.5] group-hover:grayscale-0 transition-all duration-700" />
                                        ) : (
                                            <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-slate-100 to-slate-50 text-slate-400">
                                                <UserCircle size={28} strokeWidth={1.5} />
                                            </div>
                                        )}
                                        {/* Small indicator on avatar */}
                                        <div className="absolute bottom-1 right-1 w-2.5 h-2.5 bg-green-500 rounded-full border-2 border-white"></div>
                                    </button>

                                    <AnimatePresence>
                                        {showUserMenu && (
                                            <motion.div
                                                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                                animate={{ opacity: 1, y: 0, scale: 1 }}
                                                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                                className="absolute right-0 top-full mt-4 w-60 bg-white/90 backdrop-blur-2xl rounded-[1.5rem] shadow-[0_30px_60px_-15px_rgba(0,0,0,0.15)] border border-white/60 p-2 z-[110] overflow-hidden"
                                            >
                                                {renderUserMenuContent()}
                                            </motion.div>
                                        )}
                                    </AnimatePresence>
                                </div>
                            </div>
                        </div>
                    </header>
                )}

                {/* Scrollable Content Area */}
                <main className="flex-1 overflow-y-auto p-4 lg:p-8 scroll-smooth bg-slate-50/50">
                    <div className="max-w-[98%] mx-auto h-full"> {/* Added h-full for ArkPage full height */}
                        {activeTab === 'dashboard' && <Dashboard />}
                        {activeTab === 'ark' && <ArkPage />}
                        {activeTab === 'announcement' && <AnnouncementManagement />}
                        {activeTab === 'sys' && <SystemManagement />}
                        {activeTab === 'version' && <VersionManagement />}
                        {activeTab === 'metadata' && <MetadataManagement />}
                        {activeTab === 'ops' && <OpsManagement />}
                        {activeTab === 'knowledge' && <KnowledgeCenter />}
                        {activeTab === 'marketplace' && <MarketplacePage />}
                        {activeTab === 'basic_info' && <BasicInfo userInfo={userInfo} />}
                    </div>
                </main>
            </div>

            <ChangePasswordModal
                visible={changePasswordVisible}
                onCancel={() => setChangePasswordVisible(false)}
                onSuccess={() => {
                    setChangePasswordVisible(false);
                    // Optionally logout or just close
                    handleLogout();
                }}
            />

            {/* Persistent Chat Widget */}
            <ChatWidget />
        </div >
    );
};

// Helper for Sidebar Items
interface NavItemProps {

    icon: React.ReactNode;
    label: string;
    active?: boolean;
    isOpen: boolean;
    onClick: () => void;
}

const NavItem: React.FC<NavItemProps> = ({ icon, label, active, isOpen, onClick }) => (
    <button
        onClick={onClick}
        className={`group relative flex items-center gap-3.5 w-full p-3.5 rounded-2xl transition-all duration-300
        ${active ? 'text-red-600' : 'text-slate-500 hover:text-slate-900'}
        ${!isOpen ? 'justify-center' : ''}
    `}>
        {active && (
            <motion.div
                layoutId="sidebarActivePill"
                className="absolute inset-x-2 inset-y-1 bg-white border border-red-100 shadow-sm rounded-2xl z-[-1]"
                transition={{ type: "spring", bounce: 0.25, duration: 0.5 }}
            />
        )}

        <div className={`transition-transform duration-300 ${active ? 'scale-110' : 'group-hover:scale-110'}`}>
            {icon}
        </div>

        {isOpen && (
            <span className={`text-[11px] font-black tracking-[0.15em] uppercase transition-all duration-300 ${active ? 'opacity-100' : 'opacity-70 group-hover:opacity-100'}`}>
                {label}
            </span>
        )}

        {!isOpen && (
            <div className="absolute left-[calc(100%+15px)] px-3 py-2 bg-slate-900/90 backdrop-blur-md text-white text-[10px] font-black uppercase tracking-[0.2em] rounded-xl shadow-2xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-300 z-50 whitespace-nowrap border border-white/10">
                {label}
            </div>
        )}
    </button>
);

export default App;
