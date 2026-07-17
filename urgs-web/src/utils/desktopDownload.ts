import { message } from 'antd';
import { getApiBaseUrl, isDesktopRuntime, resolveServiceUrl } from '../config';

const BLOB_URL_PREFIX = 'blob:';
const DOWNLOADABLE_SERVICE_PATHS = ['/api', '/uploads', '/profile'];
const INVALID_FILE_NAME_CHARACTERS = /[\\/:*?"<>|]/g;

let desktopDownloadAdapterInstalled = false;

const objectUrlBlobs = new Map<string, Blob>();

const safeFileName = (name: string) => {
    const normalized = name.trim().replace(INVALID_FILE_NAME_CHARACTERS, '_');
    return normalized || 'download';
};

const isDownloadableServiceUrl = (rawHref: string, resolvedHref: string) => {
    if (rawHref.startsWith(BLOB_URL_PREFIX)) {
        return true;
    }

    if (DOWNLOADABLE_SERVICE_PATHS.some((path) => rawHref.startsWith(path))) {
        return true;
    }

    const apiBaseUrl = getApiBaseUrl();
    if (!apiBaseUrl || !/^https?:\/\//i.test(resolvedHref)) {
        return false;
    }

    try {
        return new URL(resolvedHref).origin === new URL(apiBaseUrl).origin;
    } catch {
        return false;
    }
};

const getAuthorizedHeaders = () => {
    const headers = new Headers();
    const token = localStorage.getItem('auth_token');
    const authUser = localStorage.getItem('auth_user');

    if (token) {
        headers.set('Authorization', `Bearer ${token}`);
    }
    if (authUser) {
        try {
            const user = JSON.parse(authUser);
            if (user?.id || user?.userId) {
                headers.set('X-User-Id', String(user.id || user.userId));
            }
        } catch {
            // Keep the same tolerant behavior as the shared request wrapper.
        }
    }

    return headers;
};

const loadDownloadBlob = async (resolvedHref: string, blob?: Blob) => {
    if (blob) {
        return blob;
    }

    const response = await window.fetch(resolvedHref, {
        headers: getAuthorizedHeaders(),
    });
    if (!response.ok) {
        throw new Error(`下载请求失败（${response.status}）`);
    }
    return response.blob();
};

const saveDesktopDownload = async (rawHref: string, fileName: string, blob?: Blob) => {
    const resolvedHref = resolveServiceUrl(rawHref);
    const downloadBlob = await loadDownloadBlob(resolvedHref, blob);
    const [{ save }, { writeFile }] = await Promise.all([
        import('@tauri-apps/plugin-dialog'),
        import('@tauri-apps/plugin-fs'),
    ]);
    const destination = await save({ defaultPath: safeFileName(fileName) });

    if (!destination) {
        return;
    }

    await writeFile(destination, new Uint8Array(await downloadBlob.arrayBuffer()));
    message.success('文件已保存');
};

const trySaveDesktopDownload = (anchor: HTMLAnchorElement) => {
    const rawHref = anchor.getAttribute('href') || anchor.href;
    const resolvedHref = resolveServiceUrl(rawHref);

    if (!anchor.download || !isDownloadableServiceUrl(rawHref, resolvedHref)) {
        return false;
    }

    const blob = objectUrlBlobs.get(rawHref) || objectUrlBlobs.get(anchor.href);
    void saveDesktopDownload(rawHref, anchor.download, blob).catch((error: unknown) => {
        console.error('Desktop download failed:', error);
        message.error(error instanceof Error ? error.message : '文件下载失败，请稍后重试');
    });
    return true;
};

const installObjectUrlTracker = () => {
    const nativeCreateObjectUrl = URL.createObjectURL.bind(URL);
    const nativeRevokeObjectUrl = URL.revokeObjectURL.bind(URL);

    URL.createObjectURL = (object: Blob | MediaSource) => {
        const objectUrl = nativeCreateObjectUrl(object);
        if (object instanceof Blob) {
            objectUrlBlobs.set(objectUrl, object);
        }
        return objectUrl;
    };

    URL.revokeObjectURL = (objectUrl: string) => {
        objectUrlBlobs.delete(objectUrl);
        nativeRevokeObjectUrl(objectUrl);
    };
};

export const installDesktopDownloadAdapter = () => {
    if (desktopDownloadAdapterInstalled || !isDesktopRuntime()) {
        return;
    }

    installObjectUrlTracker();

    const nativeAnchorClick = HTMLAnchorElement.prototype.click;
    HTMLAnchorElement.prototype.click = function desktopAwareClick(this: HTMLAnchorElement) {
        if (!trySaveDesktopDownload(this)) {
            nativeAnchorClick.call(this);
        }
    };

    document.addEventListener('click', (event) => {
        const target = event.target;
        if (!(target instanceof Element)) {
            return;
        }

        const anchor = target.closest('a[download]');
        if (anchor instanceof HTMLAnchorElement && trySaveDesktopDownload(anchor)) {
            event.preventDefault();
            event.stopImmediatePropagation();
        }
    }, true);

    desktopDownloadAdapterInstalled = true;
};
