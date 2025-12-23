import React, { useState, useEffect } from 'react';
import { LOGO_URL } from '../constants';

// ... (existing imports)

// ... inside component
<div className="inline-flex items-center justify-center mb-4">
    <img src={LOGO_URL} alt="Bank of Jilin" className="h-12 w-auto" />
</div>
import { Lock, User, ShieldCheck } from 'lucide-react';

interface LoginProps {
    onLogin: (token: string, user: any) => void;
}

const Login: React.FC<LoginProps> = ({ onLogin }) => {
    const [loading, setLoading] = useState(false);
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState<string | null>(null);
    const [rememberMe, setRememberMe] = useState(false);

    useEffect(() => {
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
            // Keep loading true while switching views to prevent flash
            onLogin(data.token, {
                id: data.id,
                empId: data.empId,
                name: data.name,
                roleName: data.roleName,
                roleId: data.roleId, // Added roleId
                system: data.system
            });
        } catch (err: any) {
            console.error('Login error:', err);
            setError(err.message || '连接服务器失败，请检查网络');
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-slate-50 flex items-center justify-center relative overflow-hidden">
            {/* Background Decorative Elements - Red/Warm Theme */}
            <div className="absolute top-0 left-0 w-full h-full overflow-hidden z-0">
                {/* Abstract Red Curve */}
                <div className="absolute top-[-20%] right-[-10%] w-[60%] h-[60%] bg-red-600/10 rounded-full blur-3xl"></div>
                <div className="absolute bottom-[-10%] left-[-10%] w-[40%] h-[40%] bg-orange-500/10 rounded-full blur-3xl"></div>
            </div>

            <div className="bg-white p-10 rounded-xl shadow-2xl w-full max-w-md border-t-4 border-red-600 z-10">
                <div className="text-center mb-10">
                    <div className="inline-flex items-center justify-center mb-4">
                        <img src={LOGO_URL} alt="Bank of Jilin" className="h-16 w-auto" />
                    </div>
                    <p className="text-red-700 font-semibold text-sm mt-1 uppercase tracking-wider">监管报送一体化系统</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div>
                        <label className="block text-sm font-bold text-slate-700 mb-1">用户名 / 证书ID</label>
                        <div className="relative">
                            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <User className="h-5 w-5 text-slate-400" />
                            </div>
                            <input
                                type="text"
                                required
                                value={username}
                                onChange={(e) => setUsername(e.target.value)}
                                className="block w-full pl-10 pr-3 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 bg-white text-slate-900 placeholder-slate-400 transition-colors"
                                placeholder="请输入工号"
                            />
                        </div>
                    </div>

                    <div>
                        <label className="block text-sm font-bold text-slate-700 mb-1">密码</label>
                        <div className="relative">
                            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <Lock className="h-5 w-5 text-slate-400" />
                            </div>
                            <input
                                type="password"
                                required
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                className="block w-full pl-10 pr-3 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 bg-white text-slate-900 placeholder-slate-400 transition-colors"
                                placeholder="请输入密码"
                            />
                        </div>
                    </div>

                    {error && (
                        <div className="text-sm text-red-600 bg-red-50 border border-red-100 rounded-md px-3 py-2">
                            {error}
                        </div>
                    )}

                    <div className="flex items-center justify-between text-sm">
                        <label className="flex items-center">
                            <input
                                type="checkbox"
                                checked={rememberMe}
                                onChange={(e) => setRememberMe(e.target.checked)}
                                className="w-4 h-4 text-red-600 border-slate-300 rounded focus:ring-red-500"
                            />
                            <span className="ml-2 text-slate-600">记住我</span>
                        </label>
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        className={`w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-md shadow-red-600/20 text-sm font-bold text-white bg-gradient-to-r from-red-600 to-red-700 hover:from-red-700 hover:to-red-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-all transform active:scale-[0.98] ${loading ? 'opacity-70 cursor-wait' : ''}`}
                    >
                        {loading ? (
                            <div className="flex items-center gap-2">
                                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                正在认证...
                            </div>
                        ) : '安全登录'}
                    </button>
                </form>

                <div className="mt-8 pt-6 border-t border-slate-100 text-center text-xs text-slate-400">
                    <div className="flex items-center justify-center gap-2 mb-2">
                        <ShieldCheck className="w-4 h-4 text-slate-300" />
                        <span>Bank of Jilin Secure Access</span>
                    </div>
                    <p>© 2024 吉林银行 版权所有</p>
                </div>
            </div>
        </div>
    );
};

export default Login;
