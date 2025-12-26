import React, { useState, useEffect } from 'react';
import { LOGO_URL } from '../constants';
import { Lock, User, ShieldCheck, ChevronRight, ArrowRight } from 'lucide-react';

interface LoginProps {
    onLogin: (token: string, user: any) => void;
}

const Login: React.FC<LoginProps> = ({ onLogin }) => {
    const [loading, setLoading] = useState(false);
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState<string | null>(null);
    const [rememberMe, setRememberMe] = useState(false);
    const [animate, setAnimate] = useState(false);

    useEffect(() => {
        setAnimate(true);
        const stored = localStorage.getItem('remember_me');
        if (stored) {
            try {
                const { u, p } = JSON.parse(atob(stored));
                setUsername(u);
                setPassword(p);
                setRememberMe(true);
            } catch (e) {
                localStorage.removeItem('remember_me');
            }
        }
    }, []);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError(null);
        try {
            const res = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password }),
            });

            if (!res.ok) {
                const errorText = await res.text().catch(() => '');
                if (res.status === 401) {
                    throw new Error('用户名或密码错误');
                } else if (res.status === 403) {
                    throw new Error('账号已被禁用或无权访问');
                } else {
                    throw new Error(`登录失败 (${res.status})`);
                }
            }

            const data = await res.json();

            // Handle Remember Me
            if (rememberMe) {
                localStorage.setItem('remember_me', btoa(JSON.stringify({ u: username, p: password })));
            } else {
                localStorage.removeItem('remember_me');
            }

            localStorage.setItem('auth_token', data.token);
            localStorage.setItem('auth_user', JSON.stringify({
                id: data.id,
                empId: data.empId,
                name: data.name,
                roleName: data.roleName,
                roleId: data.roleId,
                system: data.system
            }));

            // Check for OAuth params
            const params = new URLSearchParams(window.location.search);
            const clientId = params.get('client_id');
            const redirectUri = params.get('redirect_uri');

            if (clientId && redirectUri) {
                try {
                    // Call authorize endpoint to get code
                    const authRes = await fetch('/api/oauth/authorize', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': `Bearer ${data.token}`
                        },
                        body: JSON.stringify({
                            client_id: clientId,
                            redirect_uri: redirectUri,
                            response_type: 'code'
                        })
                    });

                    if (authRes.ok) {
                        const authData = await authRes.json();
                        // Redirect to external system with code
                        window.location.href = `${authData.redirect_uri}?code=${authData.code}`;
                        return;
                    } else {
                        console.error('OAuth authorization failed');
                    }
                } catch (e) {
                    console.error('OAuth error', e);
                }
            }

            // Keep loading true while switching views to prevent flash
            onLogin(data.token, {
                id: data.id,
                empId: data.empId,
                name: data.name,
                roleName: data.roleName,
                roleId: data.roleId,
                system: data.system
            });
        } catch (err: any) {
            console.error('Login error:', err);
            setError(err.message || '连接服务器失败，请检查网络');
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-slate-900 overflow-hidden relative font-sans flex items-center justify-center">
            {/* 1. Dynamic Background Layer */}
            <div className="absolute inset-0 z-0">
                {/* Dark gradient base */}
                <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900"></div>

                {/* Abstract Glowing Orbs (Bank Red/Gold Theme) */}
                <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-red-900/40 rounded-full blur-[120px] animate-pulse"></div>
                <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-blue-900/30 rounded-full blur-[120px]"></div>
                <div className="absolute top-[40%] left-[60%] w-[30%] h-[30%] bg-amber-700/20 rounded-full blur-[100px]"></div>

                {/* Mesh Pattern Overlay */}
                <div className="absolute inset-0 opacity-[0.03]" style={{
                    backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
                }}></div>
            </div>

            {/* 2. Main Container - Split Layout or Centered Card? -> Centered Floating Glass Card looks very premium */}
            <div className={`relative z-10 w-full max-w-[440px] px-6 transition-all duration-1000 transform ${animate ? 'translate-y-0 opacity-100' : 'translate-y-10 opacity-0'}`}>

                {/* Glass Card */}
                <div className="backdrop-blur-xl bg-white/90 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.5)] border border-white/50 rounded-2xl overflow-hidden">

                    {/* Header Section */}
                    <div className="relative pt-10 pb-8 px-10 border-b border-slate-100/80 bg-gradient-to-b from-white to-slate-50/50">
                        {/* Logo Container - Clean and Centered */}
                        <div className="flex flex-col items-center justify-center">
                            <div className="w-full flex justify-center mb-6 drop-shadow-sm">
                                <img src={LOGO_URL} alt="Bank Logo" className="h-16 w-auto object-contain" />
                            </div>
                            <div className="space-y-1 text-center">
                                <h1 className="text-xl font-bold bg-gradient-to-r from-slate-900 to-slate-700 bg-clip-text text-transparent tracking-tight">
                                    监管报送一体化系统
                                </h1>
                                <p className="text-[10px] text-slate-400 font-medium tracking-[0.2em] uppercase">
                                    Integrated Regulatory Reporting System
                                </p>
                            </div>
                        </div>
                    </div>

                    {/* Form Section */}
                    <div className="p-10 pt-8 bg-white/50">
                        <form onSubmit={handleSubmit} className="space-y-6">

                            {/* Username Input */}
                            <div className="space-y-2 group">
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider ml-1 group-focus-within:text-red-600 transition-colors">
                                    ID / Username
                                </label>
                                <div className="relative transform transition-all duration-300 group-focus-within:scale-[1.01]">
                                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-slate-400 group-focus-within:text-red-500 transition-colors">
                                        <User className="h-5 w-5" strokeWidth={2} />
                                    </div>
                                    <input
                                        type="text"
                                        required
                                        value={username}
                                        onChange={(e) => setUsername(e.target.value)}
                                        className="block w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500 transition-all shadow-sm"
                                        placeholder="请输入您的工号"
                                    />
                                </div>
                            </div>

                            {/* Password Input */}
                            <div className="space-y-2 group">
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider ml-1 group-focus-within:text-red-600 transition-colors">
                                    Password
                                </label>
                                <div className="relative transform transition-all duration-300 group-focus-within:scale-[1.01]">
                                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-slate-400 group-focus-within:text-red-500 transition-colors">
                                        <Lock className="h-5 w-5" strokeWidth={2} />
                                    </div>
                                    <input
                                        type="password"
                                        required
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        className="block w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500 transition-all shadow-sm"
                                        placeholder="请输入密码"
                                    />
                                </div>
                            </div>

                            {/* Error Message */}
                            {error && (
                                <div className="flex items-center gap-2 p-3 rounded-lg bg-red-50 border border-red-100 text-red-600 text-sm animate-shake">
                                    <div className="w-1.5 h-1.5 bg-red-500 rounded-full"></div>
                                    {error}
                                </div>
                            )}

                            {/* Actions */}
                            <div className="flex items-center justify-between pt-2">
                                <label className="flex items-center cursor-pointer group">
                                    <div className="relative">
                                        <input
                                            type="checkbox"
                                            checked={rememberMe}
                                            onChange={(e) => setRememberMe(e.target.checked)}
                                            className="peer sr-only"
                                        />
                                        <div className="w-4 h-4 border-2 border-slate-300 rounded peer-checked:bg-red-600 peer-checked:border-red-600 transition-all"></div>
                                        <div className="absolute inset-0 hidden peer-checked:flex items-center justify-center pointer-events-none">
                                            <svg className="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                                            </svg>
                                        </div>
                                    </div>
                                    <span className="ml-2.5 text-sm text-slate-500 group-hover:text-slate-700 transition-colors">记住我</span>
                                </label>
                                <a href="#" className="text-sm font-medium text-red-600 hover:text-red-700 hover:underline transition-colors decoration-dashed decoration-1 underline-offset-4">
                                    忘记密码?
                                </a>
                            </div>

                            {/* Submit Button */}
                            <button
                                type="submit"
                                disabled={loading}
                                className={`group relative w-full flex items-center justify-center py-4 px-6 border border-transparent rounded-xl text-sm font-bold text-white overflow-hidden transition-all duration-300 shadow-lg shadow-red-600/30 ${loading
                                    ? 'bg-slate-800 cursor-not-allowed'
                                    : 'bg-gradient-to-r from-red-600 to-rose-700 hover:from-red-500 hover:to-rose-600 transform hover:-translate-y-0.5'
                                    }`}
                            >
                                {loading ? (
                                    <div className="flex items-center gap-2">
                                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                        <span className="tracking-wide">AUTHENTICATING...</span>
                                    </div>
                                ) : (
                                    <div className="flex items-center gap-2">
                                        <span className="tracking-wide">安全登录</span>
                                        <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
                                    </div>
                                )}
                            </button>
                        </form>
                    </div>

                    {/* Footer */}
                    <div className="bg-slate-50/80 p-4 border-t border-slate-100 flex items-center justify-center gap-2 text-xs text-slate-400">
                        <ShieldCheck className="w-3.5 h-3.5" />
                        <span className="font-medium">Secure Access • Bank of Jilin © 2026</span>
                    </div>
                </div>

                {/* Bottom Reflection/Glow */}
                <div className="absolute -bottom-4 left-10 right-10 h-10 bg-white/20 blur-xl rounded-full z-[-1]"></div>
            </div>
        </div>
    );
};

export default Login;
