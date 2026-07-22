import React, { useEffect, useState } from 'react';
import { isDesktopRuntime } from '@/config';
import {
    getDesktopAutostartEnabled,
    setDesktopAutostartEnabled,
} from '@/utils/desktopAutostart';

interface DesktopAutostartSettingProps {
    className?: string;
}

const DesktopAutostartSetting: React.FC<DesktopAutostartSettingProps> = ({ className = '' }) => {
    const [enabled, setEnabled] = useState(true);
    const [ready, setReady] = useState(false);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        let active = true;

        void getDesktopAutostartEnabled()
            .then((value) => {
                if (active) {
                    setEnabled(value);
                }
            })
            .catch((loadError) => {
                console.error('读取开机自启动状态失败', loadError);
                if (active) {
                    setError('读取开机自启动状态失败');
                }
            })
            .finally(() => {
                if (active) {
                    setReady(true);
                }
            });

        return () => {
            active = false;
        };
    }, []);

    if (!isDesktopRuntime()) {
        return null;
    }

    const handleChange = async () => {
        setError('');
        setSaving(true);
        try {
            setEnabled(await setDesktopAutostartEnabled(!enabled));
        } catch (saveError) {
            setError(saveError instanceof Error ? saveError.message : '更新开机自启动设置失败');
        } finally {
            setSaving(false);
        }
    };

    return (
        <div className={`rounded-xl border border-slate-200 px-4 py-3 ${className}`}>
            <div className="flex items-center justify-between gap-4">
                <div>
                    <p className="text-sm font-bold text-slate-700">开机自动启动</p>
                    <p className="mt-1 text-xs text-slate-500">登录 Windows 后自动启动 URGS 客户端。</p>
                </div>
                <button
                    type="button"
                    role="switch"
                    aria-checked={enabled}
                    aria-label="开机自动启动"
                    disabled={!ready || saving}
                    onClick={handleChange}
                    className={`relative h-7 w-12 shrink-0 rounded-full transition ${enabled ? 'bg-blue-600' : 'bg-slate-300'} disabled:cursor-not-allowed disabled:opacity-60`}
                >
                    <span
                        className={`absolute top-1 h-5 w-5 rounded-full bg-white shadow transition ${enabled ? 'left-6' : 'left-1'}`}
                    />
                </button>
            </div>
            {error && <p className="mt-2 text-xs text-red-600">{error}</p>}
        </div>
    );
};

export default DesktopAutostartSetting;
