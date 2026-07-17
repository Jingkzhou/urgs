import React, { useState, useEffect, useRef } from 'react';
import { Tabs, Button, Tag, Space, Avatar, Select, Input, Spin, message, Dropdown, Modal } from 'antd';
import { ArrowLeft, GitBranch, Copy, ShieldCheck, Play, Rocket, ClipboardList, Code, Folder, FileText, Clock, ChevronRight, X, GitPullRequest, Upload, Pencil, Download } from 'lucide-react';

const { Option } = Select;
import { GitRepository, SsoConfig, GitFileEntry, GitBranch as GitBranchType, GitCommit, GitFileContent, getRepoFileTree, getRepoBranches, getRepoLatestCommit, getRepoFileContent, getRepoCommitDetail, saveRepoFile, downloadRepoFile } from '@/api/version';
import { useBreadcrumbs } from '../../../context/BreadcrumbContext';
import CommitList from './CommitList';
import CommitDetail from './CommitDetail';
import BranchList from './BranchList';
import TagList from './TagList';
import PullRequestModule from './PullRequestModule';
import { formatCommitTime } from '@/utils/dateUtils';
import PipelineManagement from '../PipelineManagement';
import DeploymentManagement from '../DeploymentManagement';
import ReleaseLedger from '../ReleaseLedger';
import AICodeAudit from '../AICodeAudit';

const MAX_UPLOAD_SIZE = 5 * 1024 * 1024;

type FileEditorState = {
    mode: 'edit' | 'upload';
    path: string;
    content?: string;
    contentBase64?: string;
    fileSha?: string;
    fileName?: string;
    size?: number;
};

const bytesToBase64 = (bytes: Uint8Array) => {
    const chunkSize = 0x8000;
    let binary = '';
    for (let index = 0; index < bytes.length; index += chunkSize) {
        binary += String.fromCharCode(...bytes.subarray(index, index + chunkSize));
    }
    return window.btoa(binary);
};

const textToBase64 = (content: string) => bytesToBase64(new TextEncoder().encode(content));

