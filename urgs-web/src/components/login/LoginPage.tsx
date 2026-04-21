import React, { useState, useEffect } from "react";
import { LOGO_URL } from "../../constants";
import { Lock, User, Eye, EyeOff, ShieldCheck, ChevronRight, Landmark, Activity } from "lucide-react";

interface LoginProps {
  onLogin: (token: string, user: any) => void;
}

const LoginPage: React.FC<LoginProps> = ({ onLogin }) => {
  const [loading, setLoading] = useState(false);
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [rememberMe, setRememberMe] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    const stored = localStorage.getItem("remember_me");
    if (stored) {
      try {
        const { u, p } = JSON.parse(atob(stored));
        setUsername(u);
        setPassword(p);
        setRememberMe(true);
      } catch (e) {
        localStorage.removeItem("remember_me");
      }
    }
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });

      if (!res.ok) {
        await res.text().catch(() => "");
        if (res.status === 401) {
          throw new Error("用户名或密码错误");
        } else if (res.status === 403) {
          throw new Error("账号已被禁用或无权访问");
        } else {
          throw new Error(`登录失败 (${res.status})`);
        }
      }

      const data = await res.json();

      if (rememberMe) {
        localStorage.setItem(
          "remember_me",
          btoa(JSON.stringify({ u: username, p: password }))
        );
      } else {
        localStorage.removeItem("remember_me");
      }

      localStorage.setItem("auth_token", data.token);
      localStorage.setItem(
        "auth_user",
        JSON.stringify({
          id: data.id,
          empId: data.empId,
          name: data.name,
          roleName: data.roleName,
          roleId: data.roleId,
          system: data.system,
        })
      );

      const params = new URLSearchParams(window.location.search);
      const clientId = params.get("client_id");
      const redirectUri = params.get("redirect_uri");

      if (clientId && redirectUri) {
        try {
          const authRes = await fetch("/api/oauth/authorize", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${data.token}`,
            },
            body: JSON.stringify({
              client_id: clientId,
              redirect_uri: redirectUri,
              response_type: "code",
            }),
          });

          if (authRes.ok) {
            const authData = await authRes.json();
            window.location.href = `${authData.redirect_uri}?code=${authData.code}`;
            return;
          } else {
            console.error("OAuth authorization failed");
          }
        } catch (e) {
          console.error("OAuth error", e);
        }
      }

      onLogin(data.token, {
        id: data.id,
        empId: data.empId,
        name: data.name,
        roleName: data.roleName,
        roleId: data.roleId,
        system: data.system,
      });
    } catch (err: any) {
      console.error("Login error:", err);
      setError(err.message || "连接服务器失败，请检查网络");
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen max-h-screen overflow-hidden grid lg:grid-cols-2 bg-slate-50">
      {/* Left Content Section - Professional Dark Theme */}
      <div className="relative hidden lg:flex flex-col justify-between bg-slate-950 p-16 text-white overflow-hidden">
        {/* Background Decorations */}
        <div 
          className="absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage: `linear-gradient(#fff 1px, transparent 1px), linear-gradient(90deg, #fff 1px, transparent 1px)`,
            backgroundSize: '40px 40px',
          }}
        />
        <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] rounded-full bg-blue-600/20 blur-[120px]" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-red-600/10 blur-[100px]" />

        <div className="relative z-10 flex items-center gap-3">
          <div className="bg-white p-2 rounded-xl shadow-lg shadow-black/50">
            <img src={LOGO_URL} alt="Logo" className="h-8 w-auto" />
          </div>
          <div>
            <div className="text-xl font-bold tracking-tight">监管报送一体化系统</div>
            <div className="text-xs text-slate-400 tracking-[0.2em] uppercase mt-0.5">Integrated Reporting Portal</div>
          </div>
        </div>

        <div className="relative z-10 max-w-lg">
          <h2 className="text-4xl font-bold leading-tight mb-6 text-slate-100">
            数据驱动监管，<br />
            合规护航金融安全。
          </h2>
          <div className="flex items-center gap-4 text-slate-400">
            <div className="h-[1px] w-8 bg-red-600" />
            <span className="text-sm font-medium uppercase tracking-widest">Security & Compliance First</span>
          </div>
        </div>

        <div className="relative z-10 flex items-center justify-between text-xs text-slate-500 border-t border-slate-800/50 pt-8">
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <Activity size={14} className="text-red-500" />
              <span>实时监测</span>
            </div>
            <div className="flex items-center gap-2">
              <Landmark size={14} className="text-blue-500" />
              <span>合规报送</span>
            </div>
          </div>
          <span>Bank of Jilin &copy; 2026</span>
        </div>
      </div>

      {/* Right Login Section - Clean Professional White */}
      <div className="flex items-center justify-center p-8 bg-white">
        <div className="w-full max-w-[400px]">
          {/* Mobile Logo */}
          <div className="lg:hidden flex items-center justify-center gap-3 mb-12">
            <img src={LOGO_URL} alt="Logo" className="h-10 w-auto" />
            <span className="text-xl font-bold text-slate-900">监管报送一体化系统</span>
          </div>

          {/* Header */}
          <div className="mb-10">
            <h1 className="text-2xl font-bold text-slate-900 mb-2">欢迎登录</h1>
            <p className="text-slate-500 text-sm">请验证您的身份以继续操作</p>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-1.5">
              <label htmlFor="username" className="text-xs font-bold text-slate-700 uppercase tracking-wider ml-0.5">
                工号 / 用户名
              </label>
              <div className="relative group">
                <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-red-600 transition-colors">
                  <User size={18} />
                </div>
                <input
                  id="username"
                  type="text"
                  required
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="请输入您的工号"
                  className="w-full h-12 pl-10 pr-4 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-red-500/10 focus:border-red-600 transition-all placeholder:text-slate-400"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label htmlFor="password" className="text-xs font-bold text-slate-700 uppercase tracking-wider ml-0.5">
                登录密码
              </label>
              <div className="relative group">
                <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-red-600 transition-colors">
                  <Lock size={18} />
                </div>
                <input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="请输入密码"
                  className="w-full h-12 pl-10 pr-10 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-red-500/10 focus:border-red-600 transition-all placeholder:text-slate-400"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer group">
                <input
                  type="checkbox"
                  id="remember"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="w-4 h-4 rounded border-slate-300 text-red-600 focus:ring-red-500 cursor-pointer transition-all"
                />
                <span className="text-sm text-slate-600 group-hover:text-slate-900 transition-colors">记住我</span>
              </label>
              <button type="button" className="text-sm text-red-600 hover:text-red-700 font-semibold transition-colors">
                忘记密码?
              </button>
            </div>

            {error && (
              <div className="p-3 text-xs text-red-600 bg-red-50 border border-red-100 rounded-lg animate-shake">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full h-12 bg-slate-900 hover:bg-black text-white rounded-xl font-bold text-sm transition-all active:scale-[0.98] disabled:opacity-70 disabled:pointer-events-none shadow-lg shadow-slate-200 flex items-center justify-center gap-2"
            >
              {loading ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <>
                  登录系统
                  <ChevronRight size={18} />
                </>
              )}
            </button>
          </form>

          {/* Footer */}
          <div className="mt-12 flex items-center justify-center gap-2 text-slate-400">
            <ShieldCheck size={14} strokeWidth={2.5} />
            <span className="text-[10px] uppercase tracking-[0.2em] font-semibold">
              Secure Enterprise Access
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;

