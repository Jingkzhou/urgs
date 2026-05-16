import React from 'react';
import { Badge, Button, Divider, Modal, Popover, Space, Tag, Tooltip } from 'antd';
import {
    DeleteOutlined,
    FileTextOutlined,
    PlayCircleOutlined,
    PoweroffOutlined,
    ReloadOutlined,
    RobotOutlined,
} from '@ant-design/icons';
import EngineLogViewer from './EngineLogViewer';
import LineageEngineStartModal from './LineageEngineStartModal';
import type { UseLineageEngineControllerResult } from '../hooks/useLineageEngineController';

const RunDuration: React.FC<{ startTime: string }> = ({ startTime }) => {
    const [duration, setDuration] = React.useState('');

    React.useEffect(() => {
        const update = () => {
            if (!startTime) {
                return;
            }

            const start = new Date(startTime).getTime();
            const now = new Date().getTime();
            const diff = Math.max(0, Math.floor((now - start) / 1000));
            const hours = Math.floor(diff / 3600);
            const minutes = Math.floor((diff % 3600) / 60);
            const seconds = diff % 60;

            setDuration(
                `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
            );
        };

        update();
        const timer = window.setInterval(update, 1000);
        return () => window.clearInterval(timer);
    }, [startTime]);

    if (!duration) {
        return null;
    }

    return <span style={{ fontFamily: 'monospace' }}>{duration}</span>;
};

interface LineageEngineToolbarProps {
    controller: UseLineageEngineControllerResult;
    canOpenAuditBoard?: boolean;
    onOpenAuditBoard?: () => void;
}

const LineageEngineToolbar: React.FC<LineageEngineToolbarProps> = ({
    controller,
    canOpenAuditBoard = false,
    onOpenAuditBoard,
}) => {
    const {
        autoRefresh,
        canRestartEngine,
        canStartEngine,
        canStopEngine,
        canViewEngineLogs,
        canViewEngineStatus,
        engineActionLoading,
        engineLogs,
        engineLogsLoading,
        engineMeta,
        engineStatus,
        engineStatusInfo,
        fetchEngineLogs,
        handleClearDatabase,
        handleCloseLogs,
        handleConfirmStartEngine,
        handleOpenLogs,
        handleRestartEngine,
        handleStartEngine,
        handleStopEngine,
        setAutoRefresh,
        setShowStartModal,
        showLogModal,
        showStartModal,
    } = controller;

    const taskPanel = (
        <div style={{ width: 360 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
                <div>
                    <div style={{ fontSize: 14, fontWeight: 600, color: '#111827' }}>解析任务</div>
                    <div style={{ marginTop: 2, fontSize: 12, color: '#64748b' }}>SQL 血缘解析、校验与引擎控制</div>
                </div>
                {canViewEngineStatus ? (
                    <Badge status={engineStatusInfo.badge} text={engineStatusInfo.label} />
                ) : (
                    <Badge status="default" text="无权限" />
                )}
            </div>

            <div style={{ marginTop: 12, padding: 12, border: '1px solid #e5e7eb', borderRadius: 8, background: '#f8fafc' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                    <span style={{ fontSize: 12, color: '#64748b' }}>引擎状态</span>
                    {canViewEngineStatus ? <Badge status={engineStatusInfo.badge} text={engineStatusInfo.label} /> : <Badge status="default" text="无权限" />}
                    {engineMeta.versionStatus && !engineMeta.versionStatus.consistent && (
                        <Tooltip title={
                            <div>
                                <p>{engineMeta.versionStatus.message}</p>
                                <p style={{ fontSize: 11, opacity: 0.8 }}>最近分析 SHA: {engineMeta.versionStatus.lastCommitSha?.substring(0, 8)}</p>
                                <p style={{ fontSize: 11, opacity: 0.8 }}>Git 最新 SHA: {engineMeta.versionStatus.currentCommitSha?.substring(0, 8)}</p>
                            </div>
                        }>
                            <Tag color="warning" icon={<ReloadOutlined spin />} style={{ margin: 0, cursor: 'help', borderRadius: 10 }}>数据过时</Tag>
                        </Tooltip>
                    )}
                </div>
                <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 4, fontSize: 12, color: '#64748b' }}>
                    {engineMeta.pid ? <span>PID {engineMeta.pid}</span> : <span>暂无进程信息</span>}
                    {engineMeta.lastStartedAt && engineStatus === 'running' ? (
                        <span title={engineMeta.lastStartedAt}>
                            启动于 {new Date(engineMeta.lastStartedAt).toLocaleString('zh-CN', { hour12: false })}
                            <span style={{ margin: '0 4px' }}>·</span>
                            已运行 <RunDuration startTime={engineMeta.lastStartedAt} />
                        </span>
                    ) : null}
                </div>
            </div>

            <Divider style={{ margin: '12px 0' }} />

            <div style={{ display: 'grid', gap: 8 }}>
                <Button
                    block
                    icon={<RobotOutlined />}
                    disabled={!canOpenAuditBoard}
                    title={canOpenAuditBoard ? '在当前血缘页面打开 SQL 血缘事后校验看板' : '缺少 version:ai:audit 权限'}
                    onClick={onOpenAuditBoard}
                >
                    打开事后校验
                </Button>

                <Space size={8} wrap>
                    {canStartEngine ? (
                        <Button
                            type="primary"
                            icon={<PlayCircleOutlined />}
                            loading={engineActionLoading === 'start'}
                            disabled={engineStatus === 'running' || engineStatus === 'starting'}
                            onClick={handleStartEngine}
                        >
                            启动引擎
                        </Button>
                    ) : null}
                    {canRestartEngine ? (
                        <Button
                            icon={<ReloadOutlined />}
                            loading={engineActionLoading === 'restart'}
                            disabled={engineStatus !== 'running'}
                            onClick={handleRestartEngine}
                        >
                            重启
                        </Button>
                    ) : null}
                    {canStopEngine ? (
                        <Button
                            danger
                            icon={<PoweroffOutlined />}
                            loading={engineActionLoading === 'stop'}
                            disabled={engineStatus !== 'running'}
                            onClick={handleStopEngine}
                        >
                            停止
                        </Button>
                    ) : null}
                    {canViewEngineLogs ? (
                        <Button icon={<FileTextOutlined />} onClick={handleOpenLogs}>
                            查看日志
                        </Button>
                    ) : null}
                    {canStopEngine ? (
                        <Button
                            danger
                            icon={<DeleteOutlined />}
                            loading={engineActionLoading === 'clear'}
                            onClick={handleClearDatabase}
                        >
                            清空数据
                        </Button>
                    ) : null}
                </Space>
            </div>
        </div>
    );

    return (
        <>
            <Popover content={taskPanel} trigger="click" placement="bottomRight">
                <Button icon={<RobotOutlined />}>
                    解析任务
                    <Badge status={canViewEngineStatus ? engineStatusInfo.badge : 'default'} style={{ marginLeft: 8 }} />
                </Button>
            </Popover>
            <Modal
                title={<div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><FileTextOutlined /> 引擎执行日志</div>}
                open={showLogModal}
                onCancel={handleCloseLogs}
                footer={null}
                width={840}
                styles={{ body: { padding: 0 } }}
            >
                <EngineLogViewer
                    logs={engineLogs}
                    loading={engineLogsLoading}
                    autoRefresh={autoRefresh}
                    onAutoRefreshChange={setAutoRefresh}
                    onRefresh={() => fetchEngineLogs(false, undefined, 'viewer_refresh')}
                />
            </Modal>
            <LineageEngineStartModal
                open={showStartModal}
                onCancel={() => setShowStartModal(false)}
                onOk={handleConfirmStartEngine}
                loading={engineActionLoading === 'start'}
            />
        </>
    );
};

export default LineageEngineToolbar;
