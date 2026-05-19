import React from 'react';
import { Alert, Button, Checkbox, Descriptions, Form, Input, List, Modal, Select, Space, Tag, Upload } from 'antd';
import { CheckCircle, Download, UploadCloud } from 'lucide-react';
import { DeployEnvironment, VersionPackage } from '@/api/version';
import type { FormInstance } from 'antd';

const { Option } = Select;

type StatusConfig = Record<string, { color: string; icon: React.ReactNode; label: string }>;

interface DeploymentPackageModalsProps {
    statusConfig: StatusConfig;
    environments: DeployEnvironment[];
    detailModalVisible: boolean;
    selectedPackageDetail: VersionPackage | null;
    fileListModalVisible: boolean;
    fileListPackage: VersionPackage | null;
    recordModalVisible: boolean;
    recordPackage: VersionPackage | null;
    recordForm: FormInstance;
    watchedRecordStatus?: string;
    watchedManualChecked?: boolean;
    logParseMessage: string;
    logParseStatus: 'success' | 'error' | 'warning' | 'info';
    setDetailModalVisible: (visible: boolean) => void;
    setFileListModalVisible: (visible: boolean) => void;
    setRecordModalVisible: (visible: boolean) => void;
    setRecordPackage: (pkg: VersionPackage | null) => void;
    setLogParseMessage: (message: string) => void;
    setLogParseStatus: (status: 'success' | 'error' | 'warning' | 'info') => void;
    handleRecordResult: () => void;
    handleDeploymentLogFile: (file: File) => void;
    handleDownloadProduction: (packageId: number, fileName?: string) => void;
    handleDownloadLegacy: (pkg: VersionPackage) => void;
    openRecordModal: (pkg?: VersionPackage) => void;
    openPackageFileList: (pkg: VersionPackage) => void;
    exportPackageExcel: (pkg?: VersionPackage | null) => void;
    parsePackageFiles: (pkg?: VersionPackage | null) => string[];
    packageDeployCommand: (pkg?: VersionPackage | null) => string;
    packageRollbackCommand: (pkg?: VersionPackage | null) => string;
    packageDeployLogPath: () => string;
}

