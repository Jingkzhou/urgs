import React from 'react';
import { Alert, Button, Card, Descriptions, Form, Input, List, Select, Space, Steps, Tag } from 'antd';
import { CheckCircle, Download, History, Package, RefreshCw, Tag as TagIcon } from 'lucide-react';
import {
    GitCommit,
    GitRepository,
    GitTag as IGitTag,
    ProductionPackageBuildResult,
    ProductionPackageGateResult,
    ProductionPackageRequest
} from '@/api/version';
import type { FormInstance } from 'antd';

const { Option } = Select;

interface ProductionPackagePanelProps {
    productionForm: FormInstance<ProductionPackageRequest>;
    repoId?: number;
    repos: GitRepository[];
    selectedRepo: number | null;
    tags: IGitTag[];
    fetchingGit: boolean;
    gateLoading: boolean;
    buildLoading: boolean;
    commitLoading: boolean;
    releaseCommits: GitCommit[];
    watchedGitRef?: string;
    watchedPreviousGitRef?: string;
    gateResult: ProductionPackageGateResult | null;
    buildResult: ProductionPackageBuildResult | null;
    currentStep: number;
    onRepoChange: (targetRepoId: number) => void;
    onTagChange: (tagName: string) => void;
    onPreviousTagChange: () => void;
    onGateCheck: () => void;
    onBuildPackage: () => void;
    onDownloadProduction: (packageId: number, fileName?: string) => void;
    onOpenRecordModal: () => void;
}

