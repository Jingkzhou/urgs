import React from 'react';
import { ChevronLeft, ChevronRight, MoreHorizontal } from 'lucide-react';

interface PaginationProps {
    current: number;
    total: number;
    pageSize: number;
    onChange: (page: number, pageSize: number) => void;
    className?: string;
    showSizeChanger?: boolean;
    pageSizeOptions?: number[];
}

const Pagination: React.FC<PaginationProps> = ({
    current,
    total,
    pageSize,
    onChange,
    className = '',
    showSizeChanger = false,
    pageSizeOptions = [10, 20, 50, 100]
}) => {
    const [isCustomSize, setIsCustomSize] = React.useState(false);
    const [customSizeValue, setCustomSizeValue] = React.useState(pageSize.toString());

    const totalPages = Math.ceil(total / pageSize);

    // Removed early return for total === 0 to always show pagination control
    // if (total === 0) return null;

    const handlePageChange = (page: number) => {
        if (page < 1 || page > totalPages) return;
        onChange(page, pageSize);
    };

    const handleSizeChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        const value = e.target.value;
        if (value === 'custom') {
            setIsCustomSize(true);
            setCustomSizeValue(pageSize.toString());
        } else {
            const newSize = Number(value);
            onChange(1, newSize); // Reset to page 1 when size changes
            setIsCustomSize(false);
        }
    };

    const handleCustomSizeSubmit = () => {
        const newSize = parseInt(customSizeValue, 10);
        if (!isNaN(newSize) && newSize > 0) {
            onChange(1, newSize);
            setIsCustomSize(false);
        } else {
            // Reset to current pageSize if invalid
            setCustomSizeValue(pageSize.toString());
            setIsCustomSize(false);
        }
    };

    const handleCustomSizeKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter') {
            handleCustomSizeSubmit();
        } else if (e.key === 'Escape') {
            setIsCustomSize(false);
            setCustomSizeValue(pageSize.toString());
        }
    };

    const renderPageNumbers = () => {
        if (totalPages === 0) return null;

        const pages = [];
        const maxVisiblePages = 5; // Number of page buttons to show

        if (totalPages <= maxVisiblePages + 2) {
            // Show all pages if total is small
            for (let i = 1; i <= totalPages; i++) {
                pages.push(i);
            }
        } else {
            // Always show first page
            pages.push(1);

            if (current > 3) {
                pages.push('...');
            }

            // Calculate range around current page
            let start = Math.max(2, current - 1);
            let end = Math.min(totalPages - 1, current + 1);

            // Adjust if at edges
            if (current <= 3) {
                end = 4;
            }
            if (current >= totalPages - 2) {
                start = totalPages - 3;
            }

            for (let i = start; i <= end; i++) {
                pages.push(i);
            }

            if (current < totalPages - 2) {
                pages.push('...');
            }

            // Always show last page
            pages.push(totalPages);
        }

        return pages.map((page, index) => {
            if (page === '...') {
                return (
                    <span key={`ellipsis-${index}`} className="px-2 py-1 text-slate-400">
                        <MoreHorizontal size={16} />
                    </span>
                );
            }

            const pageNum = page as number;
            return (
                <button
                    key={pageNum}
                    onClick={() => handlePageChange(pageNum)}
                    className={`
                        min-w-[32px] h-8 flex items-center justify-center rounded-lg text-sm font-medium transition-all duration-200
                        ${current === pageNum
                            ? 'bg-blue-600 text-white shadow-md shadow-blue-200'
                            : 'text-slate-600 hover:bg-slate-100 hover:text-blue-600'
                        }
                    `}
                >
                    {pageNum}
                </button>
            );
        });
    };

    return (
        <div className={`flex items-center justify-between py-4 ${className}`}>
            <div className="text-sm text-slate-500 font-medium">
                共 <span className="text-slate-900 font-bold">{total}</span> 条记录
            </div>

            <div className="flex items-center gap-2">
                {showSizeChanger && (
                    <div className="mr-2">
                        {isCustomSize ? (
                            <div className="flex items-center gap-1">
                                <input
                                    type="number"
                                    value={customSizeValue}
                                    onChange={(e) => setCustomSizeValue(e.target.value)}
                                    onBlur={handleCustomSizeSubmit}
                                    onKeyDown={handleCustomSizeKeyDown}
                                    autoFocus
                                    className="h-8 w-20 px-2 text-sm border border-blue-500 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 text-slate-600 bg-white"
                                />
                                <span className="text-sm text-slate-500">条/页</span>
                            </div>
                        ) : (
                            <select
                                value={pageSizeOptions.includes(pageSize) ? pageSize : 'custom'}
                                onChange={handleSizeChange}
                                className="h-8 px-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 text-slate-600 bg-white"
                            >
                                {pageSizeOptions.map(size => (
                                    <option key={size} value={size}>{size} 条/页</option>
                                ))}
                                <option value="custom">自定义</option>
                            </select>
                        )}
                    </div>
                )}

                <button
                    onClick={() => handlePageChange(current - 1)}
                    disabled={current === 1 || totalPages === 0}
                    className="h-8 w-8 flex items-center justify-center rounded-lg border border-slate-200 text-slate-500 hover:bg-slate-50 hover:text-blue-600 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-transparent disabled:hover:text-slate-500 transition-colors"
                >
                    <ChevronLeft size={16} />
                </button>

                <div className="flex items-center gap-1">
                    {renderPageNumbers()}
                </div>

                <button
                    onClick={() => handlePageChange(current + 1)}
                    disabled={current === totalPages || totalPages === 0}
                    className="h-8 w-8 flex items-center justify-center rounded-lg border border-slate-200 text-slate-500 hover:bg-slate-50 hover:text-blue-600 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-transparent disabled:hover:text-slate-500 transition-colors"
                >
                    <ChevronRight size={16} />
                </button>
            </div>
        </div>
    );
};

export default Pagination;
