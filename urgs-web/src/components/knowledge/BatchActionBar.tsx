import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Modal, Popover, Checkbox, Button, message } from 'antd';
import {
    Download, Trash2, FolderInput, Tags, X,
    ChevronRight, Folder,
} from 'lucide-react';
import type { FolderTreeNode, KnowledgeTag } from '../../api/knowledge';

interface BatchActionBarProps {
    visible: boolean;
    selectedCount: number;
    totalCount: number;
    onSelectAll: () => void;
    onDeselectAll: () => void;
    onBatchDownload: () => void;
    onBatchDelete: () => void;
    onBatchMove: (folderId: number | null) => void;
    onBatchTag: (tagIds: number[]) => void;
    onCancel: () => void;
    folders: FolderTreeNode[];
    tags: KnowledgeTag[];
    hasSelectedFolders?: boolean;
}

// 文件夹树选择器
const FolderPicker: React.FC<{
    folders: FolderTreeNode[];
    onSelect: (id: number | null) => void;
}> = ({ folders, onSelect }) => {
    const renderNode = (nodes: FolderTreeNode[], depth: number = 0) =>
        nodes.map(node => (
            <div key={node.id}>
                <div
                    className="flex items-center gap-2 px-3 py-2 hover:bg-blue-50 cursor-pointer rounded-lg transition-colors text-sm"
                    style={{ paddingLeft: `${12 + depth * 20}px` }}
                    onClick={() => onSelect(node.id)}
                >
                    <Folder size={16} className="text-amber-400 fill-amber-400 flex-shrink-0" />
                    <span className="truncate text-slate-700">{node.name}</span>
                </div>
                {node.children && node.children.length > 0 && renderNode(node.children, depth + 1)}
            </div>
        ));

    return (
        <div className="w-64 max-h-72 overflow-auto py-1">
            <div
                className="flex items-center gap-2 px-3 py-2 hover:bg-blue-50 cursor-pointer rounded-lg transition-colors text-sm font-medium text-slate-600"
                onClick={() => onSelect(null)}
            >
                <Folder size={16} className="text-slate-400 flex-shrink-0" />
                根目录
            </div>
            {renderNode(folders)}
        </div>
    );
};