const formatFileSize = (size?: number) => {
    if (size === undefined || size === null) return '-';
    if (size < 1024) return `${size} B`;
    if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`;
    return `${(size / (1024 * 1024)).toFixed(1)} MB`;
};

interface Props {
    repo: GitRepository;
    ssoList: SsoConfig[];
    onBack: () => void;
}

const GitRepoDetail: React.FC<Props> = ({ repo, ssoList, onBack }) => {
    const onBackRef = useRef(onBack);
    useEffect(() => {
        onBackRef.current = onBack;
    }, [onBack]);
    const [activeTab, setActiveTab] = useState('code');

    // 代码浏览状态
    const [currentRef, setCurrentRef] = useState(repo.defaultBranch || 'master');
    const [currentPath, setCurrentPath] = useState('');
    const [branches, setBranches] = useState<GitBranchType[]>([]);
    const [files, setFiles] = useState<GitFileEntry[]>([]);
    const [latestCommit, setLatestCommit] = useState<GitCommit | null>(null);
    const [loading, setLoading] = useState(false);
    const [treeVersion, setTreeVersion] = useState(0);

    // 文件内容查看状态
    const [viewingFile, setViewingFile] = useState<GitFileContent | null>(null);
    const [fileLoading, setFileLoading] = useState(false);
    const [fileEditor, setFileEditor] = useState<FileEditorState | null>(null);
    const [commitMessage, setCommitMessage] = useState('');
    const [fileSaving, setFileSaving] = useState(false);
    const uploadInputRef = useRef<HTMLInputElement>(null);



    // Commit History & Diff
    // Commit History & Diff
    const [viewingCommitList, setViewingCommitList] = useState(false);
    const [viewingCommit, setViewingCommit] = useState<GitCommit | null>(null);
    const [viewingBranchList, setViewingBranchList] = useState(false);
    const [viewingTagList, setViewingTagList] = useState(false);
    const [viewingPullRequests, setViewingPullRequests] = useState(false);
    const [commitsLoading, setCommitsLoading] = useState(false); // Used for detail loading now

    const ssoName = ssoList.find(s => s.id === repo.ssoId)?.name || '未知系统';

    const { setBreadcrumbs } = useBreadcrumbs();

    // Context-based Breadcrumbs
    useEffect(() => {
        if (viewingPullRequests) return;

        const crumbs = [
            { id: 'root', label: '版本管理中心' },
            { id: 'list', label: '仓库管理', onClick: () => onBackRef.current() },
            { id: 'repo', label: repo.name, onClick: backToCodeView }
        ];

        // Add sub-view crumbs if needed
        if (viewingCommitList) {
            crumbs.push({ id: 'commits', label: '提交记录' });
        } else if (viewingBranchList) {
            crumbs.push({ id: 'branches', label: '分支列表' });
        } else if (viewingTagList) {
            crumbs.push({ id: 'tags', label: '标签列表' });
        } else if (viewingFile) {
            // Optional: Add file name as crumb
            crumbs.push({ id: 'file', label: viewingFile.name });
        }

        setBreadcrumbs(crumbs);
    }, [repo.name, viewingPullRequests, viewingCommitList, viewingBranchList, viewingTagList, viewingFile]);

    // 加载分支
    useEffect(() => {
        if (repo.id) {
            getRepoBranches(repo.id)
                .then(data => setBranches(data || []))
                .catch(err => console.error('获取分支失败', err));
        }
    }, [repo.id]);

    // 加载文件树和提交信息
    useEffect(() => {
        if (repo.id && !viewingFile) {
            setLoading(true);
            Promise.all([
                getRepoFileTree(repo.id, currentRef, currentPath),
                getRepoLatestCommit(repo.id, currentRef)
            ])
                .then(([filesData, commitData]) => {
                    setFiles((filesData || []).map(file => ({
                        ...file,
                        lastCommitMessage: file.lastCommitMessage || commitData?.message?.split('\n')[0],
                        lastCommitDate: file.lastCommitDate || commitData?.committedAt
                    })));
                    setLatestCommit(commitData);
                })
                .catch(err => {
                    console.error('获取文件列表失败', err);
                    message.error('获取仓库数据失败，请检查访问令牌配置');
                })
                .finally(() => setLoading(false));
        }
    }, [repo.id, currentRef, currentPath, viewingFile, treeVersion]);

    // Load Commits
    // Load Commits logic moved to CommitList component

    const handleCommitClick = (sha: string) => {
        setCommitsLoading(true);
        getRepoCommitDetail(repo.id!, sha)
            .then(data => {
                setViewingCommit(data);
            })
            .catch(err => {
                console.error('Failed to load commit detail', err);
                message.error('获取提交详情失败');
            })
            .finally(() => setCommitsLoading(false));
    };

    const handleFolderClick = (path: string) => {
        setCurrentPath(path);
    };

    const handleFileClick = (file: GitFileEntry) => {
        if (file.type === 'dir') {
            handleFolderClick(file.path);
        } else {
            // 加载文件内容
            setFileLoading(true);
            getRepoFileContent(repo.id!, file.path, currentRef)
                .then(content => {
                    setViewingFile(content);
                })
                .catch(err => {
                    console.error('获取文件内容失败', err);
                    message.error('获取文件内容失败');
                })
                .finally(() => setFileLoading(false));
        }
    };

    const handleEditFile = () => {
        if (!viewingFile) {
            return;
        }
        setFileEditor({
            mode: 'edit',
            path: viewingFile.path,
            content: viewingFile.content || '',
            fileSha: viewingFile.sha
        });
        setCommitMessage(`更新 ${viewingFile.path}`);
    };

    const handleDownloadFile = async () => {
        if (!repo.id || !viewingFile) {
            return;
        }
        try {
            const blob = await downloadRepoFile(repo.id, viewingFile.path, currentRef);
            const objectUrl = URL.createObjectURL(blob);
            const anchor = document.createElement('a');
            anchor.href = objectUrl;
            anchor.download = viewingFile.name;
            document.body.appendChild(anchor);
            anchor.click();
            anchor.remove();
            URL.revokeObjectURL(objectUrl);
            message.success('文件已开始下载');
        } catch (error) {
            console.error('下载 Git 文件失败', error);
            message.error('下载文件失败，请稍后重试');
        }
    };

    const handleUploadFile = async (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        event.target.value = '';
        if (!file) {
            return;
        }
        if (file.size > MAX_UPLOAD_SIZE) {
            message.error('单个文件不能超过 5MB');
            return;
        }

        try {
            const contentBase64 = bytesToBase64(new Uint8Array(await file.arrayBuffer()));
            const targetPath = currentPath ? `${currentPath}/${file.name}` : file.name;
            setFileEditor({
                mode: 'upload',
                path: targetPath,
                contentBase64,
                fileName: file.name,
                size: file.size
            });
            setCommitMessage(`上传 ${targetPath}`);
        } catch (error) {
            console.error('读取上传文件失败', error);
            message.error('读取上传文件失败');
        }
    };

    const handleSaveFile = async () => {
        if (!repo.id || !fileEditor) {
            return;
        }
        const path = fileEditor.path.trim().replace(/^\/+/, '');
        if (!path) {
            message.error('请输入仓库内文件路径');
            return;
        }
        if (!commitMessage.trim()) {
            message.error('请输入提交说明');
            return;
        }
        const existingFile = files.find(file => file.type === 'file' && file.path === path);
        const overwrite = fileEditor.mode === 'edit' || Boolean(existingFile);
        if (fileEditor.mode === 'upload' && existingFile) {
            const confirmed = await new Promise<boolean>(resolve => {
                Modal.confirm({
                    title: '文件已存在',
                    content: `当前分支已存在 ${path}，是否覆盖后提交？`,
                    okText: '覆盖并提交',
                    cancelText: '取消',
                    onOk: () => resolve(true),
                    onCancel: () => resolve(false)
                });
            });
            if (!confirmed) {
                return;
            }
        }

        setFileSaving(true);
        try {
            await saveRepoFile(repo.id, {
                path,
                branch: currentRef,
                contentBase64: fileEditor.mode === 'edit'
                    ? textToBase64(fileEditor.content || '')
                    : fileEditor.contentBase64 || '',
                commitMessage: commitMessage.trim(),
                fileSha: fileEditor.fileSha || existingFile?.sha,
                overwrite
            });
            message.success(overwrite ? '文件已覆盖并提交' : '文件已上传并提交');
            setFileEditor(null);
            setViewingFile(null);
            setTreeVersion(version => version + 1);
        } catch (error: any) {
            console.error('保存 Git 文件失败', error);
            message.error(error?.message || '保存失败，请检查仓库写入权限');
        } finally {
            setFileSaving(false);
        }
    };

    const handleBreadcrumbClick = (index: number) => {
        setViewingFile(null);
        const parts = currentPath.split('/').filter(Boolean);
        const newPath = parts.slice(0, index).join('/');
        setCurrentPath(newPath);
    };

    const backToCodeView = () => {
        setActiveTab('code');
        setViewingPullRequests(false);
        setViewingBranchList(false);
        setViewingTagList(false);
        setViewingCommitList(false);
        // Explicitly set breadcrumbs for code view will happen via effect
    };



    const renderHeader = () => (
        <div className="bg-white p-6 border-b border-slate-200 mb-4">
            <div className="flex items-start gap-4">
                <div className="mt-1">
                    <Button type="text" icon={<ArrowLeft size={18} />} onClick={onBack} className="mr-2" />
                </div>
                <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                        <h1 className="text-xl font-bold text-slate-800 m-0">{ssoName} / {repo.name}</h1>
                        <Tag color={repo.enabled ? 'green' : 'red'}>{repo.enabled ? '已启用' : '已禁用'}</Tag>
                        <Tag>{repo.platform}</Tag>
                    </div>
                    <div className="text-slate-500 text-sm mb-4">
                        {repo.fullName || repo.cloneUrl || '暂无描述'}
                    </div>

                </div>

            </div>
        </div>
    );

    const renderBreadcrumbs = () => {
        const parts = (viewingFile ? viewingFile.path : currentPath).split('/').filter(Boolean);
        return (
            <div className="flex items-center text-sm text-slate-600 breadcrumbs">
                <span
                    className="font-semibold text-blue-600 cursor-pointer hover:underline"
                    onClick={() => { setViewingFile(null); setCurrentPath(''); }}
                >
                    {repo.name}
                </span>
                {parts.map((part, idx) => (
                    <React.Fragment key={idx}>
                        <ChevronRight size={14} className="mx-1 text-slate-400" />
                        <span
                            className={`cursor-pointer hover:underline ${idx === parts.length - 1 ? 'text-slate-800' : 'text-blue-600'}`}
                            onClick={() => {
                                if (idx < parts.length - 1 || !viewingFile) {
                                    handleBreadcrumbClick(idx + 1);
                                }
                            }}
                        >
                            {part}
                        </span>
                    </React.Fragment>
                ))}
            </div>
        );
    };

    const renderFileContent = () => {
        if (!viewingFile) return null;

        const lines = viewingFile.content?.split('\n') || [];

        return (
            <div className="border border-slate-200 rounded-lg overflow-hidden w-full">
                {/* File header */}
                <div className="flex justify-between items-center bg-slate-50 px-4 py-2 border-b border-slate-200">
                    <div className="flex items-center gap-2 text-sm text-slate-600">
                        <FileText size={16} />
                        <span className="font-medium">{viewingFile.name}</span>
                        <span className="text-slate-400">|</span>
                        <span>{lines.length} 行</span>
                        <span className="text-slate-400">|</span>
                        <span>{formatFileSize(viewingFile.size)}</span>
                    </div>
                    <div className="flex items-center gap-2">
                        <Button
                            size="small"
                            icon={<Copy size={12} />}
                            onClick={() => {
                                navigator.clipboard.writeText(viewingFile.content || '');
                                message.success('已复制到剪贴板');
                            }}
                        >
                            复制
                        </Button>
                        <Button
                            size="small"
                            type="primary"
                            icon={<Pencil size={13} />}
                            onClick={handleEditFile}
                        >
                            编辑
                        </Button>
                        <Button
                            size="small"
                            icon={<Download size={13} />}
                            onClick={handleDownloadFile}
                        >
                            下载
                        </Button>
                        <Button
                            size="small"
                            type="text"
                            icon={<X size={14} />}
                            onClick={() => setViewingFile(null)}
                        />
                    </div>
                </div>

                {/* Code content - overflow inside this container only */}
                <div className="max-h-[600px] overflow-auto bg-white" style={{ maxWidth: '100%' }}>
                    <table className="text-sm font-mono" style={{ tableLayout: 'fixed', minWidth: '100%' }}>
                        <tbody>
                            {lines.map((line, idx) => (
                                <tr key={idx} className="hover:bg-slate-50">
                                    <td className="px-3 py-0.5 text-right text-slate-400 select-none border-r border-slate-100 w-12 sticky left-0 bg-slate-50">
                                        {idx + 1}
                                    </td>
                                    <td className="px-4 py-0.5">
                                        <pre className="m-0 whitespace-pre">{line || ' '}</pre>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        );
    };

    const renderFileEditorModal = () => (
        <Modal
            open={Boolean(fileEditor)}
            title={fileEditor?.mode === 'edit' ? `编辑 ${fileEditor.path}` : '上传文件并提交'}
            width={960}
            destroyOnClose
            onCancel={() => !fileSaving && setFileEditor(null)}
            footer={[
                <Button key="cancel" onClick={() => setFileEditor(null)} disabled={fileSaving}>取消</Button>,
                <Button key="save" type="primary" loading={fileSaving} onClick={handleSaveFile}>
                    提交到 {currentRef}
                </Button>
            ]}
        >
            {fileEditor && (
                <div className="space-y-4">
                    <div>
                        <label className="mb-1.5 block text-sm font-medium text-slate-700">仓库内路径</label>
                        <Input
                            value={fileEditor.path}
                            disabled={fileEditor.mode === 'edit'}
                            onChange={event => setFileEditor(current => current ? { ...current, path: event.target.value } : current)}
                            placeholder="例如 src/example.ts"
                        />
                        {fileEditor.mode === 'upload' && (
                            <div className="mt-1.5 text-xs text-slate-400">文件将上传到当前目录，可在此修改目标路径。</div>
                        )}
                    </div>

                    {fileEditor.mode === 'edit' ? (
                        <div>
                            <label className="mb-1.5 block text-sm font-medium text-slate-700">文件内容</label>
                            <Input.TextArea
                                value={fileEditor.content}
                                onChange={event => setFileEditor(current => current ? { ...current, content: event.target.value } : current)}
                                autoSize={{ minRows: 18, maxRows: 28 }}
                                className="font-mono text-xs"
                                spellCheck={false}
                            />
                        </div>
                    ) : (
                        <>
                            <div className="rounded-lg border border-blue-100 bg-blue-50 px-4 py-3 text-sm text-blue-800">
                                已选择 <span className="font-medium">{fileEditor.fileName}</span>
                                {typeof fileEditor.size === 'number' && `（${(fileEditor.size / 1024).toFixed(1)} KB）`}
                            </div>
                            {files.some(file => file.type === 'file' && file.path === fileEditor.path.trim().replace(/^\/+/, '')) && (
                                <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-700">
                                    当前分支已存在同名文件，提交后将覆盖其内容。
                                </div>
                            )}
                        </>
                    )}

                    <div>
                        <label className="mb-1.5 block text-sm font-medium text-slate-700">提交说明</label>
                        <Input
                            value={commitMessage}
                            onChange={event => setCommitMessage(event.target.value)}
                            placeholder="说明本次修改内容"
                        />
                    </div>
                </div>
            )}
        </Modal>
    );

    const items = [
        {
            key: 'code',
            label: <span className="flex items-center gap-1"><Code size={14} /> 代码</span>,
            children: (
                <Spin spinning={loading || fileLoading}>
                    <div className="space-y-4">
                        <input ref={uploadInputRef} type="file" className="hidden" onChange={handleUploadFile} />
                        {/* Toolbar & Branch Selector */}
                        <div className="flex justify-between items-center">
                            <div className="flex items-center gap-2">
                                <Select
                                    value={currentRef}
                                    onChange={(val) => {
                                        setCurrentRef(val);
                                        setCurrentPath('');
                                        setViewingFile(null);
                                    }}
                                    style={{ width: 280 }}
                                    popupMatchSelectWidth={false}
                                    variant="borderless"
                                    className="bg-slate-100 rounded hover:bg-slate-200 transition-colors"
                                >
                                    {branches.map(b => (
                                        <Option key={b.name} value={b.name}>
                                            <GitBranch size={12} className="inline mr-1" /> {b.name}
                                        </Option>
                                    ))}
                                    {branches.length === 0 && (
                                        <Option value={currentRef}><GitBranch size={12} className="inline mr-1" /> {currentRef}</Option>
                                    )}
                                </Select>
                                <div className="h-4 w-px bg-slate-300 mx-2"></div>
                                {renderBreadcrumbs()}
                            </div>
                            <Space>
                                <div className="flex bg-slate-100 rounded p-1 text-slate-600 text-xs">
                                    <span className="px-2 py-1 bg-white shadow-sm rounded cursor-pointer">HTTPS</span>
                                    <span className="px-2 py-1 cursor-pointer hover:bg-white hover:shadow-sm hover:rounded transition-all">SSH</span>
                                </div>
                                <Space.Compact>
                                    <Input
                                        readOnly
                                        value={repo.cloneUrl}
                                        className="text-xs w-64 bg-slate-50 border-slate-200"
                                    />
                                    <Button
                                        icon={<Copy size={12} />}
                                        className="flex items-center justify-center text-slate-500 hover:text-blue-500"
                                        onClick={() => {
                                            navigator.clipboard.writeText(repo.cloneUrl || '');
                                            message.success('已复制到剪贴板');
                                        }}
                                    />
                                </Space.Compact>
                                <Button
                                    type="primary"
                                    icon={<Upload size={15} />}
                                    onClick={() => uploadInputRef.current?.click()}
                                    className="bg-blue-600 hover:bg-blue-700"
                                >
                                    上传文件
                                </Button>
                            </Space>
                        </div>

                        {/* File Content View */}
                        {viewingFile ? (
                            renderFileContent()
                        ) : (
                            <>
                                {/* Commit Info Box */}
                                {latestCommit && (
                                    <div className="border border-blue-200 bg-blue-50 rounded-t-lg p-3 text-sm flex justify-between items-center">
                                        <div className="flex items-center gap-3">
                                            <Avatar size={24} src={latestCommit.authorAvatar || undefined} style={{ backgroundColor: '#1890ff' }}>
                                                {latestCommit.authorName?.charAt(0).toUpperCase()}
                                            </Avatar>
                                            <span className="font-semibold text-slate-700">{latestCommit.authorName}</span>
                                            <span className="text-slate-600 truncate max-w-md">{latestCommit.message?.split('\n')[0]}</span>
                                        </div>
                                        <div className="flex items-center gap-4 text-slate-500 text-xs">
                                            <span className="font-mono">{latestCommit.sha}</span>
                                            <span>{formatCommitTime(latestCommit.committedAt)}</span>
                                            {latestCommit.totalCommits && latestCommit.totalCommits > 0 && (
                                                <div className="flex items-center gap-1 font-semibold text-slate-600">
                                                    <Clock size={12} /> <span>{latestCommit.totalCommits} 次提交</span>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                )}

                                {/* File List Table */}
                                <div
                                    className={`min-h-[160px] max-h-[calc(100vh-360px)] overflow-x-auto overflow-y-scroll border ${latestCommit ? 'border-t-0 rounded-b-lg' : 'rounded-lg'} border-slate-200`}
                                >
                                    <table className="w-full text-sm text-left">
                                        <thead className="sticky top-0 z-10 bg-slate-50 text-slate-500 font-medium">
                                            <tr>
                                                <th className="px-4 py-2 w-1/4">文件名</th>
                                                <th className="px-4 py-2 w-1/2">最新提交信息</th>
                                                <th className="px-4 py-2 w-1/4 text-right">大小</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-slate-100 bg-white">
                                            {files.length === 0 && !loading && (
                                                <tr>
                                                    <td colSpan={3} className="px-4 py-8 text-center text-slate-400">
                                                        暂无文件或无法获取（请检查仓库配置和访问令牌）
                                                    </td>
                                                </tr>
                                            )}
                                            {files.map((file, idx) => (
                                                <tr key={idx} className="hover:bg-slate-50 group cursor-pointer" onClick={() => handleFileClick(file)}>
                                                    <td className="px-4 py-2.5 flex items-center gap-2">
                                                        {file.type === 'dir' ? (
                                                            <div className="text-blue-400"><Folder size={16} fill="currentColor" /></div>
                                                        ) : (
                                                            <div className="text-slate-400"><FileText size={16} /></div>
                                                        )}
                                                        <span className="text-slate-700 group-hover:text-blue-600">
                                                            {file.name}
                                                        </span>
                                                    </td>
                                                    <td className="px-4 py-2.5 text-slate-500 truncate max-w-xs">
                                                        {file.lastCommitMessage || '-'}
                                                    </td>
                                                    <td className="px-4 py-2.5 text-right text-slate-400">
                                                        {file.type === 'file' ? formatFileSize(file.size) : '-'}
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </>
                        )}
                    </div>
                </Spin>
            )
        },
        {
            key: 'repository',
            label: (
                <Dropdown menu={{
                    items: [
                        {
                            key: 'commits',
                            label: '提交',
                            onClick: () => {
                                setViewingCommitList(true);
                                setActiveTab('code'); // Provide context
                            }
                        },
                        {
                            key: 'branches',
                            label: '分支',
                            onClick: () => {
                                setViewingBranchList(true);
                                setActiveTab('code');
                            }
                        },
                        {
                            key: 'tags', label: '标签', onClick: () => {
                                setViewingTagList(true);
                                setActiveTab('code');
                            }
                        },
                    ]
                }}>
                    <span className="flex items-center gap-1" onClick={e => {
                        e.preventDefault();
                        e.stopPropagation();
                    }}>
                        <Folder size={14} /> 仓库 <ChevronRight size={12} className="rotate-90" />
                    </span>
                </Dropdown>
            ),
            children: <div className="p-4 text-center text-slate-500">请选择子菜单查看详情</div>
        },
        {
            key: 'pull-requests',
            label: (
                <span
                    className="flex items-center gap-1 text-indigo-600"
                    onClick={() => setViewingPullRequests(true)}
                >
                    <GitPullRequest size={14} /> Pull Requests <Tag className="ml-1 bg-gradient-to-tr from-indigo-500 to-purple-600 text-white border-none text-xs px-1.5 py-0 rounded-full">{repo.pendingPrCount || 0}</Tag>
                </span>
            ),
            children: (
                <div
                    className="p-8 text-center cursor-pointer hover:bg-slate-50 transition-colors rounded-lg border-2 border-dashed border-slate-200 hover:border-indigo-300"
                    onClick={() => setViewingPullRequests(true)}
                >
                    <GitPullRequest size={48} className="mx-auto mb-4 text-indigo-400" />
                    <div className="text-lg font-medium text-slate-600 mb-2">Pull Request 列表</div>
                    <div className="text-slate-400">点击此区域查看所有 Pull Request</div>
                </div>
            )
        },
        {
            key: 'pipeline',
            label: <span className="flex items-center gap-1"><Play size={14} /> 流水线</span>,
            children: <PipelineManagement ssoId={repo.ssoId} repoId={repo.id} />
        },
        {
            key: 'deploy',
            label: <span className="flex items-center gap-1"><Rocket size={14} /> 部署管理</span>,
            children: <DeploymentManagement ssoId={repo.ssoId} repoId={repo.id} />
        },
        {
            key: 'release',
            label: <span className="flex items-center gap-1"><ClipboardList size={14} /> 发布台账</span>,
            children: <ReleaseLedger ssoId={repo.ssoId} />
        },
        {
            key: 'audit',
            label: <span className="flex items-center gap-1"><ShieldCheck size={14} /> 代码智查</span>,
            children: <AICodeAudit ssoId={repo.ssoId} repoId={repo.id} />
        },
    ];

    // Commit Detail View
    if (viewingCommit) {
        return (
            <CommitDetail
                commit={viewingCommit}
                onBack={() => setViewingCommit(null)}
            />
        );
    }

    // Branch List View
    if (viewingBranchList) {
        return (
            <BranchList
                repoId={repo.id!}
                currentRef={currentRef}
                platform={repo.platform}
                onRefChange={(ref) => {
                    setCurrentRef(ref);
                    setViewingBranchList(false);
                }}
                onBack={backToCodeView}
            />
        );
    }

    // Tag List View
    if (viewingTagList) {
        return (
            <TagList
                repoId={repo.id!}
                onBack={backToCodeView}
            />
        );
    }

    // Pull Request Module View
    if (viewingPullRequests) {
        return (
            <PullRequestModule
                repoId={repo.id!}
                ssoId={repo.ssoId}
                repoName={repo.name}
                onBack={backToCodeView}
                onBackToRepoList={onBack}
            />
        );
    }

    // Commit List View
    if (viewingCommitList) {
        return (
            <CommitList
                repoId={repo.id!}
                currentRef={currentRef}
                branches={branches}
                onRefChange={setCurrentRef}
                onCommitClick={handleCommitClick}
                onBack={backToCodeView}
            />
        );
    }

    // 当查看文件内容时，全屏显示
    if (viewingFile) {
        const lines = viewingFile.content?.split('\n') || [];
        const pathParts = viewingFile.path.split('/').filter(Boolean);

        return (
            <div className="-m-4 overflow-hidden">
                {/* 文件查看头部 */}
                <div className="bg-white p-4 border-b border-slate-200 flex justify-between items-center">
                    <div className="flex items-center gap-3">
                        <Button
                            type="text"
                            icon={<ArrowLeft size={18} />}
                            onClick={() => setViewingFile(null)}
                        >
                            返回
                        </Button>
                        <div className="h-4 w-px bg-slate-300"></div>
                        {/* 面包屑 */}
                        <div className="flex items-center text-sm">
                            <span
                                className="text-blue-600 cursor-pointer hover:underline"
                                onClick={() => { setViewingFile(null); setCurrentPath(''); }}
                            >
                                {repo.name}
                            </span>
                            {pathParts.map((part, idx) => (
                                <React.Fragment key={idx}>
                                    <ChevronRight size={14} className="mx-1 text-slate-400" />
                                    <span
                                        className={idx === pathParts.length - 1 ? 'text-slate-800 font-medium' : 'text-blue-600 cursor-pointer hover:underline'}
                                        onClick={() => {
                                            if (idx < pathParts.length - 1) {
                                                setViewingFile(null);
                                                setCurrentPath(pathParts.slice(0, idx + 1).join('/'));
                                            }
                                        }}
                                    >
                                        {part}
                                    </span>
                                </React.Fragment>
                            ))}
                        </div>
                    </div>
                    <div className="flex items-center gap-2">
                        <Tag>{currentRef}</Tag>
                        <span className="text-slate-500 text-sm">{lines.length} 行</span>
                        <span className="text-slate-400">|</span>
                        <span className="text-slate-500 text-sm">{formatFileSize(viewingFile.size)}</span>
                        <Button
                            size="small"
                            icon={<Copy size={12} />}
                            onClick={() => {
                                navigator.clipboard.writeText(viewingFile.content || '');
                                message.success('已复制到剪贴板');
                            }}
                        >
                            复制
                        </Button>
                        <Button
                            size="small"
                            type="primary"
                            icon={<Pencil size={13} />}
                            onClick={handleEditFile}
                        >
                            编辑
                        </Button>
                        <Button
                            size="small"
                            icon={<Download size={13} />}
                            onClick={handleDownloadFile}
                        >
                            下载
                        </Button>
                    </div>
                </div>

                {/* 文件内容 - 全屏显示，宽度固定 */}
                <div className="bg-white overflow-auto" style={{ height: 'calc(100vh - 180px)', maxWidth: 'calc(100vw - 320px)' }}>
                    <table className="text-sm font-mono" style={{ minWidth: '100%' }}>
                        <tbody>
                            {lines.map((line, idx) => (
                                <tr key={idx} className="hover:bg-blue-50">
                                    <td className="px-4 py-0.5 text-right text-slate-400 select-none border-r border-slate-100 w-16 sticky left-0 bg-slate-50">
                                        {idx + 1}
                                    </td>
                                    <td className="px-4 py-0.5">
                                        <pre className="m-0 whitespace-pre">{line || ' '}</pre>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
                {renderFileEditorModal()}
            </div>
        );
    }

    return (
        <div className="-m-4">
            {renderHeader()}
            <div className="px-6">
                <Tabs activeKey={activeTab} onChange={setActiveTab} items={items} />
            </div>
            {renderFileEditorModal()}
        </div>
    );
};

export default GitRepoDetail;
