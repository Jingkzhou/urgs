import React, { useState, useEffect } from "react";
import { LOGIN_DARK_LOGO_URL, LOGO_URL } from "../../constants";
import { Lock, User, Eye, EyeOff, ShieldCheck, ChevronRight, Landmark, Activity } from "lucide-react";

/* ── Particle type ─────────────────────────────────────────────── */
interface Particle {
  id: number;
  x: number;          // % of container width
  y: number;          // % of container height
  size: number;       // px
  duration: number;   // seconds for one float cycle
  delay: number;      // initial offset
  opacity: number;
}

/* ── Data stream type ──────────────────────────────────────────── */
interface Stream {
  id: number;
  left: number;       // % from left
  duration: number;
  delay: number;
  height: number;     // px of the streak
}

/* ── Seeded random for deterministic particles per session ─────── */
const seededRandom = (() => {
  let s = Date.now() % 1e5;
  return () => { s = (s * 9301 + 49297) % 233280; return s / 233280; };
})();

const PARTICLES: Particle[] = Array.from({ length: 30 }, (_, i) => ({
  id: i,
  x: seededRandom() * 100,
  y: seededRandom() * 100,
  size: 2 + seededRandom() * 3,
  duration: 6 + seededRandom() * 10,
  delay: -seededRandom() * 15,
  opacity: 0.15 + seededRandom() * 0.35,
}));