const DeploymentPackageModals: React.FC<DeploymentPackageModalsProps> = ({
    statusConfig,
    environments,
    detailModalVisible,
    selectedPackageDetail,
    fileListModalVisible,
    fileListPackage,
    recordModalVisible,
    recordPackage,
    recordForm,
    watchedRecordStatus,
    watchedManualChecked,
    logParseMessage,
    logParseStatus,
    setDetailModalVisible,
    setFileListModalVisible,
    setRecordModalVisible,
    setRecordPackage,
    setLogParseMessage,
    setLogParseStatus,
    handleRecordResult,
    handleDeploymentLogFile,
    handleDownloadProduction,
    handleDownloadLegacy,
    openRecordModal,
    openPackageFileList,
    exportPackageExcel,
    parsePackageFiles,
    packageDeployCommand,
    packageRollbackCommand,
    packageDeployLogPath
}) => (
    <>
        <Modal
            title="投产包详情"
            open={detailModalVisible}
            onCancel={() => setDetailModalVisible(false)}
            footer={selectedPackageDetail ? (
                <Space wrap>
                    <Button
                        icon={<Download size={14} />}
                        onClick={() => {
                            const isProductionPackage = !!selectedPackageDetail.deployCommand || selectedPackageDetail.packageUrl?.startsWith('generated://production');
                            isProductionPackage
                                ? handleDownloadProduction(selectedPackageDetail.id, selectedPackageDetail.packageName)
                                : handleDownloadLegacy(selectedPackageDetail);
                        }}
                    >
                        下载投产包
                    </Button>
                    <Button icon={<CheckCircle size={14} />} onClick={() => openRecordModal(selectedPackageDetail)}>
                        回填生产执行结果
                    </Button>
                    <Button icon={<Download size={14} />} onClick={() => exportPackageExcel(selectedPackageDetail)}>
                        导出 Excel
                    </Button>
                </Space>
            ) : null}
            width={760}
        >
            {selectedPackageDetail && (
                <div className="space-y-4">
                    <Descriptions size="small" bordered column={2}>
                        <Descriptions.Item label="版本">{selectedPackageDetail.version || '-'}</Descriptions.Item>
                        <Descriptions.Item label="包名">{selectedPackageDetail.packageName || '-'}</Descriptions.Item>
                        <Descriptions.Item label="当前 Tag">{selectedPackageDetail.gitRef || '-'}</Descriptions.Item>
                        <Descriptions.Item label="基线 Tag">{selectedPackageDetail.previousGitRef || '-'}</Descriptions.Item>
                        <Descriptions.Item label="需求编号">{selectedPackageDetail.requirementNumber || '-'}</Descriptions.Item>
                        <Descriptions.Item label="环境">
                            {environments.find(e => String(e.id) === String(selectedPackageDetail.envId))?.name || '-'}
                        </Descriptions.Item>
                        <Descriptions.Item label="状态">
                            <Tag color={(statusConfig[selectedPackageDetail.status] || statusConfig.ready).color}>
                                {(statusConfig[selectedPackageDetail.status] || statusConfig.ready).label}
                            </Tag>
                        </Descriptions.Item>
                        <Descriptions.Item label="门禁">{selectedPackageDetail.gateStatus || '-'}</Descriptions.Item>
                        <Descriptions.Item label="类型">{selectedPackageDetail.packageType || '-'}</Descriptions.Item>
                        <Descriptions.Item label="创建时间" span={2}>
                            {selectedPackageDetail.createdAt ? new Date(selectedPackageDetail.createdAt).toLocaleString() : '-'}
                        </Descriptions.Item>
                        <Descriptions.Item label="部署命令" span={2}>
                            <code>{packageDeployCommand(selectedPackageDetail)}</code>
                        </Descriptions.Item>
                        <Descriptions.Item label="回滚命令" span={2}>
                            <code>{packageRollbackCommand(selectedPackageDetail)}</code>
                        </Descriptions.Item>
                        <Descriptions.Item label="回填日志文件路径" span={2}>
                            <div className="font-mono text-xs text-slate-700">{packageDeployLogPath()}</div>
                        </Descriptions.Item>
                    </Descriptions>
                    {selectedPackageDetail.description && (
                        <div className="rounded-lg border border-slate-200 bg-slate-50 p-3">
                            <div className="mb-2 text-sm font-semibold text-slate-700">投产说明</div>
                            <pre className="whitespace-pre-wrap break-words text-xs leading-5 text-slate-600">{selectedPackageDetail.description}</pre>
                        </div>
                    )}
                    {selectedPackageDetail.buildLog && (
                        <button
                            type="button"
                            className="w-full rounded-lg border border-slate-200 bg-slate-50 p-3 text-left text-xs text-slate-600 hover:border-indigo-200 hover:bg-indigo-50 hover:text-indigo-700"
                            onClick={() => openPackageFileList(selectedPackageDetail)}
                        >
                            {selectedPackageDetail.buildLog}
                        </button>
                    )}
                </div>
            )}
        </Modal>

        <Modal
            title="投产文件清单"
            open={fileListModalVisible}
            onCancel={() => setFileListModalVisible(false)}
            footer={(
                <Space>
                    <Button onClick={() => setFileListModalVisible(false)}>关闭</Button>
                    <Button type="primary" icon={<Download size={14} />} onClick={() => exportPackageExcel(fileListPackage)}>
                        导出 Excel
                    </Button>
                </Space>
            )}
            width={760}
        >
            <div className="space-y-3">
                <Descriptions size="small" bordered column={2}>
                    <Descriptions.Item label="投产包">
                        {fileListPackage?.packageName || fileListPackage?.version || '-'}
                    </Descriptions.Item>
                    <Descriptions.Item label="文件数">
                        {parsePackageFiles(fileListPackage).length}
                    </Descriptions.Item>
                    <Descriptions.Item label="当前 Tag">{fileListPackage?.gitRef || '-'}</Descriptions.Item>
                    <Descriptions.Item label="基线 Tag">{fileListPackage?.previousGitRef || '-'}</Descriptions.Item>
                    <Descriptions.Item label="需求编号">{fileListPackage?.requirementNumber || '-'}</Descriptions.Item>
                </Descriptions>
                <List
                    size="small"
                    bordered
                    dataSource={parsePackageFiles(fileListPackage)}
                    locale={{ emptyText: '暂无投产文件记录' }}
                    renderItem={(item, index) => (
                        <List.Item>
                            <span className="mr-3 text-xs text-slate-400">{index + 1}</span>
                            <span className="font-mono text-xs text-slate-700">{item}</span>
                        </List.Item>
                    )}
                />
            </div>
        </Modal>

        <Modal
            title="回填生产执行结果"
            open={recordModalVisible}
            onOk={handleRecordResult}
            onCancel={() => {
                setRecordModalVisible(false);
                setRecordPackage(null);
                setLogParseMessage('');
            }}
            okButtonProps={{ disabled: !watchedRecordStatus || !watchedManualChecked }}
            okText="确认回填"
            cancelText="取消"
            width={720}
        >
            <Form form={recordForm} layout="vertical">
                {recordPackage && (
                    <Alert
                        className="mb-4"
                        type="info"
                        showIcon
                        message="必须上传当前生产包 deploy.sh 产生的日志文件"
                        description={`当前投产包：VP-${recordPackage.id.toString().padStart(6, '0')} / ${recordPackage.packageName || recordPackage.version || '-'}`}
                    />
                )}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <Form.Item name="packageId" label="投产包 ID" rules={[{ required: true }]}>
                        <Input disabled />
                    </Form.Item>
                    <Form.Item name="logFileName" label="日志文件">
                        <Input disabled placeholder="上传后自动填入" />
                    </Form.Item>
                </div>
                <Form.Item name="envId" hidden><Input /></Form.Item>
                <Form.Item name="logs" hidden rules={[{ required: true, message: '请上传生产执行日志文件' }]}>
                    <Input.TextArea />
                </Form.Item>
                <Upload
                    accept=".log"
                    maxCount={1}
                    beforeUpload={(file) => {
                        handleDeploymentLogFile(file);
                        return false;
                    }}
                    onRemove={() => {
                        recordForm.setFieldsValue({ status: undefined, logs: '', logFileName: undefined, manualChecked: false });
                        setLogParseStatus('info');
                        setLogParseMessage('请上传当前投产包执行 deploy.sh 产生的日志文件，系统会自动识别执行结果。');
                    }}
                >
                    <Button icon={<UploadCloud size={14} />}>上传生产执行日志</Button>
                </Upload>
                {logParseMessage && (
                    <Alert className="mt-3" type={logParseStatus} showIcon message={logParseMessage} />
                )}
                <Form.Item name="status" label="执行结果" rules={[{ required: true }]}>
                    <Select disabled placeholder="上传日志后自动识别">
                        <Option value="success">成功</Option>
                        <Option value="failed">失败</Option>
                        <Option value="blocked">被存储过程一致性校验阻断</Option>
                    </Select>
                </Form.Item>
                <Form.Item
                    name="manualChecked"
                    valuePropName="checked"
                    rules={[
                        {
                            validator: (_, value) => value
                                ? Promise.resolve()
                                : Promise.reject(new Error('请完成人工检核确认'))
                        }
                    ]}
                >
                    <Checkbox>我已人工核验日志文件，确认该日志由当前投产包部署产生，且识别结果与日志一致</Checkbox>
                </Form.Item>
                <Form.Item name="remark" label="备注">
                    <Input.TextArea rows={3} placeholder="填写验证结论、异常说明或回滚说明" />
                </Form.Item>
            </Form>
        </Modal>
    </>
);

export default DeploymentPackageModals;
