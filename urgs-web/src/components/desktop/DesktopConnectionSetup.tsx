import React, { useMemo, useState } from 'react';
import {
    deriveWebSocketUrl,
    getApiBaseUrl,
    WS_URL,
    type RuntimeConfig,
} from '@/config';
import { saveDesktopRuntimeConfig } from '@/utils/desktopRuntime';
import DesktopAutostartSetting from './DesktopAutostartSetting';

const validateUrl = (value: string, protocols: string[], fieldName: string) => {
    let parsed: URL;
    try {
        parsed = new URL(value);
    } catch {
        throw new Error(`${fieldName}格式不正确`);
    }

    if (!protocols.includes(parsed.protocol)) {
        throw new Error(`${fieldName}仅支持 ${protocols.join('、')} 协议`);
    }
};

const DesktopConnectionSetup: React.FC = () => {
    const [apiUrl, setApiUrl] = useState(() => getApiBaseUrl() || 'http://localhost:8080');
    const [wsUrl, setWsUrl] = useState(() => WS_URL || 'ws://localhost:8080/ws/im');
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState('');

    const suggestedWsUrl = useMemo(() => {
        try {
            return deriveWebSocketUrl(apiUrl);
        } catch {
            return '';
        }
    }, [apiUrl]);

    const handleApiUrlBlur = () => {
        if (!wsUrl.trim() || wsUrl === 'ws://localhost:8080/ws/im') {
            setWsUrl(suggestedWsUrl);
        }
    };

    const handleSubmit = async (event: React.FormEvent) => {
        event.preventDefault();
        setError('');

        const config: Required<RuntimeConfig> = {
            VITE_API_URL: apiUrl.trim().replace(/\/+$/, ''),
            VITE_WS_URL: wsUrl.trim().replace(/\/+$/, ''),
        };

        try {
            validateUrl(config.VITE_API_URL, ['http:', 'https:'], 'API 服务地址');
            validateUrl(config.VITE_WS_URL, ['ws:', 'wss:'], 'WebSocket 地址');
            setSaving(true);
            await saveDesktopRuntimeConfig(config);
            localStorage.removeItem('urgs_desktop_edit_connection');
            window.location.reload();
        } catch (saveError) {
            setError(saveError instanceof Error ? saveError.message : '保存客户端配置失败');
            setSaving(false);
        }
    };

    return (
        <div className="flex min-h-screen items-center justify-center bg-slate-950 px-6 py-10">
            <div className="w-full max-w-xl rounded-3xl border border-white/10 bg-white p-8 shadow-2xl">
                <div className="mb-8 flex items-center gap-4">
                    <img src="/jlbank_logo_transparent.png" alt="URGS" className="h-16 w-16 object-contain" />
                    <div>
                        <p className="text-xs font-bold uppercase tracking-[0.24em] text-blue-600">URGS Desktop</p>
                        <h1 className="mt-1 text-2xl font-black text-slate-900">连接服务器</h1>
                        <p className="mt-1 text-sm text-slate-500">首次启动需要配置监管报送一体化系统的服务地址。</p>
                    </div>
                </div>

                <form className="space-y-5" onSubmit={handleSubmit}>
                    <label className="block">
                        <span className="mb-2 block text-sm font-bold text-slate-700">API 服务根地址</span>
                        <input
                            value={apiUrl}
                            onChange={event => setApiUrl(event.target.value)}
                            onBlur={handleApiUrlBlur}
                            placeholder="https://urgs.example.com"
                            className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100"
                            required
                        />
                    </label>

                    <label className="block">
                        <span className="mb-2 block text-sm font-bold text-slate-700">即时通信 WebSocket 地址</span>
                        <input
                            value={wsUrl}
                            onChange={event => setWsUrl(event.target.value)}
                            placeholder="wss://urgs.example.com/ws/im"
                            className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-blue-500 focus:ring-4 focus:ring-blue-100"
                            required
                        />
                    </label>

                    <DesktopAutostartSetting />

                    {error && (
                        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                            {error}
                        </div>
                    )}

                    <button
                        type="submit"
                        disabled={saving}
                        className="w-full rounded-xl bg-blue-600 px-4 py-3 text-sm font-bold text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        {saving ? '正在保存...' : '保存并进入客户端'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default DesktopConnectionSetup;
