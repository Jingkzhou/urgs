import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Spin, message } from 'antd';
import { createPortal } from 'react-dom';
import { Download, RotateCcw, X } from 'lucide-react';
import type { OnlineDocument } from '../../api/onlineDocs';
import { getOnlineDocumentOnlyOfficeConfig } from '../../api/onlineDocs';
import { userService } from '../../services/userService';

declare global {
    interface Window {
        DocsAPI?: {
            DocEditor: new (placeholderId: string, config: Record<string, unknown>) => {
                destroyEditor?: () => void;
            };
        };
    }
}

interface OnlyOfficeEditorModalProps {
    open: boolean;
    document: OnlineDocument | null;
    onClose: () => void;
    onSaved?: () => void;
    onDownload: (doc: OnlineDocument) => void;
}

const scriptLoaders = new Map<string, Promise<void>>();

const loadOnlyOfficeScript = (documentServerUrl: string) => {
    const baseUrl = documentServerUrl.replace(/\/$/, '');
    const scriptUrl = `${baseUrl}/web-apps/apps/api/documents/api.js`;

    const existingLoader = scriptLoaders.get(scriptUrl);
    if (existingLoader) {
        return existingLoader;
    }

    const loader = new Promise<void>((resolve, reject) => {
        const existingScript = document.querySelector<HTMLScriptElement>(`script[src="${scriptUrl}"]`);
        if (existingScript) {
            if (window.DocsAPI) {
                resolve();
                return;
            }
            existingScript.addEventListener('load', () => resolve(), { once: true });
            existingScript.addEventListener('error', () => reject(new Error('ONLYOFFICE 脚本加载失败')), { once: true });
            return;
        }

        const script = document.createElement('script');
        script.src = scriptUrl;
        script.async = true;
        script.onload = () => resolve();
        script.onerror = () => reject(new Error('ONLYOFFICE 脚本加载失败，请检查 Document Server 地址'));
        document.body.appendChild(script);
    });

    loader.catch(() => {
        scriptLoaders.delete(scriptUrl);
    });
    scriptLoaders.set(scriptUrl, loader);
    return loader;
};

const getDocumentExtension = (fileName: string) => {
    const extension = fileName.split('.').pop()?.toLowerCase();
    return extension || '';
};

export const isOnlyOfficeSupported = (fileName: string) => {
    const extension = getDocumentExtension(fileName);
    return ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'pdf'].includes(extension);
};

const OnlyOfficeEditorModal: React.FC<OnlyOfficeEditorModalProps> = ({
    open,
    document: doc,
    onClose,
    onSaved,
    onDownload,
}) => {
    const editorId = useMemo(() => `onlyoffice-editor-${doc?.id || 'empty'}`, [doc?.id]);
    const editorRef = useRef<{ destroyEditor?: () => void } | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const destroyEditor = () => {
        try {
            editorRef.current?.destroyEditor?.();
        } catch (err) {
            console.warn('ONLYOFFICE editor destroy failed', err);
        } finally {
            editorRef.current = null;
        }
    };

    const openEditor = async () => {
        if (!doc) return;
        setLoading(true);
        setError(null);
        destroyEditor();

        try {
            const { documentServerUrl, config } = await getOnlineDocumentOnlyOfficeConfig(doc.id);
            await loadOnlyOfficeScript(documentServerUrl);

            if (!window.DocsAPI) {
                throw new Error('ONLYOFFICE API 未就绪');
            }

            editorRef.current = new window.DocsAPI.DocEditor(editorId, config);
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'ONLYOFFICE 打开失败';
            setError(errorMessage);
            message.error(errorMessage);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (!open || !doc) return;
        openEditor();
        return destroyEditor;
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [open, doc?.id]);

    useEffect(() => {
        if (!open || !doc) return;
        const keepAlive = () => {
            userService.getProfile().catch((err) => {
                console.warn('ONLYOFFICE keepalive failed', err);
            });
        };
        const timer = window.setInterval(keepAlive, 5 * 60 * 1000);
        return () => window.clearInterval(timer);
    }, [open, doc?.id]);

    useEffect(() => {
        if (!open) return;
        const handleMessage = (event: MessageEvent) => {
            const payload = typeof event.data === 'string' ? event.data : JSON.stringify(event.data);
            if (payload.includes('forcesave') || payload.includes('saved')) {
                onSaved?.();
            }
        };
        window.addEventListener('message', handleMessage);
        return () => window.removeEventListener('message', handleMessage);
    }, [open, onSaved]);

    if (!open || !doc) return null;

    return createPortal(
        <div className="fixed inset-0 z-[1100] flex flex-col bg-slate-950">
            <div className="flex h-14 shrink-0 items-center justify-between border-b border-white/10 bg-slate-950 px-5 text-white">
                <div className="min-w-0">
                    <p className="truncate text-sm font-bold">{doc.fileName || doc.title}</p>
                    <p className="text-[11px] text-white/45">ONLYOFFICE 在线预览、编辑、协同</p>
                </div>
                <div className="flex items-center gap-2">
                    <button
                        onClick={() => openEditor()}
                        className="rounded-lg p-2 text-white/60 transition-colors hover:bg-white/10 hover:text-white"
                        title="重新加载"
                    >
                        <RotateCcw size={17} />
                    </button>
                    <button
                        onClick={() => onDownload(doc)}
                        className="rounded-lg p-2 text-white/60 transition-colors hover:bg-white/10 hover:text-white"
                        title="下载"
                    >
                        <Download size={18} />
                    </button>
                    <button
                        onClick={() => {
                            destroyEditor();
                            onSaved?.();
                            onClose();
                        }}
                        className="rounded-lg p-2 text-white/60 transition-colors hover:bg-white/10 hover:text-white"
                        title="关闭"
                    >
                        <X size={19} />
                    </button>
                </div>
            </div>

            <div className="relative flex-1 bg-slate-900">
                {loading && (
                    <div className="absolute inset-0 z-10 flex items-center justify-center bg-slate-950/75">
                        <Spin size="large" />
                    </div>
                )}
                {error ? (
                    <div className="flex h-full flex-col items-center justify-center gap-4 text-white/70">
                        <p className="text-sm">{error}</p>
                        <button
                            onClick={() => openEditor()}
                            className="rounded-lg bg-blue-600 px-5 py-2 text-sm font-bold text-white transition-colors hover:bg-blue-700"
                        >
                            重试
                        </button>
                    </div>
                ) : (
                    <div id={editorId} className="h-full w-full bg-white" />
                )}
            </div>
        </div>,
        document.body
    );
};

export default OnlyOfficeEditorModal;
