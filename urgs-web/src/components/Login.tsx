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
        <div className="min-h-screen bg-slate-50 overflow-hidden relative font-sans flex items-center justify-center p-6">
            {/* 1. Light Dynamic Background Layer - Elegant & Airy */}
            <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
                {/* Background Pattern */}
                <div className="absolute inset-0 opacity-[0.4] bg-[radial-gradient(#e2e8f0_1px,transparent_1px)] [background-size:32px_32px] [mask-image:radial-gradient(ellipse_at_center,black,transparent_90%)]"></div>

                {/* Soft Airy Orbs */}
                <div className="absolute top-[-10%] left-[-5%] w-[50%] h-[50%] bg-red-100/50 rounded-full blur-[120px] animate-[pulse_10s_ease-in-out_infinite]"></div>
                <div className="absolute bottom-[-10%] right-[-5%] w-[40%] h-[40%] bg-indigo-100/40 rounded-full blur-[100px] animate-[pulse_12s_ease-in-out_infinite_reverse]"></div>

                {/* Subtle Multi-color Fluid Gradient */}
                <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_30%,rgba(244,63,94,0.05),transparent_40%),radial-gradient(circle_at_80%_70%,rgba(99,102,241,0.05),transparent_40%)]"></div>
            </div>

            {/* 2. Login Card - Sophisticated White Glass */}
            <div className={`relative z-10 w-full max-w-[460px] transition-all duration-1000 transform ${animate ? 'translate-y-0 opacity-100' : 'translate-y-8 opacity-0'}`}>

                {/* Soft Floating Shadow Decor */}
                <div className="absolute -inset-10 bg-black/[0.02] rounded-[4rem] blur-[60px] pointer-events-none"></div>

                <div className="backdrop-blur-[60px] bg-white/75 shadow-[0_40px_80px_-15px_rgba(0,0,0,0.08)] border border-white/60 rounded-[3rem] overflow-hidden group/card relative">
                    {/* Top Accent Line */}
                    <div className="absolute top-0 inset-x-0 h-1.5 bg-gradient-to-r from-red-500 via-rose-500 to-red-600 opacity-80"></div>

                    {/* Header Section */}
                    <div className="relative pt-16 pb-10 px-12 text-center">
                        <div className="relative z-10">
                            <div className="flex justify-center mb-8">
                                <div className="relative p-2 bg-white rounded-[2rem] shadow-xl shadow-black/[0.03] border border-slate-100 group/logo">
                                    <img src={LOGO_URL} alt="Bank Logo" className="h-[64px] w-auto object-contain group-hover/logo:scale-105 transition-transform duration-700" />
                                </div>
                            </div>
                            <h1 className="text-2xl font-black text-slate-800 tracking-tighter italic uppercase mb-2">
                                监管报送一体化系统
                            </h1>
                            <div className="flex items-center justify-center gap-2">
                                <span className="text-[10px] text-slate-400 font-black uppercase tracking-[0.25em] opacity-80">
                                    Integrated Reporting Portal
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Form Fields */}
                    <div className="px-12 pb-12">
                        <form onSubmit={handleSubmit} className="space-y-6">

                            {/* Input: ID */}
                            <div className="space-y-2">
                                <label className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.15em] ml-2">
                                    <User size={12} strokeWidth={3} className="text-red-500" /> Username
                                </label>
                                <div className="relative group/input">
                                    <input
                                        type="text"
                                        required
                                        value={username}
                                        onChange={(e) => setUsername(e.target.value)}
                                        className="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 text-slate-800 text-sm placeholder:text-slate-300 focus:outline-none focus:ring-4 focus:ring-red-500/5 focus:border-red-500/30 transition-all duration-500 shadow-inner group-hover/input:bg-white"
                                        placeholder="请输入您的工号"
                                    />
                                    <div className="absolute right-6 top-1/2 -translate-y-1/2 text-slate-200 group-focus-within/input:text-red-500 transition-colors">
                                        <ChevronRight size={18} strokeWidth={3} />
                                    </div>
                                </div>
                            </div>

                            {/* Input: Password */}
                            <div className="space-y-2">
                                <label className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.15em] ml-2">
                                    <Lock size={12} strokeWidth={3} className="text-red-500" /> Password
                                </label>
                                <div className="relative group/input">
                                    <input
                                        type="password"
                                        required
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        className="w-full bg-slate-50 border border-slate-100 rounded-2xl px-6 py-4 text-slate-800 text-sm placeholder:text-slate-300 focus:outline-none focus:ring-4 focus:ring-red-500/5 focus:border-red-500/30 transition-all duration-500 shadow-inner group-hover/input:bg-white"
                                        placeholder="请输入密码"
                                    />
                                </div>
                            </div>

                            {/* Actions Overlay */}
                            <div className="flex items-center justify-between px-2 pt-1">
                                <label className="flex items-center gap-3 cursor-pointer group/check">
                                    <div className="relative">
                                        <input
                                            type="checkbox"
                                            checked={rememberMe}
                                            onChange={(e) => setRememberMe(e.target.checked)}
                                            className="peer sr-only"
                                        />
                                        <div className="w-5 h-5 bg-white border-2 border-slate-100 rounded-lg group-hover/check:border-red-200 transition-all peer-checked:bg-red-600 peer-checked:border-red-600 shadow-sm"></div>
                                        <div className="absolute inset-0 flex items-center justify-center opacity-0 peer-checked:opacity-100 transition-opacity">
                                            <ShieldCheck size={12} className="text-white" strokeWidth={3} />
                                        </div>
                                    </div>
                                    <span className="text-[11px] font-black text-slate-400 group-hover/check:text-slate-600 uppercase tracking-widest transition-colors">记住我</span>
                                </label>
                                <button type="button" className="text-[11px] font-black text-red-600/70 hover:text-red-600 uppercase tracking-widest transition-colors">
                                    忘记密码?
                                </button>
                            </div>

                            {/* Error Tip */}
                            {error && (
                                <div className="p-4 bg-red-50 border border-red-100 rounded-2xl flex items-center gap-3 text-[11px] font-black text-red-600 uppercase tracking-widest animate-in fade-in slide-in-from-top-2 duration-300">
                                    <div className="w-1 h-5 bg-red-500 rounded-full"></div>
                                    {error}
                                </div>
                            )}

                            {/* Submit Controller */}
                            <button
                                type="submit"
                                disabled={loading}
                                className={`w-full relative py-5 rounded-2xl overflow-hidden transition-all duration-500 ${loading
                                        ? 'bg-slate-100 cursor-wait'
                                        : 'bg-slate-900 hover:bg-black group/btn active:scale-95 shadow-xl shadow-slate-900/10'
                                    }`}
                            >
                                <div className="relative z-10 flex items-center justify-center gap-3">
                                    {loading ? (
                                        <>
                                            <div className="w-5 h-5 border-2 border-slate-300 border-t-slate-800 rounded-full animate-spin"></div>
                                            <span className="text-xs font-black text-slate-800 uppercase tracking-[0.2em]">Authenticating...</span>
                                        </>
                                    ) : (
                                        <>
                                            <span className="text-xs font-black text-white uppercase tracking-[0.25em]">登 录</span>
                                            <ArrowRight size={18} strokeWidth={3} className="text-red-500 group-hover/btn:translate-x-1 transition-transform" />
                                        </>
                                    )}
                                </div>
                                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/5 to-transparent opacity-0 group-hover/btn:opacity-100 transition-opacity duration-700"></div>
                            </button>
                        </form>
                    </div>

                    {/* Footer Guard */}
                    <div className="px-12 py-5 bg-slate-50/50 border-t border-slate-100 flex items-center justify-center gap-3">
                        <ShieldCheck size={14} className="text-red-600" strokeWidth={3} />
                        <span className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em]">
                            Verified Secure Portal • Bank of Jilin © 2026
                        </span>
                    </div>
                </div>

                {/* Build Hint */}
                <div className="mt-8 text-center text-slate-300 font-mono text-[9px] uppercase tracking-widest flex items-center justify-center gap-3">
                    <span>V3.8.2-GA</span>
                    <span className="w-1 h-1 bg-slate-200 rounded-full"></span>
                    <span>Service: Optimized</span>
                </div>
            </div>
        </div>
    );
};

export default Login;