// 标签选择器
const TagPicker: React.FC<{
    tags: KnowledgeTag[];
    onConfirm: (tagIds: number[]) => void;
}> = ({ tags, onConfirm }) => {
    const [selected, setSelected] = useState<number[]>([]);

    const toggle = (id: number) => {
        setSelected(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
    };

    return (
        <div className="w-56 py-2">
            <div className="max-h-48 overflow-auto space-y-1 px-2">
                {tags.length === 0 && (
                    <p className="text-slate-400 text-sm text-center py-4">暂无标签</p>
                )}
                {tags.map(t => (
                    <div
                        key={t.id}
                        className="flex items-center gap-2 px-2 py-1.5 hover:bg-slate-50 rounded-lg cursor-pointer transition-colors"
                        onClick={() => toggle(t.id)}
                    >
                        <Checkbox checked={selected.includes(t.id)} />
                        <div
                            className="w-3 h-3 rounded-full flex-shrink-0"
                            style={{ backgroundColor: t.color }}
                        />
                        <span className="text-sm text-slate-700 truncate">{t.name}</span>
                    </div>
                ))}
            </div>
            {tags.length > 0 && (
                <div className="border-t border-slate-100 mt-2 pt-2 px-2">
                    <Button
                        type="primary"
                        size="small"
                        block
                        disabled={selected.length === 0}
                        onClick={() => onConfirm(selected)}
                    >
                        确认 ({selected.length})
                    </Button>
                </div>
            )}
        </div>
    );
};

const BatchActionBar: React.FC<BatchActionBarProps> = ({
    visible, selectedCount, totalCount,
    onSelectAll, onDeselectAll, onBatchDownload, onBatchDelete,
    onBatchMove, onBatchTag, onCancel, folders, tags, hasSelectedFolders = false,
}) => {
    const [moveOpen, setMoveOpen] = useState(false);
    const [tagOpen, setTagOpen] = useState(false);

    const handleDelete = () => {
        Modal.confirm({
            title: '确认批量删除',
            content: `确定要删除选中的 ${selectedCount} 个项目吗？此操作不可撤销。`,
            okText: '确认删除',
            okType: 'danger',
            cancelText: '取消',
            onOk: onBatchDelete,
        });
    };

    const handleMove = (folderId: number | null) => {
        setMoveOpen(false);
        onBatchMove(folderId);
    };

    const handleMoveOpenChange = (open: boolean) => {
        if (open && hasSelectedFolders) {
            message.warning('移动操作只支持文档，请不要选择文件夹');
            setMoveOpen(false);
            return;
        }
        setMoveOpen(open);
    };

    const handleTag = (tagIds: number[]) => {
        setTagOpen(false);
        onBatchTag(tagIds);
    };

    const isAllSelected = selectedCount === totalCount && totalCount > 0;

    return (
        <AnimatePresence>
            {visible && selectedCount > 0 && (
                <motion.div
                    initial={{ y: 80, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    exit={{ y: 80, opacity: 0 }}
                    transition={{ type: 'spring', damping: 25, stiffness: 300 }}
                    className="knowledge-batch-action fixed left-1/2 -translate-x-1/2 z-30 bg-white/95 shadow-2xl border border-slate-200 rounded-2xl px-6 py-3 flex items-center gap-4"
                >
                    {/* 选中计数 */}
                    <span className="text-sm font-bold text-slate-800 whitespace-nowrap">
                        已选择 <span className="text-blue-600">{selectedCount}</span> 项
                    </span>

                    {/* 全选/取消全选 */}
                    <button
                        onClick={isAllSelected ? onDeselectAll : onSelectAll}
                        className="text-xs text-blue-600 hover:text-blue-700 font-medium whitespace-nowrap"
                    >
                        {isAllSelected ? '取消全选' : '全选'}
                    </button>

                    <div className="w-px h-6 bg-slate-200"></div>

                    {/* 操作按钮组 */}
                    <div className="flex items-center gap-1">
                        <button
                            onClick={onBatchDownload}
                            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm text-slate-600 hover:bg-slate-100 hover:text-slate-800 transition-colors"
                        >
                            <Download size={16} />
                            <span className="hidden sm:inline">下载</span>
                        </button>

                        <Popover
                            content={<FolderPicker folders={folders} onSelect={handleMove} />}
                            title={<span className="text-sm font-medium">移动到</span>}
                            trigger="click"
                            open={moveOpen}
                            onOpenChange={handleMoveOpenChange}
                            placement="top"
                        >
                            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm text-slate-600 hover:bg-slate-100 hover:text-slate-800 transition-colors">
                                <FolderInput size={16} />
                                <span className="hidden sm:inline">移动</span>
                            </button>
                        </Popover>

                        <Popover
                            content={<TagPicker tags={tags} onConfirm={handleTag} />}
                            title={<span className="text-sm font-medium">添加标签</span>}
                            trigger="click"
                            open={tagOpen}
                            onOpenChange={setTagOpen}
                            placement="top"
                        >
                            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm text-slate-600 hover:bg-slate-100 hover:text-slate-800 transition-colors">
                                <Tags size={16} />
                                <span className="hidden sm:inline">标签</span>
                            </button>
                        </Popover>

                        <button
                            onClick={handleDelete}
                            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm text-red-500 hover:bg-red-50 hover:text-red-600 transition-colors"
                        >
                            <Trash2 size={16} />
                            <span className="hidden sm:inline">删除</span>
                        </button>
                    </div>

                    <div className="w-px h-6 bg-slate-200"></div>

                    {/* 取消 */}
                    <button
                        onClick={onCancel}
                        className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors"
                    >
                        <X size={16} />
                    </button>
                </motion.div>
            )}
        </AnimatePresence>
    );
};

export default BatchActionBar;