const ProductionPackagePanel: React.FC<ProductionPackagePanelProps> = ({
    productionForm,
    repoId,
    repos,
    selectedRepo,
    tags,
    fetchingGit,
    gateLoading,
    buildLoading,
    commitLoading,
    releaseCommits,
    watchedGitRef,
    watchedPreviousGitRef,
    gateResult,
    buildResult,
    currentStep,
    onRepoChange,
    onTagChange,
    onPreviousTagChange,
    onGateCheck,
    onBuildPackage,
    onDownloadProduction,
    onOpenRecordModal
}) => {
    const renderGatePanel = () => {
        if (!gateResult) {
            return (
                <Alert
                    type="info"
                    showIcon
                    message="等待门禁校验"
                    description="系统会读取当前 Tag 中的 .urgs/release.yml，并基于需求编号匹配当前 Tag 中的投产文件生成门禁结果。"
                />
            );
        }

        const summary = gateResult.changeSummary;
        return (
            <div className="space-y-4">
                <Alert
                    type={gateResult.status === 'passed' ? 'success' : 'error'}
                    showIcon
                    message={gateResult.summary}
                    description={gateResult.status === 'passed'
                        ? '生产执行时会先校验存储过程生产版本与上一 Tag 基线版本，一旦不一致会在备份前终止。'
                        : '门禁未通过，请按失败项补齐发布规格、备份、回滚内容或需求编号文件后重新校验。'}
                />
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {gateResult.gates.map(item => (
                        <div key={item.key} className="border border-slate-200 rounded-lg p-3 bg-white">
                            <div className="flex items-center justify-between mb-1">
                                <span className="font-semibold text-slate-800 text-sm">{item.label}</span>
                                <Tag color={item.status === 'passed' ? 'success' : 'error'}>{item.status === 'passed' ? '通过' : '失败'}</Tag>
                            </div>
                            <div className="text-xs text-slate-500 leading-5">{item.message || '-'}</div>
                        </div>
                    ))}
                </div>
                <Descriptions size="small" bordered column={2}>
                    <Descriptions.Item label="规格文件">{gateResult.specPath || '-'}</Descriptions.Item>
                    <Descriptions.Item label="投产类型">{gateResult.packageType || '-'}</Descriptions.Item>
                    <Descriptions.Item label="需求编号">{gateResult.requirementNumber || '-'}</Descriptions.Item>
                    <Descriptions.Item label="SQL">{summary?.sqlFiles?.length || 0} 个</Descriptions.Item>
                    <Descriptions.Item label="存储过程">{summary?.procedureFiles?.length || 0} 个</Descriptions.Item>
                    <Descriptions.Item label="备份脚本">{summary?.backupFiles?.length || 0} 个</Descriptions.Item>
                    <Descriptions.Item label="回滚脚本">{summary?.rollbackFiles?.length || 0} 个</Descriptions.Item>
                </Descriptions>
                <List
                    size="small"
                    bordered
                    header={<span className="font-semibold">需求编号匹配到的投产文件</span>}
                    dataSource={gateResult.includedFiles || []}
                    locale={{ emptyText: '暂无匹配文件' }}
                    renderItem={item => <List.Item><span className="font-mono text-xs">{item}</span></List.Item>}
                />
            </div>
        );
    };

    return (
        <div className="space-y-5">
            <Steps
                size="small"
                current={currentStep}
                items={[
                    { title: '选择 Tag' },
                    { title: '填写需求' },
                    { title: '门禁校验' },
                    { title: '生成生产包' },
                    { title: '回填结果' }
                ]}
            />

            <div className="grid grid-cols-1 xl:grid-cols-[420px_1fr] gap-5">
                <Card title="生产投产参数" className="border-slate-200 shadow-sm">
                    <Form form={productionForm} layout="vertical">
                        <Form.Item name="repoId" label="Git 仓库" rules={[{ required: true, message: '请选择 Git 仓库' }]}>
                            {repoId ? (
                                <div className="p-3 bg-slate-50 rounded-lg border border-slate-100">
                                    <div className="font-semibold text-slate-800">{repos.find(r => r.id === repoId)?.name || '当前仓库'}</div>
                                    <div className="text-xs text-slate-400 font-mono break-all mt-1">{repos.find(r => r.id === repoId)?.cloneUrl}</div>
                                </div>
                            ) : (
                                <Select placeholder="选择 Git 仓库" onChange={onRepoChange}>
                                    {repos.map(repo => <Option key={repo.id} value={repo.id}>{repo.name}</Option>)}
                                </Select>
                            )}
                        </Form.Item>

                        <Form.Item name="gitRef" label="当前投产 Tag" rules={[{ required: true, message: '请选择当前投产 Tag' }]}>
                            <Select
                                placeholder={selectedRepo ? '选择当前投产 Tag' : '请先选择仓库'}
                                disabled={!selectedRepo}
                                loading={fetchingGit}
                                showSearch
                                onChange={onTagChange}
                            >
                                {tags.map(tag => (
                                    <Option key={tag.name} value={tag.name}>
                                        <Space>
                                            <TagIcon size={14} />
                                            <span>{tag.name}</span>
                                            {tag.taggerDate && <span className="text-xs text-slate-400">{tag.taggerDate.split('T')[0]}</span>}
                                        </Space>
                                    </Option>
                                ))}
                            </Select>
                        </Form.Item>

                        <Form.Item name="previousGitRef" label="上一投产 Tag" rules={[{ required: true, message: '请选择上一投产 Tag' }]}>
                            <Select
                                placeholder={selectedRepo ? '选择上一投产 Tag' : '请先选择仓库'}
                                disabled={!selectedRepo}
                                loading={fetchingGit}
                                showSearch
                                onChange={onPreviousTagChange}
                            >
                                {tags
                                    .filter(tag => tag.name !== productionForm.getFieldValue('gitRef'))
                                    .map(tag => (
                                        <Option key={tag.name} value={tag.name}>
                                            <Space>
                                                <History size={14} />
                                                <span>{tag.name}</span>
                                                {tag.taggerDate && <span className="text-xs text-slate-400">{tag.taggerDate.split('T')[0]}</span>}
                                            </Space>
                                        </Option>
                                    ))}
                            </Select>
                        </Form.Item>

                        <Form.Item
                            name="requirementNumber"
                            label="需求编号"
                            rules={[{ required: true, whitespace: true, message: '请输入需求编号' }]}
                        >
                            <Input placeholder="用于匹配当前 Tag 中包含该编号的投产文件" />
                        </Form.Item>

                        <Form.Item name="envId" hidden><Input /></Form.Item>

                        <Form.Item name="description" label="投产说明">
                            <Input.TextArea rows={8} placeholder="选择当前投产 Tag 和上一投产 Tag 后自动带出两次 Tag 之间的提交记录" />
                        </Form.Item>
                        <div className="mb-4 -mt-3 text-xs text-slate-500">
                            {commitLoading
                                ? '正在读取两次 Tag 之间的提交记录...'
                                : watchedGitRef && watchedPreviousGitRef
                                    ? `已带出 ${releaseCommits.length} 条提交记录，可在生成生产包前补充风险点和验证说明。`
                                    : '选择完整 Tag 后自动带出提交记录。'}
                        </div>

                        <Space wrap>
                            <Button icon={<RefreshCw size={14} />} onClick={onGateCheck} loading={gateLoading}>
                                执行门禁校验
                            </Button>
                            <Button type="primary" icon={<Package size={14} />} onClick={onBuildPackage} loading={buildLoading} disabled={gateResult?.status !== 'passed'}>
                                生成生产投产包
                            </Button>
                        </Space>
                    </Form>
                </Card>

                <div className="space-y-4">
                    <Card title="生产门禁" className="border-slate-200 shadow-sm">
                        {renderGatePanel()}
                    </Card>

                    {buildResult && (
                        <Card title="生产执行命令" className="border-emerald-200 shadow-sm bg-emerald-50/30">
                            <div className="space-y-3">
                                <Alert type="success" showIcon message="生产投产包已生成" description={buildResult.packageName} />
                                <Descriptions size="small" bordered column={1}>
                                    <Descriptions.Item label="部署命令">
                                        <code>{buildResult.deployCommand}</code>
                                    </Descriptions.Item>
                                    <Descriptions.Item label="回滚命令">
                                        <code>{buildResult.rollbackCommand}</code>
                                    </Descriptions.Item>
                                </Descriptions>
                                <Space wrap>
                                    <Button type="primary" icon={<Download size={14} />} onClick={() => onDownloadProduction(buildResult.packageId, buildResult.packageName)}>
                                        下载生产投产包
                                    </Button>
                                    <Button icon={<CheckCircle size={14} />} onClick={onOpenRecordModal}>
                                        回填生产执行结果
                                    </Button>
                                </Space>
                            </div>
                        </Card>
                    )}
                </div>
            </div>
        </div>
    );
};

export default ProductionPackagePanel;
