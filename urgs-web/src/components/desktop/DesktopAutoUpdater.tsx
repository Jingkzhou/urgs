import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Alert, Button, Modal } from 'antd';
import { Download, RefreshCw } from 'lucide-react';
import { relaunch } from '@tauri-apps/plugin-process';
import { check, type Update } from '@tauri-apps/plugin-updater';
import { isDesktopRuntime } from '@/config';

type UpdatePhase = 'idle' | 'downloading' | 'ready' | 'installing' | 'error';

const UPDATE_CHECK_INTERVAL_MS = 60_000;

const DesktopAutoUpdater: React.FC = () => {
    const updateRef = useRef<Update | null>(null);
    const checkingRef = useRef(false);
    const [phase, setPhase] = useState<UpdatePhase>('idle');
    const [visible, setVisible] = useState(false);
    const [version, setVersion] = useState('');
    const [notes, setNotes] = useState('');
    const [errorMessage, setErrorMessage] = useState('');

    const checkAndDownload = useCallback(async (forceRetry = false) => {
        if (checkingRef.current || (updateRef.current && !forceRetry)) {
            return;
        }

        checkingRef.current = true;
        setErrorMessage('');
        try {
            if (updateRef.current) {
                await updateRef.current.close();
                updateRef.current = null;
            }

            const update = await check({ timeout: 30_000 });
            if (!update) {
                setPhase('idle');
                setVisible(false);
                return;
            }

            updateRef.current = update;
            setVersion(update.version);
            setNotes(update.body || '本次更新包含功能改进与问题修复。');
            setPhase('downloading');
            setVisible(false);
            await update.download(undefined, { timeout: 10 * 60_000 });
            setPhase('ready');
            setVisible(true);
        } catch (error) {
            console.warn('Desktop update check or download failed', error);
            if (updateRef.current) {
                setErrorMessage(error instanceof Error ? error.message : '更新下载失败，请稍后重试');
                setPhase('error');
                setVisible(true);
            }
        } finally {
            checkingRef.current = false;
        }
    }, []);

    useEffect(() => {
        if (!isDesktopRuntime()) {
            return;
        }

        const timer = window.setTimeout(() => {
            void checkAndDownload();
        }, 1_500);
        const interval = window.setInterval(() => {
            void checkAndDownload();
        }, UPDATE_CHECK_INTERVAL_MS);
        const checkWhenVisible = () => {
            if (!document.hidden) {
                void checkAndDownload();
            }
        };

        document.addEventListener('visibilitychange', checkWhenVisible);
        return () => {
            window.clearTimeout(timer);
            window.clearInterval(interval);
            document.removeEventListener('visibilitychange', checkWhenVisible);
        };
    }, [checkAndDownload]);

    const installAndRestart = async () => {
        if (!updateRef.current) return;
        setPhase('installing');
        setErrorMessage('');
        try {
            await updateRef.current.install();
            await relaunch();
        } catch (error) {
            console.error('Desktop update installation failed', error);
            setErrorMessage(error instanceof Error ? error.message : '更新安装失败，请稍后重试');
            setPhase('error');
            setVisible(true);
        }
    };

    if (!isDesktopRuntime()) {
        return null;
    }

    return (
        <>
            {phase === 'ready' && !visible && (
                <Button
                    type="primary"
                    icon={<RefreshCw size={15} />}
                    className="fixed bottom-5 right-5 z-[1100] shadow-lg"
                    onClick={() => setVisible(true)}
                >
                    新版本已就绪 · 重启更新
                </Button>
            )}

            <Modal
                open={visible}
                title={phase === 'ready' ? `监管一体化系统 ${version} 已下载` : '监管一体化系统自动更新'}
                closable={false}
                maskClosable={false}
                keyboard={false}
                footer={phase === 'ready' ? [
                    <Button key="later" onClick={() => setVisible(false)}>
                        稍后重启
                    </Button>,
                    <Button key="restart" type="primary" icon={<RefreshCw size={15} />} onClick={installAndRestart}>
                        立即重启并更新
                    </Button>,
                ] : phase === 'error' ? [
                    <Button key="later" onClick={() => setVisible(false)}>
                        稍后处理
                    </Button>,
                    <Button key="retry" type="primary" icon={<Download size={15} />} onClick={() => void checkAndDownload(true)}>
                        重新下载
                    </Button>,
                ] : null}
            >
                {phase === 'ready' && (
                    <div className="space-y-4 py-2">
                        <Alert
                            type="success"
                            showIcon
                            message="更新已准备完成"
                            description="点击“立即重启并更新”后，客户端会自动安装并重新打开，无需手工运行安装包。"
                        />
                        <div>
                            <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">更新说明</p>
                            <p className="max-h-40 whitespace-pre-wrap overflow-y-auto text-sm leading-6 text-slate-600">{notes}</p>
                        </div>
                    </div>
                )}

                {phase === 'installing' && (
                    <div className="py-4 text-center text-sm text-slate-600">
                        正在启动更新程序，客户端将自动关闭并重新打开…
                    </div>
                )}

                {phase === 'error' && (
                    <Alert
                        type="error"
                        showIcon
                        message="自动更新未完成"
                        description={errorMessage || '请检查网络连接后重试。'}
                    />
                )}
            </Modal>
        </>
    );
};

export default DesktopAutoUpdater;
