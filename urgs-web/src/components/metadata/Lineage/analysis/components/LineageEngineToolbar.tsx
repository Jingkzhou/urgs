import React from 'react';
import { Badge, Button, Modal, Space, Tag, Tooltip } from 'antd';
import {
    DeleteOutlined,
    FileTextOutlined,
    PlayCircleOutlined,
    PoweroffOutlined,
    ReloadOutlined,
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
}

const LineageEngineToolbar: React.FC<LineageEngineToolbarProps> = ({ controller }) => {
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

    return (
        <>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 10px', border: '1px solid #f0f0f0', borderRadius: 8, background: '#fafafa' }}>
                    <span style={{ fontSize: 12, color: '#8c8c8c' }}>引擎控制</span>
                    {canViewEngineStatus ? (
                        <>
                            <Badge status={engineStatusInfo.badge} text={engineStatusInfo.label} />
                            {engineMeta.versionStatus && !engineMeta.versionStatus.consistent && (
                                <Tooltip title={
                                    <div>
                                        <p>{engineMeta.versionStatus.message}</p>
                                        <p style={{ fontSize: 11, opacity: 0.8 }}>最近分析 SHA: {engineMeta.versionStatus.lastCommitSha?.substring(0, 8)}</p>
                                        <p style={{ fontSize: 11, opacity: 0.8 }}>Git 最新 SHA: {engineMeta.versionStatus.currentCommitSha?.substring(0, 8)}</p>
                                    </div>
                                }>
                                    <Tag color="warning" icon={<ReloadOutlined spin />} style={{ marginLeft: 8, cursor: 'help', borderRadius: 10 }}>数据过时</Tag>
                                </Tooltip>
                            )}
                            {engineMeta.pid ? <span style={{ fontSize: 11, color: '#94a3b8', marginLeft: 4 }}>PID {engineMeta.pid}</span> : null}
                            {engineMeta.lastStartedAt && engineStatus === 'running' ? (
                                <span style={{ fontSize: 11, color: '#94a3b8', marginLeft: 8 }} title={engineMeta.lastStartedAt}>
                                    启动于 {new Date(engineMeta.lastStartedAt).toLocaleString('zh-CN', { hour12: false })}
                                    <span style={{ margin: '0 4px' }}>·</span>
                                    已运行 <RunDuration startTime={engineMeta.lastStartedAt} />
                                </span>
                            ) : null}
                        </>
                    ) : (
                        <Badge status="default" text="无权限" />
                    )}
                </div>
                <Space>
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
