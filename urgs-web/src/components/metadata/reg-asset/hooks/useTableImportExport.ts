import React from 'react';

interface UseTableImportExportOptions {
    selectedSystem?: string;
    selectedSystemName?: string;
    tableKeyword: string;
    filterStatus: string;
    filterFrequency: string;
    filterSourceType: string;
    selectedTableIds: Set<number | string>;
    setIsImporting: React.Dispatch<React.SetStateAction<boolean>>;
    onImportSuccess: () => void;
}

const buildTimestamp = (includeSeconds = false) => {
    const now = new Date();
    const base = now.getFullYear() +
        String(now.getMonth() + 1).padStart(2, '0') +
        String(now.getDate()).padStart(2, '0') +
        String(now.getHours()).padStart(2, '0') +
        String(now.getMinutes()).padStart(2, '0');

    if (!includeSeconds) {
        return base;
    }

    return base + String(now.getSeconds()).padStart(2, '0');
};

const buildTableExportParams = ({
    selectedSystem,
    tableKeyword,
    filterStatus,
    filterFrequency,
    filterSourceType,
    selectedTableIds,
}: Omit<UseTableImportExportOptions, 'setIsImporting' | 'onImportSuccess'>) => {
    const params = new URLSearchParams();

    if (selectedSystem) {
        params.append('systemCode', selectedSystem);
    }
    if (tableKeyword) {
        params.append('keyword', tableKeyword);
    }
    if (filterStatus) {
        params.append('autoFetchStatus', filterStatus);
    }
    if (filterFrequency) {
        params.append('frequency', filterFrequency);
    }
    if (filterSourceType) {
        params.append('sourceType', filterSourceType);
    }
    if (selectedTableIds.size > 0) {
        params.append('tableIds', Array.from(selectedTableIds).join(','));
    }

    return params;
};

const triggerDownload = (blob: Blob, fileName: string) => {
    const blobUrl = window.URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = blobUrl;
    anchor.download = fileName;
    document.body.appendChild(anchor);
    anchor.click();
    window.URL.revokeObjectURL(blobUrl);
    document.body.removeChild(anchor);
};

export const useTableImportExport = ({
    selectedSystem,
    selectedSystemName,
    tableKeyword,
    filterStatus,
    filterFrequency,
    filterSourceType,
    selectedTableIds,
    setIsImporting,
    onImportSuccess,
}: UseTableImportExportOptions) => {
    const tableFileInputRef = React.useRef<HTMLInputElement>(null);

    const getAuthHeaders = () => {
        const token = localStorage.getItem('auth_token');
        return token ? { Authorization: `Bearer ${token}` } : {};
    };

    const handleTableExport = async () => {
        try {
            const params = buildTableExportParams({
                selectedSystem,
                tableKeyword,
                filterStatus,
                filterFrequency,
                filterSourceType,
                selectedTableIds,
            });
            const url = '/api/reg/table/export' + (params.toString() ? `?${params.toString()}` : '');
            const response = await fetch(url, {
                headers: getAuthHeaders(),
            });

            if (!response.ok) {
                throw new Error('Export failed');
            }

            const blob = await response.blob();
            const sysName = selectedSystemName ? `${selectedSystemName}_` : '';
            triggerDownload(blob, `报表数据导出_${sysName}${buildTimestamp(true)}.xlsx`);
        } catch (error) {
            console.error('Export failed', error);
            alert('导出失败');
        }
    };

    const handleTableMarkdownExport = async () => {
        try {
            const params = buildTableExportParams({
                selectedSystem,
                tableKeyword,
                filterStatus,
                filterFrequency,
                filterSourceType,
                selectedTableIds,
            });
            const url = '/api/reg/table-docs/export' + (params.toString() ? `?${params.toString()}` : '');
            const response = await fetch(url, {
                headers: getAuthHeaders(),
            });

            if (!response.ok) {
                throw new Error('Markdown export failed');
            }

            const blob = await response.blob();
            const sysName = selectedSystemName ? `${selectedSystemName}_` : '';
            triggerDownload(blob, `监管报表Markdown导出_${sysName}${buildTimestamp(true)}.zip`);
        } catch (error) {
            console.error('Markdown export failed', error);
            alert('Markdown 导出失败');
        }
    };

    const handleTableImport = async (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) {
            return;
        }

        const formData = new FormData();
        formData.append('file', file);

        setIsImporting(true);
        try {
            const response = await fetch('/api/reg/table/import', {
                method: 'POST',
                headers: getAuthHeaders(),
                body: formData,
            });

            const result = await response.json();
            if (response.ok && result.success) {
                alert(`导入成功！\n报表：${result.tableCount} 个\n字段/指标：${result.elementCount} 个`);
                onImportSuccess();
            } else {
                alert(`导入失败：${result.message || '未知错误'}`);
            }
        } catch (error: any) {
            console.error('Import failed', error);
            alert('导入失败：' + (error.message || '网络或系统异常'));
        } finally {
            setIsImporting(false);
            if (tableFileInputRef.current) {
                tableFileInputRef.current.value = '';
            }
        }
    };

    return {
        tableFileInputRef,
        handleTableExport,
        handleTableMarkdownExport,
        handleTableImport,
    };
};
