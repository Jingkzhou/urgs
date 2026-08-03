import React, { useState, useEffect, useRef } from "react";
import { LOGIN_DARK_LOGO_URL, LOGIN_LOGO_URL } from "../../constants";
import { Lock, User, Eye, EyeOff, ShieldCheck, ChevronRight, Landmark, Activity, ServerCog } from "lucide-react";
import { isDesktopRuntime } from "../../config";
import { openExternalUrl } from "../../utils/desktopRuntime";
import DesktopInstallerDownload from "../desktop/DesktopInstallerDownload";

/* ── Particle type ─────────────────────────────────────────────── */
interface Particle {
  id: number;
  x: number;          // % of container width
  y: number;          // % of container height
  size: number;       // px
  duration: number;   // seconds for one float cycle
  opacity: number;
  phase: number;
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
  let s = 4187;
  return () => { s = (s * 9301 + 49297) % 233280; return s / 233280; };
})();

const PARTICLES: Particle[] = Array.from({ length: 30 }, (_, i) => ({
  id: i,
  x: seededRandom() * 100,
  y: seededRandom() * 100,
  size: 2 + seededRandom() * 3,
  duration: 6 + seededRandom() * 10,
  opacity: 0.15 + seededRandom() * 0.35,
  phase: seededRandom() * Math.PI * 2,
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
  const solarOrbitRefs = useRef<Array<HTMLDivElement | null>>([]);
  const particleRefs = useRef<Array<HTMLDivElement | null>>([]);
  const streamRefs = useRef<Array<HTMLDivElement | null>>([]);
  const glowRefs = useRef<Array<HTMLDivElement | null>>([]);

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

  useEffect(() => {
    const startTime = performance.now();
    const orbitPeriods = [9000, -15000, 3200, 24000];
    let animationFrame = 0;

    const animateSolarSystem = (timestamp: number) => {
      const elapsed = timestamp - startTime;
      solarOrbitRefs.current.forEach((element, index) => {
        if (!element) {
          return;
        }
        const period = orbitPeriods[index];
        const angle = (elapsed / Math.abs(period)) * 360 * Math.sign(period);
        element.style.transform = `rotate(${angle}deg)`;
      });

      particleRefs.current.forEach((element, index) => {
        const particle = PARTICLES[index];
        if (!element || !particle) {
          return;
        }
        const phase = (elapsed / (particle.duration * 1000)) * Math.PI * 2 + particle.phase;
        element.style.transform = `translate(${Math.sin(phase) * 8}px, ${Math.cos(phase * 0.82) * 18}px)`;
        element.style.opacity = `${particle.opacity + (Math.sin(phase) + 1) * 0.05}`;
      });

      streamRefs.current.forEach((element, index) => {
        const stream = STREAMS[index];
        if (!element || !stream) {
          return;
        }
        const duration = stream.duration * 1000;
        const elapsedWithDelay = elapsed + stream.delay * 1000;
        const progress = (((elapsedWithDelay % duration) + duration) % duration) / duration;
        const fadeIn = Math.min(progress / 0.06, 1);
        const fadeOut = Math.min((1 - progress) / 0.12, 1);
        element.style.transform = `translateY(${(1 - progress) * 118 - 10}vh)`;
        element.style.opacity = `${Math.min(fadeIn, fadeOut) * 0.65}`;
      });

      glowRefs.current.forEach((element, index) => {
        if (!element) {
          return;
        }
        const cycle = (elapsed / (index === 0 ? 8000 : 12000)) * Math.PI * 2 + (index === 0 ? 0 : Math.PI);
        element.style.opacity = `${0.11 + (Math.sin(cycle) + 1) * 0.035}`;
        element.style.transform = `scale(${1 + (Math.sin(cycle) + 1) * 0.035})`;
      });
      animationFrame = requestAnimationFrame(animateSolarSystem);
    };

    animationFrame = requestAnimationFrame(animateSolarSystem);
    return () => cancelAnimationFrame(animationFrame);
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
          orgName: data.orgName,
          phone: data.phone,
          avatarUrl: data.avatarUrl,
        })
      );

      const params = new URLSearchParams(window.location.search);
      const clientId = params.get("client_id");
      const redirectUri = params.get("redirect_uri");
      const state = params.get("state");

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
              state,
            }),
          });

          if (authRes.ok) {
            const authData = await authRes.json();
            const separator = authData.redirect_uri.includes("?") ? "&" : "?";
            const stateQuery = authData.state ? `&state=${encodeURIComponent(authData.state)}` : "";
            const targetUrl = `${authData.redirect_uri}${separator}code=${encodeURIComponent(authData.code)}${stateQuery}`;
            if (isDesktopRuntime()) {
              await openExternalUrl(targetUrl);
            } else {
              window.location.href = targetUrl;
            }
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
        orgName: data.orgName,
        phone: data.phone,
        avatarUrl: data.avatarUrl,
      });
    } catch (err: any) {
      console.error("Login error:", err);
      setError(err.message || "连接服务器失败，请检查网络");
      setLoading(false);
    }
  };

  return (
    <div className="relative grid min-h-[100dvh] w-full overflow-hidden bg-slate-50 xl:grid-cols-[minmax(0,1fr)_minmax(560px,1.1fr)]">
      {isDesktopRuntime() && (
        <button
          type="button"
          onClick={() => {
            localStorage.setItem('urgs_desktop_edit_connection', '1');
            window.location.reload();
          }}
          className="absolute right-5 top-5 z-50 flex items-center gap-2 rounded-xl border border-slate-200 bg-white/90 px-3 py-2 text-xs font-bold text-slate-600 shadow-sm backdrop-blur transition hover:border-blue-200 hover:text-blue-600"
        >
          <ServerCog size={15} />
          连接设置
        </button>
      )}
      {/* Soft transition gradient to blend dark and light sides */}
      <div className="absolute inset-0 z-10 hidden pointer-events-none xl:block"
           style={{ background: 'linear-gradient(90deg, rgba(2,6,23,1) 0%, rgba(248,250,252,0.8) 10%, rgba(248,250,252,0) 30%, rgba(248,250,252,0) 70%, rgba(248,250,252,0.8) 90%, rgba(2,6,23,1) 100%)', opacity: 0.15 }} />

      {/* ── Global keyframes (injected once) ─────────────────────── */}
      <style>{`
        .solar-sun {
          background-color: #f59e0b;
          background-image:
            radial-gradient(circle at 35% 30%, rgba(255,255,255,0.95) 0%, rgba(255,244,164,0.92) 20%, rgba(255,244,164,0) 34%),
            radial-gradient(circle at 62% 68%, rgba(248,113,113,0.45) 0%, rgba(248,113,113,0) 24%),
            radial-gradient(circle at 35% 35%, #fff7ad 0%, #fbbf24 38%, #f97316 68%, #b45309 100%);
        }
        .planet-mars {
          background-color: #dc2626;
          background-image:
            radial-gradient(circle at 30% 28%, rgba(255,237,213,0.9) 0%, rgba(255,237,213,0) 20%),
            linear-gradient(150deg, transparent 0%, transparent 28%, rgba(127,29,29,0.45) 38%, transparent 48%, transparent 60%, rgba(251,146,60,0.4) 70%, transparent 80%),
            radial-gradient(circle at 35% 35%, #fca5a5 0%, #ef4444 42%, #991b1b 100%);
        }
        .planet-earth {
          background-color: #2563eb;
          background-image:
            radial-gradient(circle at 30% 24%, rgba(255,255,255,0.75) 0%, rgba(255,255,255,0) 18%),
            linear-gradient(35deg, transparent 0%, transparent 18%, rgba(255,255,255,0.68) 27%, transparent 36%, transparent 45%, rgba(255,255,255,0.5) 54%, transparent 64%),
            radial-gradient(circle at 66% 36%, rgba(34,197,94,0.95) 0%, rgba(34,197,94,0) 28%),
            radial-gradient(circle at 38% 68%, rgba(34,197,94,0.85) 0%, rgba(34,197,94,0) 24%),
            radial-gradient(circle at 35% 35%, #7dd3fc 0%, #2563eb 46%, #0f172a 100%);
        }
        .planet-moon {
          background-color: #cbd5e1;
          background-image:
            radial-gradient(circle at 62% 34%, rgba(71,85,105,0.45) 0%, rgba(71,85,105,0) 32%),
            radial-gradient(circle at 36% 66%, rgba(71,85,105,0.35) 0%, rgba(71,85,105,0) 26%),
            radial-gradient(circle at 35% 35%, #f8fafc 0%, #cbd5e1 58%, #64748b 100%);
        }
        .planet-saturn {
          background-color: #d97706;
          background-image:
            radial-gradient(circle at 30% 30%, rgba(255,255,255,0.75) 0%, rgba(255,255,255,0) 26%),
            linear-gradient(180deg, transparent 0%, transparent 28%, rgba(255,237,213,0.55) 36%, transparent 46%, transparent 58%, rgba(180,83,9,0.35) 66%, transparent 76%),
            radial-gradient(circle at 35% 35%, #fde68a 0%, #d97706 54%, #78350f 100%);
        }
      `}</style>

      {/* ── Left Content Section - Professional Dark Theme ──────── */}
      <div className="relative hidden overflow-hidden bg-slate-950 p-10 text-white xl:flex xl:flex-col xl:justify-between 2xl:p-16">
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
            ref={(element) => { particleRefs.current[p.id] = element; }}
            className="absolute rounded-full bg-blue-400"
            style={{
              left: `${p.x}%`,
              top: `${p.y}%`,
              width: p.size,
              height: p.size,
              opacity: p.opacity,
            }}
          />
        ))}

        {/* ── Data flow light streaks ─────────────────────────── */}
        {STREAMS.map((s) => (
          <div
            key={s.id}
            ref={(element) => { streamRefs.current[s.id] = element; }}
            className="absolute rounded-full"
            style={{
              left: `${s.left}%`,
              bottom: 0,
              width: 1.5,
              height: s.height,
              background: `linear-gradient(to top, transparent, rgba(59,130,246,0.5), rgba(239,68,68,0.4), transparent)`,
              opacity: 0,
            }}
          />
        ))}

        {/* ── Ambient glow blobs (animated) ───────────────────── */}
        <div ref={(element) => { glowRefs.current[0] = element; }}
             className="absolute top-[-10%] left-[-10%] h-[50%] w-[50%] rounded-full bg-blue-600/20 blur-[120px]"
             style={{ opacity: 0.14 }} />
        <div ref={(element) => { glowRefs.current[1] = element; }}
             className="absolute bottom-[-10%] right-[-10%] h-[40%] w-[40%] rounded-full bg-red-600/10 blur-[100px]"
             style={{ opacity: 0.14 }} />

        <div className="pointer-events-none absolute right-6 top-1/2 z-0 h-[270px] w-[270px] -translate-y-1/2 opacity-65 2xl:right-12 2xl:h-[300px] 2xl:w-[300px]">
          <div
            className="solar-sun absolute left-1/2 top-1/2 h-12 w-12 -translate-x-1/2 -translate-y-1/2 rounded-full shadow-[0_0_54px_rgba(251,191,36,0.95),0_0_110px_rgba(249,115,22,0.28)]"
            style={{
              backgroundColor: "#f59e0b",
              backgroundImage: "radial-gradient(circle at 35% 30%, rgba(255,255,255,0.95) 0%, rgba(255,244,164,0.92) 20%, rgba(255,244,164,0) 34%), radial-gradient(circle at 62% 68%, rgba(248,113,113,0.45) 0%, rgba(248,113,113,0) 24%), radial-gradient(circle at 35% 35%, #fff7ad 0%, #fbbf24 38%, #f97316 68%, #b45309 100%)",
            }}
          />
          <div ref={(element) => { solarOrbitRefs.current[0] = element; }}
               className="absolute inset-[80px] rounded-full border border-slate-500/35 2xl:inset-[88px]">
            <div
              className="planet-mars absolute left-1/2 top-[-7px] h-3.5 w-3.5 -translate-x-1/2 rounded-full shadow-[inset_-3px_-3px_5px_rgba(15,23,42,0.55),0_0_13px_rgba(239,68,68,0.72)]"
              style={{
                backgroundColor: "#dc2626",
                backgroundImage: "radial-gradient(circle at 30% 28%, rgba(255,237,213,0.9) 0%, rgba(255,237,213,0) 20%), linear-gradient(150deg, transparent 0%, transparent 28%, rgba(127,29,29,0.45) 38%, transparent 48%, transparent 60%, rgba(251,146,60,0.4) 70%, transparent 80%), radial-gradient(circle at 35% 35%, #fca5a5 0%, #ef4444 42%, #991b1b 100%)",
              }}
            />
          </div>
          <div ref={(element) => { solarOrbitRefs.current[1] = element; }}
               className="absolute inset-[50px] rounded-full border border-slate-500/35 2xl:inset-[56px]">
            <div
              className="planet-earth absolute left-1/2 top-[-10px] h-5 w-5 -translate-x-1/2 rounded-full shadow-[inset_-5px_-4px_7px_rgba(15,23,42,0.62),0_0_18px_rgba(96,165,250,0.75)]"
              style={{
                backgroundColor: "#2563eb",
                backgroundImage: "radial-gradient(circle at 30% 24%, rgba(255,255,255,0.75) 0%, rgba(255,255,255,0) 18%), linear-gradient(35deg, transparent 0%, transparent 18%, rgba(255,255,255,0.68) 27%, transparent 36%, transparent 45%, rgba(255,255,255,0.5) 54%, transparent 64%), radial-gradient(circle at 66% 36%, rgba(34,197,94,0.95) 0%, rgba(34,197,94,0) 28%), radial-gradient(circle at 38% 68%, rgba(34,197,94,0.85) 0%, rgba(34,197,94,0) 24%), radial-gradient(circle at 35% 35%, #7dd3fc 0%, #2563eb 46%, #0f172a 100%)",
              }}
            >
              <div className="absolute left-1/2 top-1/2 h-11 w-11 -translate-x-1/2 -translate-y-1/2">
                <div ref={(element) => { solarOrbitRefs.current[2] = element; }}
                     className="relative h-full w-full">
                  <div
                    className="planet-moon absolute left-1/2 top-[-4px] h-2 w-2 -translate-x-1/2 rounded-full shadow-[inset_-1px_-1px_2px_rgba(15,23,42,0.45),0_0_6px_rgba(226,232,240,0.65)]"
                    style={{
                      backgroundColor: "#cbd5e1",
                      backgroundImage: "radial-gradient(circle at 62% 34%, rgba(71,85,105,0.45) 0%, rgba(71,85,105,0) 32%), radial-gradient(circle at 36% 66%, rgba(71,85,105,0.35) 0%, rgba(71,85,105,0) 26%), radial-gradient(circle at 35% 35%, #f8fafc 0%, #cbd5e1 58%, #64748b 100%)",
                    }}
                  />
                </div>
              </div>
            </div>
          </div>
          <div ref={(element) => { solarOrbitRefs.current[3] = element; }}
               className="absolute inset-[18px] rounded-full border border-slate-500/30 2xl:inset-[20px]">
            <div
              className="planet-saturn absolute left-1/2 top-[-12px] h-6 w-6 -translate-x-1/2 rounded-full shadow-[inset_-5px_-5px_8px_rgba(15,23,42,0.58),0_0_18px_rgba(251,191,36,0.45)]"
              style={{
                backgroundColor: "#d97706",
                backgroundImage: "radial-gradient(circle at 30% 30%, rgba(255,255,255,0.75) 0%, rgba(255,255,255,0) 26%), linear-gradient(180deg, transparent 0%, transparent 28%, rgba(255,237,213,0.55) 36%, transparent 46%, transparent 58%, rgba(180,83,9,0.35) 66%, transparent 76%), radial-gradient(circle at 35% 35%, #fde68a 0%, #d97706 54%, #78350f 100%)",
              }}
            />
          </div>
        </div>

        <div className="relative z-10 flex items-center">
          <div className="relative overflow-hidden bg-transparent p-0">
            {/* shimmer overlay */}
            <img src={LOGIN_DARK_LOGO_URL} alt="监管报送一体化系统" className="relative z-10 h-36 w-36 object-contain 2xl:h-44 2xl:w-44" />
          </div>
        </div>

        <div className="relative z-10 max-w-lg">
          <h2 className="mb-5 text-3xl font-bold leading-tight text-slate-100 2xl:mb-6 2xl:text-4xl">
            数据驱动监管，<br />
            合规护航金融安全。
          </h2>
          <div className="flex items-center gap-4 text-slate-400">
            <div className="h-[1px] w-8 bg-red-600" />
            <span className="text-sm font-medium uppercase tracking-widest">Security & Compliance First</span>
          </div>
        </div>

        <div className="relative z-10 flex items-center justify-between border-t border-slate-800/50 pt-6 text-xs text-slate-500 2xl:pt-8">
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
      <div className="relative flex min-w-0 items-center justify-center overflow-hidden bg-white p-6 sm:p-10 xl:p-14 2xl:p-16">
        <div className="relative z-10 w-full max-w-[400px]">
          {/* Mobile Logo */}
          <div className="mb-8 flex items-center justify-center xl:hidden sm:mb-12">
            <div className="relative overflow-hidden">
              <img src={LOGIN_LOGO_URL} alt="监管报送一体化系统" className="relative z-10 h-28 w-28 object-contain" />
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
              <div className="p-3 text-xs text-red-600 bg-red-50 border border-red-100 rounded-lg">
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
                      style={{ background: 'linear-gradient(90deg, transparent, rgba(239,68,68,0.25), rgba(59,130,246,0.25), transparent)' }} />
              )}
              {loading ? (
                <span className="text-sm">正在登录...</span>
              ) : (
                <>
                  登录系统
                  <ChevronRight size={18} />
                </>
              )}
            </button>
          </form>

          <DesktopInstallerDownload />

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
