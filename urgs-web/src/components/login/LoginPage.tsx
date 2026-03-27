import React, { useState, useEffect } from "react";
import { LOGO_URL } from "../../constants";
import { Lock, User, Eye, EyeOff, ShieldCheck } from "lucide-react";
import AnimatedCharacters from "./AnimatedCharacters";
import InteractiveHoverButton from "./InteractiveButton";

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
  const [isTyping, setIsTyping] = useState(false);

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
    <div className="min-h-screen max-h-screen overflow-hidden grid lg:grid-cols-2">
      {/* Left Content Section with Animated Characters */}
      <div className="relative hidden lg:flex flex-col justify-between bg-gradient-to-br from-gray-400 via-gray-500 to-gray-600 p-12 text-white">
        <div className="relative z-20">
          <div className="flex items-center gap-2 text-lg font-semibold">
            <img
              src={LOGO_URL}
              alt="Logo"
              className="h-8 w-auto bg-white/10 backdrop-blur-sm p-1 rounded-lg"
            />
            <span>监管报送一体化系统</span>
          </div>
        </div>

        <div className="relative z-20 flex items-end justify-center h-[500px]">
          <AnimatedCharacters
            isTyping={isTyping}
            showPassword={showPassword}
            passwordLength={password.length}
          />
        </div>

        <div className="relative z-20 flex items-center gap-8 text-sm text-gray-300">
          <span>Integrated Reporting Portal</span>
          <span>Bank of Jilin &copy; 2026</span>
        </div>

        {/* Decorative elements */}
        <div
          className="absolute inset-0 opacity-5"
          style={{
            backgroundImage:
              "linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)",
            backgroundSize: "20px 20px",
          }}
        />
        <div className="absolute top-1/4 right-1/4 w-64 h-64 bg-gray-400/20 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 left-1/4 w-96 h-96 bg-gray-300/20 rounded-full blur-3xl" />
      </div>

      {/* Right Login Section */}
      <div className="flex items-center justify-center p-8 bg-white">
        <div className="w-full max-w-[420px]">
          {/* Mobile Logo */}
          <div className="lg:hidden flex items-center justify-center gap-2 text-lg font-semibold mb-12">
            <img src={LOGO_URL} alt="Logo" className="h-8 w-auto" />
            <span>监管报送一体化系统</span>
          </div>

          {/* Header */}
          <div className="text-center mb-10">
            <h1 className="text-3xl font-bold tracking-tight mb-2">
              欢迎回来
            </h1>
            <p className="text-gray-400 text-sm">请输入您的账户信息</p>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="space-y-2">
              <label
                htmlFor="username"
                className="text-sm font-medium text-gray-700 flex items-center gap-1.5"
              >
                <User size={14} className="text-gray-400" />
                用户名
              </label>
              <input
                id="username"
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                onFocus={() => setIsTyping(true)}
                onBlur={() => setIsTyping(false)}
                placeholder="请输入您的工号"
                className="w-full h-12 px-4 bg-white border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900/10 focus:border-gray-400 transition-colors"
              />
            </div>

            <div className="space-y-2">
              <label
                htmlFor="password"
                className="text-sm font-medium text-gray-700 flex items-center gap-1.5"
              >
                <Lock size={14} className="text-gray-400" />
                密码
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="请输入密码"
                  className="w-full h-12 px-4 pr-10 bg-white border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900/10 focus:border-gray-400 transition-colors"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                >
                  {showPassword ? (
                    <EyeOff className="w-5 h-5" />
                  ) : (
                    <Eye className="w-5 h-5" />
                  )}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="remember"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="w-4 h-4 rounded border-gray-300 text-gray-900 focus:ring-gray-900/20 cursor-pointer"
                />
                <label
                  htmlFor="remember"
                  className="text-sm font-normal cursor-pointer text-gray-600"
                >
                  记住我
                </label>
              </div>
              <button
                type="button"
                className="text-sm text-gray-900 hover:underline font-medium"
              >
                忘记密码?
              </button>
            </div>

            {error && (
              <div className="p-3 text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg">
                {error}
              </div>
            )}

            <InteractiveHoverButton
              type="submit"
              text={loading ? "登录中..." : "登 录"}
              className="w-full h-12 text-base font-medium"
              disabled={loading}
            />
          </form>

          {/* Footer */}
          <div className="mt-10 flex items-center justify-center gap-2 text-gray-300">
            <ShieldCheck size={14} strokeWidth={2.5} />
            <span className="text-xs tracking-wider">
              Verified Secure Portal
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