const STREAMS: Stream[] = Array.from({ length: 6 }, (_, i) => ({
  id: i,
  left: 5 + seededRandom() * 90,
  duration: 4 + seededRandom() * 5,
  delay: -seededRandom() * 8,
  height: 40 + seededRandom() * 80,
}));

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
    <div className="min-h-screen max-h-screen overflow-hidden grid lg:grid-cols-2 bg-slate-50 relative">
      {/* Soft transition gradient to blend dark and light sides */}
      <div className="absolute inset-0 pointer-events-none hidden lg:block z-10"
           style={{ background: 'linear-gradient(90deg, rgba(2,6,23,1) 0%, rgba(248,250,252,0.8) 10%, rgba(248,250,252,0) 30%, rgba(248,250,252,0) 70%, rgba(248,250,252,0.8) 90%, rgba(2,6,23,1) 100%)', opacity: 0.15 }} />

      {/* ── Global keyframes (injected once) ─────────────────────── */}
      <style>{`
        @keyframes particle-float {
          0%, 100% { transform: translateY(0) translateX(0); opacity: var(--p-opa); }
          25%      { transform: translateY(-18px) translateX(6px); opacity: calc(var(--p-opa) + 0.15); }
          50%      { transform: translateY(-8px) translateX(-4px); opacity: var(--p-opa); }
          75%      { transform: translateY(-24px) translateX(8px); opacity: calc(var(--p-opa) + 0.1); }
        }
        @keyframes data-stream {
          0%   { transform: translateY(100vh); opacity: 0; }
          5%   { opacity: var(--s-opa); }
          90%  { opacity: var(--s-opa); }
          100% { transform: translateY(-120px); opacity: 0; }
        }
        @keyframes pulse-glow {
          0%, 100% { opacity: 0.12; transform: scale(1); }
          50%      { opacity: 0.22; transform: scale(1.08); }
        }
        @keyframes border-shimmer {
          0%   { background-position: -200% center; }
          100% { background-position: 200% center; }
        }
        @keyframes input-glow {
          0%, 100% { box-shadow: 0 0 0 0 rgba(239,68,68,0); }
          50%      { box-shadow: 0 0 12px 2px rgba(239,68,68,0.15); }
        }
        .input-glow-wrapper:focus-within { animation: input-glow 1.5s ease-in-out infinite; }
      `}</style>

      {/* ── Left Content Section - Professional Dark Theme ──────── */}
      <div className="relative hidden lg:flex flex-col justify-between bg-slate-950 p-16 text-white overflow-hidden">
        {/* Background Decorations */}
        <div
          className="absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage: `linear-gradient(#fff 1px, transparent 1px), linear-gradient(90deg, #fff 1px, transparent 1px)`,
            backgroundSize: '40px 40px',
          }}
        />

        {/* ── Floating particles ──────────────────────────────── */}
        {PARTICLES.map((p) => (
          <div
            key={p.id}
            className="absolute rounded-full bg-blue-400"
            style={{
              left: `${p.x}%`,
              top: `${p.y}%`,
              width: p.size,
              height: p.size,
              opacity: 0,
              animation: `particle-float ${p.duration}s ease-in-out infinite`,
              animationDelay: `${p.delay}s`,
              ['--p-opa' as string]: p.opacity,
            }}
          />
        ))}

        {/* ── Data flow light streaks ─────────────────────────── */}
        {STREAMS.map((s) => (
          <div
            key={s.id}
            className="absolute rounded-full"
            style={{
              left: `${s.left}%`,
              bottom: 0,
              width: 1.5,
              height: s.height,
              background: `linear-gradient(to top, transparent, rgba(59,130,246,0.5), rgba(239,68,68,0.4), transparent)`,
              animation: `data-stream ${s.duration}s linear infinite`,
              animationDelay: `${s.delay}s`,
              ['--s-opa' as string]: 0.3 + seededRandom() * 0.4,
            }}
          />
        ))}

        {/* ── Ambient glow blobs (animated) ───────────────────── */}
        <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] rounded-full bg-blue-600/20 blur-[120px]"
             style={{ animation: 'pulse-glow 8s ease-in-out infinite' }} />
        <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] rounded-full bg-red-600/10 blur-[100px]"
             style={{ animation: 'pulse-glow 12s ease-in-out infinite 2s' }} />

        <div className="relative z-10 flex items-center">
          <div className="bg-transparent p-0 animate-in zoom-in duration-700 relative overflow-hidden">
            {/* shimmer overlay */}
            <div className="absolute inset-0 opacity-100"
                 style={{ background: 'linear-gradient(105deg, transparent 40%, rgba(59,130,246,0.18) 45%, rgba(239,68,68,0.16) 50%, transparent 55%)', backgroundSize: '200% 100%', animation: 'border-shimmer 3s linear infinite' }} />
            <img src={LOGIN_DARK_LOGO_URL} alt="监管报送一体化系统" className="w-[360px] max-w-full h-auto relative z-10" />
          </div>
        </div>

        <div className="relative z-10 max-w-lg animate-in fade-in slide-in-from-left-8 duration-1000 ease-out">
          <h2 className="text-4xl font-bold leading-tight mb-6 text-slate-100">
            数据驱动监管，<br />
            合规护航金融安全。
          </h2>
          <div className="flex items-center gap-4 text-slate-400 animate-in fade-in slide-in-from-left-12 duration-1000 delay-300 ease-out">
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
          <div className="lg:hidden flex items-center justify-center mb-12">
            <div className="relative overflow-hidden">
              <div className="absolute inset-0 opacity-100 pointer-events-none"
                   style={{ background: 'linear-gradient(105deg, transparent 40%, rgba(59,130,246,0.18) 45%, rgba(239,68,68,0.16) 50%, transparent 55%)', backgroundSize: '200% 100%', animation: 'border-shimmer 3s linear infinite' }} />
              <img src={LOGO_URL} alt="监管报送一体化系统" className="w-[320px] max-w-full h-auto relative z-10" />
            </div>
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
              <div className="relative group input-glow-wrapper">
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
              <div className="relative group input-glow-wrapper">
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
              className="relative w-full h-12 bg-slate-900 hover:bg-black text-white rounded-xl font-bold text-sm transition-all active:scale-[0.98] disabled:opacity-70 disabled:pointer-events-none shadow-lg shadow-slate-200 flex items-center justify-center gap-2 overflow-hidden"
            >
              {/* shimmer border on hover */}
              {!loading && (
                <span className="absolute inset-0 rounded-xl opacity-0 hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                      style={{ background: 'linear-gradient(90deg, transparent, rgba(239,68,68,0.4), rgba(59,130,246,0.4), transparent)', backgroundSize: '200% 100%', animation: 'border-shimmer 2.5s linear infinite' }} />
              )}
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
