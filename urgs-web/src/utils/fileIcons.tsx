import React from 'react';
import {
    File,
    FileText,
    Image as ImageIcon,
    FileCode,
    Music,
    Video,
    FileArchive,
    FileSpreadsheet,
    FileBarChart,
} from 'lucide-react';

export const getFileIcon = (fileName: string, size: number = 24) => {
    const ext = fileName.split('.').pop()?.toLowerCase() || '';

    // 图片
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].includes(ext)) {
        return <ImageIcon size={size} className="text-purple-500" />;
    }
    // PDF
    if (['pdf'].includes(ext)) {
        return <FileText size={size} className="text-red-500" />;
    }
    // Word/文档
    if (['doc', 'docx', 'txt', 'md', 'rtf'].includes(ext)) {
        return <FileText size={size} className="text-blue-500" />;
    }
    // Excel/表格
    if (['xls', 'xlsx', 'csv'].includes(ext)) {
        return <FileSpreadsheet size={size} className="text-emerald-500" />;
    }
    // PPT/演示
    if (['ppt', 'pptx'].includes(ext)) {
        return <FileBarChart size={size} className="text-orange-500" />;
    }
    // 代码
    if (['js', 'ts', 'tsx', 'jsx', 'java', 'py', 'c', 'cpp', 'html', 'css', 'json', 'xml', 'yaml', 'sql'].includes(ext)) {
        return <FileCode size={size} className="text-slate-600" />;
    }
    // 音频
    if (['mp3', 'wav', 'ogg', 'flac'].includes(ext)) {
        return <Music size={size} className="text-pink-500" />;
    }
    // 视频
    if (['mp4', 'avi', 'mov', 'mkv', 'webm'].includes(ext)) {
        return <Video size={size} className="text-indigo-500" />;
    }
    // 压缩包
    if (['zip', 'rar', '7z', 'tar', 'gz'].includes(ext)) {
        return <FileArchive size={size} className="text-yellow-600" />;
    }

    // 默认文件
    return <File size={size} className="text-slate-400" />;
};
