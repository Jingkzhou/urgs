export const instanceStatusMap: Record<number, { label: string; className: string; color: string }> = {
    1: { label: '等待中', className: 'bg-slate-100 text-slate-600 border-slate-200', color: 'default' },
    2: { label: '执行中', className: 'bg-blue-50 text-blue-600 border-blue-200', color: 'processing' },
    3: { label: '成功', className: 'bg-emerald-50 text-emerald-600 border-emerald-200', color: 'success' },
    4: { label: '失败', className: 'bg-red-50 text-red-600 border-red-200', color: 'error' },
};

export const taskDefinitionStatusMap: Record<number, { label: string; className: string }> = {
    0: { label: '正常', className: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
    1: { label: '暂停', className: 'bg-amber-50 text-amber-600 border-amber-200' },
};

export const detailItemClass = 'rounded-xl border border-slate-200 bg-slate-50/70 px-4 py-3';
export const detailSectionClass = 'rounded-2xl border border-slate-200 bg-white shadow-sm';
export const detailSectionHeaderClass = 'border-b border-slate-100 px-5 py-4';
export const detailSectionBodyClass = 'space-y-4 p-5';
export const headerCellClass = 'px-4 py-3 font-semibold whitespace-nowrap';
export const tableCellClass = 'px-4 py-3 align-middle';
export const monoCellClass = `${tableCellClass} font-mono text-xs text-slate-600`;
export const batchActionClass = 'inline-flex h-9 items-center gap-1.5 rounded-xl border px-3.5 text-xs font-semibold shadow-sm transition-all duration-200 hover:-translate-y-0.5 hover:shadow';
export const contextMenuItemClass = 'flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm transition-colors hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-45';
export const incompleteInstanceStatuses = new Set([1, 2, 4]);

export const blockingStatusRank: Record<number, number> = {
    4: 0,
    2: 1,
    1: 2,
};
