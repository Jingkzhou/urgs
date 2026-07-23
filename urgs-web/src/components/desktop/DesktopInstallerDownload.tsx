import React, { useEffect, useState } from 'react';
import { Download, MonitorDown } from 'lucide-react';
import { isDesktopRuntime } from '@/config';

interface DesktopUpdatePlatform {
    url?: string;
}

interface DesktopUpdateManifest {
    version?: string;
    platforms?: Record<string, DesktopUpdatePlatform>;
}

interface DesktopInstallerRelease {
    version: string;
    installerUrl: string;
    msiUrl?: string;
}

const DesktopInstallerDownload: React.FC = () => {
    const [release, setRelease] = useState<DesktopInstallerRelease | null>(null);

    useEffect(() => {
        if (isDesktopRuntime()) {
            return;
        }

        let disposed = false;

        const loadLatestRelease = async () => {
            try {
                const response = await fetch('/desktop/latest.json', { cache: 'no-store' });
                if (!response.ok) {
                    return;
                }

                const manifest = await response.json() as DesktopUpdateManifest;
                const installerUrl = manifest.platforms?.['windows-x86_64-nsis']?.url
                    ?? manifest.platforms?.['windows-x86_64']?.url;
                if (!manifest.version || !installerUrl || disposed) {
                    return;
                }

                setRelease({
                    version: manifest.version,
                    installerUrl,
                    msiUrl: manifest.platforms?.['windows-x86_64-msi']?.url,
                });
            } catch {
                // 未发布桌面工件或暂时无法访问时，不影响 Web 登录。
            }
        };

        void loadLatestRelease();
        return () => {
            disposed = true;
        };
    }, []);

    if (!release) {
        return null;
    }

    return (
        <div className="mt-6 border-t border-slate-100 pt-5">
            <div className="flex items-center justify-between gap-3">
                <div className="flex min-w-0 items-center gap-2 text-slate-600">
                    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-blue-50 text-blue-600">
                        <MonitorDown size={17} />
                    </span>
                    <div>
                        <p className="text-sm font-semibold text-slate-700">Windows 客户端</p>
                        <p className="text-xs text-slate-400">最新版本 v{release.version}</p>
                    </div>
                </div>
                <a
                    href={release.installerUrl}
                    className="inline-flex shrink-0 items-center gap-1.5 rounded-lg border border-blue-200 bg-blue-50 px-3 py-2 text-xs font-semibold text-blue-700 transition hover:border-blue-300 hover:bg-blue-100"
                >
                    <Download size={15} />
                    下载客户端
                </a>
            </div>
            {release.msiUrl && (
                <a
                    href={release.msiUrl}
                    className="mt-2 block text-right text-[11px] text-slate-400 transition hover:text-blue-600"
                >
                    企业批量部署请下载 MSI 安装包
                </a>
            )}
        </div>
    );
};

export default DesktopInstallerDownload;
