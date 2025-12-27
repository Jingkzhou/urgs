import React, { useEffect, useState } from 'react';
import { hasPermission } from './utils/permission';
import { LayoutDashboard, Menu, Bell, Search, UserCircle, LogOut, Settings, PanelTop, PanelLeft, Megaphone, Timer, Database, GitBranch, Activity, Lock, Palette, User, Sparkles } from 'lucide-react';
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

            {/* Main Content */}
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
                {/* Top Header */}
                <header className="bg-white shadow-sm border-b border-slate-200 h-16 flex items-center justify-between px-6 z-10 relative">
                    {/* Red accent line at top */}
                    <div className="absolute top-0 left-0 w-full h-1 bg-red-600"></div>

                    <div className="flex items-center gap-6">
                        {layoutMode === 'sidebar' ? (
                            /* Sidebar Mode Header Controls */
                            <>
                                <button onClick={() => setSidebarOpen(!sidebarOpen)} className="p-2 hover:bg-slate-100 rounded-lg text-slate-600 transition-colors">
                                    <Menu size={20} />
                                </button>
                                <h2 className="text-lg font-bold text-slate-800 hidden sm:block tracking-wide">
                                    金融监管统一门户 <span className="text-slate-400 font-normal text-sm ml-2">Regulatory Portal</span>
                                </h2>
                            </>
                        ) : (
                            /* Topbar Mode Header Controls (Logo + Nav) */
                            <>
                                <div className="flex items-center gap-2 mr-4">
                                    <img src={LOGO_URL} alt="Bank of Jilin" className="h-8 object-contain" />
                                </div>
                                <nav className="hidden md:flex items-center gap-1">
                                    {NAV_ITEMS.filter(item => hasPermission(item.permission)).map((item) => (
                                        <button
                                            key={item.id}
                                            onClick={() => setActiveTab(item.id)}
                                            className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-bold transition-all duration-200 ${activeTab === item.id
                                                ? 'bg-red-50 text-red-700 shadow-sm border border-red-100'
                                                : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                                                }`}
                                        >
                                            <item.icon size={18} />
                                            {item.label}
                                        </button>
                                    ))}
                                </nav>
                            </>
                        )}
                    </div>

                    <div className="flex items-center gap-3 sm:gap-4">
                        {/* Layout Toggle Button */}
                        <button
                            onClick={() => setLayoutMode(prev => prev === 'sidebar' ? 'topbar' : 'sidebar')}
                            className="p-2 hover:bg-slate-100 rounded-full text-slate-500 hover:text-red-600 transition-colors"
                            title={layoutMode === 'sidebar' ? "切换至顶部导航" : "切换至侧边栏导航"}
                        >
                            {layoutMode === 'sidebar' ? <PanelTop size={20} /> : <PanelLeft size={20} />}
                        </button>

                        <div className="h-6 w-px bg-slate-200 mx-1"></div>

                        <button className="p-2 relative hover:bg-slate-100 rounded-full text-slate-500 transition-colors">
                            <Bell size={20} />
                            <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white"></span>
                        </button>
                        <div className="flex items-center gap-3 pl-2 sm:pl-4 border-l border-slate-200">
                            <div className="text-right hidden md:block">
                                <p className="text-sm font-bold text-slate-800">{userInfo?.name || '用户'}</p>
                                <p className="text-xs text-slate-500">{userInfo?.roleName || '吉林银行总行'}</p>
                            </div>
                            {layoutMode === 'topbar' ? (
                                <div className="relative" ref={userMenuRef}>
                                    <button
                                        onClick={() => setShowUserMenu(!showUserMenu)}
                                        className="group relative focus:outline-none"
                                    >
                                        <div className={`w-8 h-8 rounded-full bg-slate-100 border flex items-center justify-center text-slate-500 transition-colors overflow-hidden ${showUserMenu ? 'border-red-300 text-red-600' : 'border-slate-200 group-hover:border-red-300 group-hover:text-red-600'}`}>
                                            {/* Show Avatar or Fallback */}
                                            {userInfo?.avatarUrl ? (
                                                <img src={userInfo.avatarUrl} alt="Avatar" className="w-full h-full object-cover" />
                                            ) : (
                                                <UserCircle size={20} />
                                            )}
                                        </div>
                                    </button>

                                    {showUserMenu && (
                                        <div className="absolute right-0 top-full mt-2 w-48 bg-white rounded-lg shadow-lg border border-slate-100 py-1 z-50 animate-in fade-in slide-in-from-top-2 duration-200">
                                            <button
                                                onClick={() => {
                                                    setActiveTab('basic_info');
                                                    setShowUserMenu(false);
                                                }}
                                                className="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 hover:text-red-600 flex items-center gap-2"
                                            >
                                                <User size={16} />
                                                <span>基本信息</span>
                                            </button>
                                            <button
                                                onClick={handleChangePassword}
                                                className="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 hover:text-red-600 flex items-center gap-2"
                                            >
                                                <Lock size={16} />
                                                <span>修改密码</span>
                                            </button>
                                            <div className="h-px bg-slate-100 my-1"></div>
                                            <button
                                                onClick={handleLogout}
                                                className="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                                            >
                                                <LogOut size={16} />
                                                <span>退出登录</span>
                                            </button>
                                        </div>
                                    )}
                                </div>
                            ) : (
                                <div className="w-8 h-8 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-500 overflow-hidden">
                                    {userInfo?.avatarUrl ? (
                                        <img src={userInfo.avatarUrl} alt="Avatar" className="w-full h-full object-cover" />
                                    ) : (
                                        <UserCircle size={20} />
                                    )}
                                </div>
                            )}
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
