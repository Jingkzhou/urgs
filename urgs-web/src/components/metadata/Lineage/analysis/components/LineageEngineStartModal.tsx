import React, { useState, useEffect } from 'react';
import { Modal, Steps, Select, Tree, Form, Input, Card, Button, Space, Typography, Tag, Empty, Spin, message } from 'antd';
import {
    GithubOutlined,
    BranchesOutlined,
    FileSearchOutlined,
    SettingOutlined,
    CheckCircleOutlined,
    FolderOpenOutlined,
    FileTextOutlined,
    LoadingOutlined,
} from '@ant-design/icons';
import {
    getGitRepositories,
    getRepoBranches,
    getRepoFileTree,
    GitRepository,
    GitBranch,
    GitFileEntry
} from '@/api/version';

const { Text, Title, Paragraph } = Typography;

interface LineageEngineStartModalProps {
    open: boolean;
    onCancel: () => void;
    onOk: (values: LineageEngineStartParams) => void;
    loading?: boolean;
}

export interface LineageEngineStartParams {
    repoId: number;
    ref: string;
    paths: string[];
    user?: string;
    language?: string;
}

const LineageEngineStartModal: React.FC<LineageEngineStartModalProps> = ({ open, onCancel, onOk, loading }) => {
    const [currentStep, setCurrentStep] = useState(0);
    const [repos, setRepos] = useState<GitRepository[]>([]);
    const [reposLoading, setReposLoading] = useState(false);
    const [selectedRepoId, setSelectedRepoId] = useState<number | null>(null);
    const [branches, setBranches] = useState<GitBranch[]>([]);
    const [branchesLoading, setBranchesLoading] = useState(false);
    const [selectedRef, setSelectedRef] = useState<string>('');
    const [fileTree, setFileTree] = useState<any[]>([]);
    const [fileTreeLoading, setFileTreeLoading] = useState(false);
    const [selectedPaths, setSelectedPaths] = useState<string[]>([]);
    const [form] = Form.useForm();

    // Load Repositories
    useEffect(() => {
        if (open) {
            setReposLoading(true);
            getGitRepositories()
                .then(res => setRepos(res || []))
                .catch(() => message.error('获取 Git 仓库失败'))
                .finally(() => setReposLoading(false));
        } else {
            // Reset state on close
            setCurrentStep(0);
            setSelectedRepoId(null);
            setBranches([]);
            setSelectedRef('');
            setFileTree([]);
            setSelectedPaths([]);
            form.resetFields();
        }
    }, [open, form]);

    // Load Branches when Repo changes
    useEffect(() => {
        if (selectedRepoId) {
            setBranchesLoading(true);
            getRepoBranches(selectedRepoId)
                .then(res => {
                    setBranches(res || []);
                    const defaultBranch = res?.find(b => b.isDefault)?.name || res?.[0]?.name || '';
                    setSelectedRef(defaultBranch);
                    form.setFieldsValue({ ref: defaultBranch });
                })
                .catch(() => message.error('获取分支失败'))
                .finally(() => setBranchesLoading(false));
        }
    }, [selectedRepoId, form]);

    // Load File Tree when Ref or Repo changes
    const loadFileTree = (path: string = '') => {
        if (selectedRepoId && selectedRef) {
            setFileTreeLoading(true);
            getRepoFileTree(selectedRepoId, selectedRef, path)
                .then(res => {
                    const nodes = formatFileTree(res || []);
                    setFileTree(nodes);
                })
                .catch(() => message.error('获取文件树失败'))
                .finally(() => setFileTreeLoading(false));
        }
    };

    useEffect(() => {
        if (currentStep === 1) {
            loadFileTree();
        }
    }, [currentStep, selectedRepoId, selectedRef]);

    const formatFileTree = (entries: GitFileEntry[]): any[] => {
        return entries.map(entry => ({
            title: entry.name,
            key: entry.path,
            isLeaf: entry.type === 'file',
            icon: entry.type === 'dir' ? <FolderOpenOutlined style={{ color: '#1890ff' }} /> : <FileTextOutlined />,
        }));
    };

    const updateTreeData = (list: any[], key: React.Key, children: any[]): any[] => {
        return list.map(node => {
            if (node.key === key) {
                return { ...node, children };
            }
            if (node.children) {
                return { ...node, children: updateTreeData(node.children, key, children) };
            }
            return node;
        });
    };

    const onLoadData = ({ key, children }: any) => {
        if (children && children.length > 0) {
            return Promise.resolve();
        }
        return getRepoFileTree(selectedRepoId!, selectedRef, key as string)
            .then(res => {
                const nodes = formatFileTree(res || []);
                setFileTree(origin => updateTreeData(origin, key, nodes));
            });
    };

    const handleNext = () => {
        if (currentStep === 0 && !selectedRepoId) {
            message.warning('请先选择一个代码仓库');
            return;
        }
        setCurrentStep(currentStep + 1);
    };

    const handlePrev = () => {
        setCurrentStep(currentStep - 1);
    };

    const handleSubmit = () => {
        if (selectedPaths.length === 0) {
            message.warning('请至少选择一个文件或目录进行分析');
            return;
        }
        form.validateFields().then(values => {
            onOk({
                repoId: selectedRepoId!,
                ref: selectedRef,
                paths: selectedPaths,
                user: values.user,
                language: values.language,
            });
        });
    };

    // Custom Styles for high-end look
    const modalStyles = {
        body: { padding: '24px 0', minHeight: 480 },
        mask: { backdropFilter: 'blur(8px)', backgroundColor: 'rgba(255,255,255,0.7)' },
    };

    const stepContentStyle: React.CSSProperties = {
        padding: '24px',
        height: '400px',
        overflowY: 'auto' as const,
    };

    return (
        <Modal
            title={
                <Space>
                    <div style={{ padding: 8, background: '#e6f7ff', borderRadius: 8 }}>
                        <SettingOutlined style={{ color: '#1890ff' }} />
                    </div>
                    <Title level={5} style={{ margin: 0 }}>启动分析引擎</Title>
                </Space>
            }
            open={open}
            onCancel={onCancel}
            width={800}
            footer={[
                currentStep > 0 && <Button key="prev" onClick={handlePrev}>上一步</Button>,
                currentStep < 2 && (
                    <Button key="next" type="primary" onClick={handleNext} disabled={!selectedRepoId}>
                        下一步
                    </Button>
                ),
                currentStep === 2 && (
                    <Button key="submit" type="primary" onClick={handleSubmit} loading={loading}>
                        开始分析
                    </Button>
                ),
            ]}
            styles={modalStyles}
            destroyOnClose
        >
            <div style={{ padding: '0 40px' }}>
                <Steps
                    current={currentStep}
                    size="small"
                    style={{ marginBottom: 24 }}
                    items={[
                        { title: '选择仓库', icon: <GithubOutlined /> },
                        { title: '浏览文件', icon: <FileSearchOutlined /> },
                        { title: '分析配置', icon: <SettingOutlined /> },
                    ]}
                />
            </div>

            <div style={stepContentStyle}>
                {currentStep === 0 && (
                    <div style={{ animation: 'fadeIn 0.5s ease-out' }}>
                        <Paragraph type="secondary" style={{ marginBottom: 20 }}>
                            请选择您需要进行血缘分析的 Git 仓库及其代码分支。
                        </Paragraph>
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 16 }}>
                            {reposLoading ? (
                                <div style={{ gridColumn: '1/-1', textAlign: 'center', padding: 40 }}>
                                    <Spin indicator={<LoadingOutlined style={{ fontSize: 24 }} spin />} />
                                </div>
                            ) : repos.length > 0 ? (
                                repos.map(repo => (
                                    <Card
                                        key={repo.id}
                                        hoverable
                                        size="small"
                                        style={{
                                            border: selectedRepoId === repo.id ? '2px solid #1890ff' : '2px solid #f0f0f0',
                                            transition: 'all 0.3s ease',
                                            borderRadius: 12,
                                            backgroundColor: selectedRepoId === repo.id ? '#f0f7ff' : '#fff'
                                        }}
                                        onClick={() => setSelectedRepoId(repo.id || null)}
                                    >
                                        <Space align="start">
                                            <div style={{
                                                width: 36,
                                                height: 36,
                                                borderRadius: 10,
                                                background: selectedRepoId === repo.id ? '#1890ff' : '#f5f5f5',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                color: selectedRepoId === repo.id ? '#fff' : '#666'
                                            }}>
                                                <GithubOutlined style={{ fontSize: 18 }} />
                                            </div>
                                            <div>
                                                <Text strong style={{ fontSize: 13, display: 'block' }}>{repo.name}</Text>
                                                <Tag color="default" style={{ marginTop: 4, borderRadius: 10, fontSize: 10 }}>{repo.platform}</Tag>
                                            </div>
                                            {selectedRepoId === repo.id && <CheckCircleOutlined style={{ color: '#1890ff', marginLeft: 'auto' }} />}
                                        </Space>
                                    </Card>
                                ))
                            ) : (
                                <Empty description="暂无配置的 Git 仓库" style={{ gridColumn: '1/-1' }} />
                            )}
                        </div>

                        {selectedRepoId && (
                            <div style={{ marginTop: 32, padding: 20, background: '#fafafa', borderRadius: 12 }}>
                                <Form layout="vertical" form={form}>
                                    <Form.Item label={<Space><BranchesOutlined /> <span>选择分析分支/标签</span></Space>} name="ref" style={{ marginBottom: 0 }}>
                                        <Select
                                            placeholder="请选择分支"
                                            loading={branchesLoading}
                                            value={selectedRef}
                                            onChange={val => setSelectedRef(val)}
                                            style={{ width: '100%' }}
                                            options={branches.map(b => ({ label: b.name, value: b.name }))}
                                        />
                                    </Form.Item>
                                </Form>
                            </div>
                        )}
                    </div>
                )}

                {currentStep === 1 && (
                    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', animation: 'fadeIn 0.5s ease-out' }}>
                        <div style={{ marginBottom: 12 }}>
                            <Text type="secondary">请在下方文件树中选择要解析的 SQL 文件或目录：</Text>
                            {selectedPaths.length > 0 && (
                                <div style={{ marginTop: 8, maxHeight: '100px', overflowY: 'auto' }}>
                                    <Text style={{ fontSize: '12px' }}>已选择: </Text>
                                    <Space wrap size={[4, 4]}>
                                        {selectedPaths.map(p => <Tag key={p} closable onClose={() => setSelectedPaths(selectedPaths.filter(val => val !== p))}>{p.split('/').pop()}</Tag>)}
                                    </Space>
                                </div>
                            )}
                        </div>
                        <div style={{ flex: 1, overflow: 'auto', border: '1px solid #f0f0f0', borderRadius: 12, padding: 12, background: '#fff' }}>
                            {fileTreeLoading ? (
                                <div style={{ textAlign: 'center', padding: '100px 0' }}>
                                    <Spin />
                                </div>
                            ) : (
                                <Tree
                                    checkable
                                    showIcon
                                    loadData={onLoadData}
                                    treeData={fileTree}
                                    onCheck={(checked: any) => setSelectedPaths(checked)}
                                    checkedKeys={selectedPaths}
                                />
                            )}
                        </div>
                    </div>
                )}

                {currentStep === 2 && (
                    <div style={{ padding: '20px 60px', animation: 'fadeIn 0.5s ease-out' }}>
                        <Title level={4} style={{ textAlign: 'center', marginBottom: 32 }}>最后一步：配置分析参数</Title>
                        <Form form={form} layout="vertical">
                            <Form.Item
                                label="默认用户"
                                name="user"
                                tooltip="在 SQL 解析过程中，如果未指定 Schema，将使用该用户作为默认前缀"
                            >
                                <Input placeholder="请输入默认用户" prefix={<SettingOutlined style={{ color: '#bfbfbf' }} />} />
                            </Form.Item>
                            <Form.Item
                                label="SQL 方言"
                                name="language"
                                initialValue="oracle"
                            >
                                <Select
                                    options={[
                                        { label: 'Oracle', value: 'oracle' },
                                        { label: 'Hive', value: 'hive' },
                                        { label: 'PostgreSQL', value: 'postgres' },
                                        { label: 'MySQL', value: 'mysql' },
                                    ]}
                                />
                            </Form.Item>

                            <div style={{ marginTop: 40, padding: 20, background: '#fffbe6', borderRadius: 12, border: '1px solid #ffe58f' }}>
                                <Space align="start">
                                    <CheckCircleOutlined style={{ color: '#faad14', marginTop: 4 }} />
                                    <div style={{ fontSize: 13, color: 'rgba(0,0,0,0.65)' }}>
                                        提示：启动后后台将异步下载仓库代码并由 Python 引擎执行解析。解析时间取决于文件数量及复杂度。
                                    </div>
                                </Space>
                            </div>
                        </Form>
                    </div>
                )}
            </div>

            <style dangerouslySetInnerHTML={{
                __html: `
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .ant-modal-content {
          border-radius: 16px !important;
          overflow: hidden;
        }
        .ant-modal-header {
          border-bottom: 1px solid #f0f0f0;
          padding: 16px 24px !important;
          margin-bottom: 0 !important;
        }
      `}} />
        </Modal>
    );
};

export default LineageEngineStartModal;
