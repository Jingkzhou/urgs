import { useState, useRef, useCallback } from 'react';
import { message } from 'antd';
import type { UploadProps } from 'antd';
import * as api from '../../api/knowledge';
import type { UploadFileItem } from './UploadProgressPanel';

interface UseUploadOptions {
    selectedFolderId: number | null;
    scope: 'private' | 'shared';
    onDocumentsChanged: () => void;
    onFoldersChanged: () => void;
}

export function useUpload({ selectedFolderId, scope, onDocumentsChanged, onFoldersChanged }: UseUploadOptions) {
    const [uploadFiles, setUploadFiles] = useState<UploadFileItem[]>([]);
    const [uploadPanelVisible, setUploadPanelVisible] = useState(false);
    const lastLoadedMap = useRef<Map<string, { loaded: number; time: number }>>(new Map());
    const folderCreationCache = useRef<Map<string, Promise<number>>>(new Map());

    // 确保路径存在
    const ensureDirectoryPath = useCallback(async (baseFolderId: number | null, fullPath: string): Promise<number | null> => {
        const parts = fullPath.split('/');
        parts.pop(); // 移除文件名

        if (parts.length === 0) return baseFolderId;

        let currentParentId = baseFolderId;

        for (const part of parts) {
            const parentKey = currentParentId === null ? 'root' : currentParentId.toString();
            const cacheKey = `${parentKey}/${part}`;

            let folderPromise = folderCreationCache.current.get(cacheKey);

            if (!folderPromise) {
                folderPromise = api.ensureFolder({
                    name: part,
                    parentId: currentParentId ?? undefined,
                    scope,
                }).then(folder => folder.id);

                folderCreationCache.current.set(cacheKey, folderPromise);
            }

            try {
                currentParentId = await folderPromise;
            } catch (e) {
                console.error(`Failed to ensure folder ${part}`, e);
                folderCreationCache.current.delete(cacheKey);
                throw e;
            }
        }

        return currentParentId;
    }, [scope]);

    // 统一上传核心逻辑
    const performUpload = useCallback(async (file: File, relativePath: string = '') => {
        const uid = (file as any).uid || Math.random().toString(36).slice(2);

        // 2GB check
        if (file.size > 2 * 1024 * 1024 * 1024) {
            message.error(`${file.name} 超过 2GB 限制`);
            setUploadFiles(prev => [{
                uid,
                name: file.name,
                size: file.size,
                status: 'error',
                progress: 0,
                errorMsg: '超过 2GB 限制'
            }, ...prev]);
            setUploadPanelVisible(true);
            return;
        }

        // Init file in list
        setUploadFiles(prev => {
            const exists = prev.find(f => f.uid === uid);
            if (exists) return prev;
            return [{
                uid,
                name: file.name,
                size: file.size,
                status: 'pending',
                progress: 0
            }, ...prev];
        });
        setUploadPanelVisible(true);

        const formData = new FormData();
        formData.append('file', file);

        const startTime = Date.now();
        lastLoadedMap.current.set(uid, { loaded: 0, time: startTime });

        return new Promise<void>((resolve, reject) => {
            const xhr = new XMLHttpRequest();
            xhr.open('POST', '/api/common/upload', true);
            xhr.setRequestHeader('Authorization', `Bearer ${localStorage.getItem('auth_token')}`);

            xhr.upload.onprogress = (e) => {
                if (e.lengthComputable) {
                    const now = Date.now();
                    const progress = Math.min((e.loaded / e.total) * 98, 98);

                    const last = lastLoadedMap.current.get(uid) || { loaded: 0, time: startTime };
                    const timeDiff = (now - last.time) / 1000;

                    let speed = '';
                    if (timeDiff > 0.5 || progress === 100) {
                        const bytesDiff = e.loaded - last.loaded;
                        const speedBytes = bytesDiff / timeDiff;

                        const k = 1024;
                        const sizes = ['B/s', 'KB/s', 'MB/s'];
                        const i = Math.floor(Math.log(speedBytes) / Math.log(k));
                        speed = (speedBytes / Math.pow(k, i)).toFixed(1) + ' ' + (sizes[i] || 'MB/s');

                        lastLoadedMap.current.set(uid, { loaded: e.loaded, time: now });

                        setUploadFiles(prev => prev.map(f => {
                            if (f.uid === uid) {
                                return { ...f, status: 'uploading', progress: Number(progress.toFixed(2)), speed };
                            }
                            return f;
                        }));
                    } else {
                        setUploadFiles(prev => prev.map(f => {
                            if (f.uid === uid) {
                                return { ...f, status: 'uploading', progress: Number(progress.toFixed(2)) };
                            }
                            return f;
                        }));
                    }
                }
            };

            xhr.onload = async () => {
                if (xhr.status >= 200 && xhr.status < 300) {
                    try {
                        const { url, name } = JSON.parse(xhr.responseText);

                        let targetFolderId = selectedFolderId;
                        if (relativePath) {
                            try {
                                targetFolderId = (await ensureDirectoryPath(selectedFolderId, relativePath)) ?? null;
                            } catch (e) {
                                console.warn("Folder creation failed", e);
                            }
                        }

                        await api.createDocument({
                            title: name,
                            fileUrl: url,
                            fileName: name,
                            fileSize: file.size,
                            folderId: targetFolderId ?? undefined,
                            scope,
                        });

                        setUploadFiles(prev => prev.map(f => {
                            if (f.uid === uid) return { ...f, status: 'success', progress: 100, speed: '' };
                            return f;
                        }));
                        resolve();
                    } catch (err) {
                        setUploadFiles(prev => prev.map(f => {
                            if (f.uid === uid) return { ...f, status: 'error', errorMsg: '处理失败' };
                            return f;
                        }));
                        reject(err);
                    }
                } else {
                    setUploadFiles(prev => prev.map(f => {
                        if (f.uid === uid) return { ...f, status: 'error', errorMsg: '上传失败' };
                        return f;
                    }));
                    reject(new Error('Upload failed'));
                }
            };

            xhr.onerror = () => {
                setUploadFiles(prev => prev.map(f => {
                    if (f.uid === uid) return { ...f, status: 'error', errorMsg: '网络错误' };
                    return f;
                }));
                reject(new Error('Network error'));
            };

            xhr.send(formData);
        });
    }, [selectedFolderId, scope, ensureDirectoryPath]);

    // Ant Design Upload 自定义请求
    const customUploadRequest = useCallback(async (options: any) => {
        const { file, onSuccess, onError } = options;
        const relativePath = file.webkitRelativePath || '';
        try {
            await performUpload(file, relativePath);
            onSuccess("Ok");
            onDocumentsChanged();
            if (relativePath) onFoldersChanged();
        } catch (err) {
            onError(err);
        }
    }, [performUpload, onDocumentsChanged, onFoldersChanged]);

    const uploadProps: UploadProps = {
        name: 'file',
        multiple: true,
        customRequest: customUploadRequest,
        showUploadList: false,
    };

    // 递归扫描文件项
    const scanFiles = useCallback(async (entry: any, path: string = ''): Promise<Array<{ file: File; path: string }>> => {
        if (entry.isFile) {
            return new Promise((resolve) => {
                entry.file((file: File) => {
                    resolve([{ file, path }]);
                });
            });
        } else if (entry.isDirectory) {
            const dirReader = entry.createReader();
            const entries: any[] = [];

            const readEntries = async () => {
                return new Promise<void>((resolve, reject) => {
                    dirReader.readEntries(async (results: any[]) => {
                        if (results.length > 0) {
                            entries.push(...results);
                            await readEntries();
                        } else {
                            resolve();
                        }
                    }, reject);
                });
            };

            await readEntries();

            let files: Array<{ file: File; path: string }> = [];
            for (const childEntry of entries) {
                const childPath = path ? `${path}/${entry.name}` : entry.name;
                files = files.concat(await scanFiles(childEntry, childPath));
            }
            return files;
        }
        return [];
    }, []);

    // 拖拽上传处理
    const handleDrop = useCallback(async (e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();

        const items = e.dataTransfer.items;
        if (!items) return;

        const queue: Promise<any>[] = [];

        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            const entry = item.webkitGetAsEntry ? item.webkitGetAsEntry() : null;
            if (entry) {
                queue.push(scanFiles(entry));
            }
        }

        try {
            message.loading({ content: '正在解析文件...', key: 'uploading' });
            const results = await Promise.all(queue);
            const allFiles = results.flat();

            if (allFiles.length === 0) return;

            message.loading({ content: `正在上传 ${allFiles.length} 个文件...`, key: 'uploading' });

            const uploadPromises = [];
            for (const { file, path } of allFiles) {
                uploadPromises.push(performUpload(file, path));
            }

            Promise.allSettled(uploadPromises).then(() => {
                onDocumentsChanged();
                onFoldersChanged();
                folderCreationCache.current.clear();
            });
        } catch (error) {
            console.error('拖拽上传失败', error);
            message.error({ content: '解析出错', key: 'uploading' });
        }
    }, [scanFiles, performUpload, onDocumentsChanged, onFoldersChanged]);

    return {
        uploadFiles,
        uploadPanelVisible,
        setUploadPanelVisible,
        uploadProps,
        handleDrop,
    };
}
