import React, { useEffect, useState } from 'react';
import { hasPermission } from './utils/permission';
import { LayoutDashboard, Menu, Bell, Search, UserCircle, LogOut, Settings, PanelTop, PanelLeft, Megaphone, Timer, Database, GitBranch, Activity, Lock, Palette, User, Sparkles } from 'lucide-react';
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
import { LOGO_URL } from './constants';

const NAV_ITEMS = [
    { id: 'dashboard', label: '工作台', icon: LayoutDashboard, permission: 'dashboard' },
    { id: 'ark', label: 'Ark (方舟)', icon: Sparkles, permission: 'ark' },
    { id: 'announcement', label: '公告管理', icon: Megaphone, permission: 'announcement' },
    { id: 'version', label: '版本管理', icon: GitBranch, permission: 'version' },
    { id: 'metadata', label: '数据管理', icon: Database, permission: 'metadata' },
    { id: 'ops', label: '运维管理', icon: Activity, permission: 'ops' },
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
    const [sidebarOpen, setSidebarOpen] = useState(true);
    const [layoutMode, setLayoutMode] = useState<'sidebar' | 'topbar'>('topbar');
    const [activeTab, setActiveTab] = useState('dashboard');
    const [showUserMenu, setShowUserMenu] = useState(false);
    const [changePasswordVisible, setChangePasswordVisible] = useState(false);

    // Click outside handler for user menu
    const userMenuRef = React.useRef<HTMLDivElement>(null);
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (showUserMenu && userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
                setShowUserMenu(false);
            }
        };
        // Use mousedown to capture the event before click (optional, but robust)
        document.addEventListener('mousedown', handleClickOutside);
        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [showUserMenu]);

    useEffect(() => {
        if (isAuthenticated) {
            setShowUserMenu(false);
        }
    }, [isAuthenticated]);

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

    return (
        <div className={`flex h-screen bg-slate-50 ${layoutMode === 'topbar' ? 'flex-col' : 'flex-row'}`}>
            {/* Sidebar Navigation - Only render in sidebar mode */}
            {layoutMode === 'sidebar' && (
                <aside
                    className={`${sidebarOpen ? 'w-64' : 'w-20'
                        } bg-white border-r border-slate-200 text-slate-800 transition-all duration-300 flex flex-col shadow-sm z-20`}
                >
                    <div className="h-16 flex items-center justify-center border-b border-slate-100 bg-white overflow-hidden">
                        {sidebarOpen ? (
                            <div className="flex flex-col items-center animate-fade-in">
                                {/* Logo Image */}
                                <img src={LOGO_URL} alt="Bank of Jilin" className="h-10 object-contain" />
                            </div>
                        ) : (
                            <div className="w-9 h-9 rounded-full bg-red-600 flex items-center justify-center font-serif font-bold italic text-white shadow-md shadow-red-200">J</div>
                        )}
                    </div>

                    <nav className="flex-1 p-4 space-y-2">
                        {NAV_ITEMS.filter(item => hasPermission(item.permission)).map((item) => (
                            <NavItem
                                key={item.id}
                                icon={<item.icon size={20} />}
                                label={item.label}
                                active={activeTab === item.id}
                                isOpen={sidebarOpen}
                                onClick={() => setActiveTab(item.id)}
                            />
                        ))}
                    </nav>

                    <div className="p-4 border-t border-slate-100">
                        <button
                            onClick={handleLogout}
                            className={`flex items-center gap-3 w-full p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors ${!sidebarOpen && 'justify-center'}`}
                        >
                            <LogOut size={20} />
                            {sidebarOpen && <span>退出登录</span>}
                        </button>
                    </div>
                </aside>
            )}

            {/* Main Content Area */}
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden relative">

                {/* 1. Global Header - Premium Floating Glass */}
                <header className="bg-white/80 backdrop-blur-xl border-b border-slate-200/50 h-20 flex items-center justify-between px-8 z-[100] relative">
                    {/* Subtle bottom glow line */}
                    <div className="absolute bottom-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-red-500/20 to-transparent"></div>

                    <div className="flex items-center gap-10">
                        {/* Logo & Platform Title */}
                        {layoutMode === 'sidebar' ? (
                            <div className="flex items-center gap-6">
                                <button
                                    onClick={() => setSidebarOpen(!sidebarOpen)}
                                    className="p-2.5 bg-slate-50 hover:bg-white rounded-xl text-slate-500 hover:text-red-600 transition-all shadow-sm border border-transparent hover:border-slate-100"
                                >
                                    <Menu size={20} strokeWidth={2.5} />
                                </button>
                                <div className="flex flex-col">
                                    <h2 className="text-sm font-black text-slate-800 tracking-tight uppercase italic flex items-center gap-2">
                                        金融监管统一门户 <span className="w-1 h-1 bg-red-500 rounded-full animate-pulse"></span>
                                    </h2>
                                    <span className="text-[9px] text-slate-400 font-bold tracking-[0.2em] uppercase">Integrated Regulatory Control</span>
                                </div>
                            </div>
                        ) : (
                            <div className="flex items-center gap-10">
                                <div className="flex items-center gap-4 py-1 px-3 bg-slate-50 rounded-2xl border border-slate-100 shadow-inner">
                                    <img src={LOGO_URL} alt="Bank Logo" className="h-8 w-auto object-contain" />
                                    <div className="h-6 w-px bg-slate-200"></div>
                                    <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest italic pr-1">ARK / PORTAL</span>
                                </div>

                                {/* Top Navigation Tabs - Dynamic Capsule Style */}
                                <nav className="hidden lg:flex items-center bg-slate-100/50 p-1.5 rounded-[1.25rem] relative">
                                    {NAV_ITEMS.filter(item => hasPermission(item.permission)).map((item) => {
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
                                </nav>
                            </div>
                        )}
                    </div>

                    {/* Right Utilities Section */}
                    <div className="flex items-center gap-6">
                        <div className="flex items-center gap-2 bg-slate-50/50 p-1 rounded-2xl border border-slate-100/50 shadow-inner">
                            <button
                                onClick={() => setLayoutMode(prev => prev === 'sidebar' ? 'topbar' : 'sidebar')}
                                className={`p-2.5 rounded-xl transition-all duration-300 ${layoutMode === 'topbar' ? 'bg-white shadow-sm text-red-600' : 'text-slate-400 hover:text-slate-600'}`}
                                title="顶部模式"
                            >
                                <PanelTop size={18} strokeWidth={2.5} />
                            </button>
                            <button
                                onClick={() => setLayoutMode(prev => prev === 'sidebar' ? 'topbar' : 'sidebar')}
                                className={`p-2.5 rounded-xl transition-all duration-300 ${layoutMode === 'sidebar' ? 'bg-white shadow-sm text-red-600' : 'text-slate-400 hover:text-slate-600'}`}
                                title="侧边模式"
                            >
                                <PanelLeft size={18} strokeWidth={2.5} />
                            </button>
                        </div>

                        <div className="h-8 w-px bg-slate-200/60 mx-1"></div>

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
                                            <div className="p-4 mb-2 bg-slate-50/50 rounded-2xl flex flex-col gap-1 md:hidden">
                                                <p className="text-[12px] font-black text-slate-800">{userInfo?.name}</p>
                                                <p className="text-[9px] text-slate-400 font-bold uppercase tracking-widest">{userInfo?.roleName}</p>
                                            </div>

                                            <button
                                                onClick={() => { setActiveTab('basic_info'); setShowUserMenu(false); }}
                                                className="w-full flex items-center gap-4 px-4 py-3 text-[11px] font-black uppercase tracking-[0.15em] text-slate-500 hover:text-red-600 hover:bg-red-50/50 rounded-xl transition-all group"
                                            >
                                                <User size={16} strokeWidth={2.5} className="group-hover:scale-110 transition-transform" />
                                                <span>Personal Identity</span>
                                            </button>

                                            <button
                                                onClick={handleChangePassword}
                                                className="w-full flex items-center gap-4 px-4 py-3 text-[11px] font-black uppercase tracking-[0.15em] text-slate-500 hover:text-red-600 hover:bg-red-50/50 rounded-xl transition-all group"
                                            >
                                                <Lock size={16} strokeWidth={2.5} className="group-hover:scale-110 transition-transform" />
                                                <span>Access Control</span>
                                            </button>

                                            <div className="h-px bg-slate-100 my-2 mx-2"></div>

                                            <button
                                                onClick={handleLogout}
                                                className="w-full flex items-center gap-4 px-4 py-3 text-[11px] font-black uppercase tracking-[0.15em] text-red-600 hover:bg-red-50 rounded-xl transition-all group"
                                            >
                                                <LogOut size={16} strokeWidth={3} className="group-hover:translate-x-1 transition-transform" />
                                                <span>System Exit</span>
                                            </button>
                                        </motion.div>
                                    )}
                                </AnimatePresence>
                            </div>
                        </div>
                    </div>
                </header>

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
        className={`
        flex items-center gap-3 w-full p-3 rounded-md transition-all duration-200 font-medium
        ${active
                ? 'bg-red-600 text-white shadow-md shadow-red-600/20'
                : 'text-slate-600 hover:text-red-700 hover:bg-red-50'
            }
        ${!isOpen && 'justify-center'}
    `}>
        {icon}
        {isOpen && <span className="text-sm">{label}</span>}
    </button>
);

export default App;
