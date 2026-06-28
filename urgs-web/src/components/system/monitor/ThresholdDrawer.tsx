import React, { useEffect, useMemo, useState } from 'react';
import { Button, Checkbox, Drawer, Form, InputNumber, Spin, Switch, message } from 'antd';
import type { MonitorTargetType, ServerMetricKey, ThresholdConfig } from '@/api/systemMonitor';
import { getThresholds, updateThresholds } from '@/api/systemMonitor';

interface ThresholdDrawerProps {
    open: boolean;
    targetType: MonitorTargetType;
    targetId?: number;
    targetName?: string;
    onClose: () => void;
    onSaved: () => void;
}

type ThresholdField = readonly [key: string, label: string, unit: string, metric?: ServerMetricKey];

const serverMetricOptions: Array<{ label: string; value: ServerMetricKey }> = [
    { label: 'CPU', value: 'CPU' },
    { label: '内存', value: 'MEMORY' },
    { label: '磁盘', value: 'DISK' },
    { label: '负载', value: 'LOAD' },
    { label: '网络速率', value: 'NETWORK' },
    { label: '运行时间', value: 'UPTIME' },
];

const allServerMetricKeys = serverMetricOptions.map(item => item.value);

const serverFields: readonly ThresholdField[] = [
    ['cpuWarning', 'CPU 预警', '%', 'CPU'], ['cpuCritical', 'CPU 严重', '%', 'CPU'],
    ['memoryWarning', '内存预警', '%', 'MEMORY'], ['memoryCritical', '内存严重', '%', 'MEMORY'],
    ['diskWarning', '磁盘预警', '%', 'DISK'], ['diskCritical', '磁盘严重', '%', 'DISK'],
] as const;

const databaseFields: readonly ThresholdField[] = [
    ['connectionWarning', '连接率预警', '%'], ['connectionCritical', '连接率严重', '%'],
    ['latencyWarning', '延迟预警', 'ms'], ['latencyCritical', '延迟严重', 'ms'],
    ['slowSqlWarning', '慢SQL预警', 'ms'], ['slowSqlCritical', '慢SQL严重', 'ms'],
    ['lockWaitWarning', '锁等待预警', '个'], ['lockWaitCritical', '锁等待严重', '个'],
] as const;

const ThresholdDrawer: React.FC<ThresholdDrawerProps> = ({
    open, targetType, targetId, targetName, onClose, onSaved,
}) => {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const watchedMetrics = Form.useWatch('enabledMetrics', form) as ServerMetricKey[] | undefined;
    const selectedServerMetrics = watchedMetrics ?? allServerMetricKeys;
    const fields = useMemo<readonly ThresholdField[]>(
        () => targetType === 'SERVER' ? serverFields : databaseFields,
        [targetType],
    );

    useEffect(() => {
        if (!open) return;
        form.resetFields();
        setLoading(true);
        getThresholds(targetType, targetId)
            .then(config => form.setFieldsValue({
                enabled: config.enabled,
                enabledMetrics: targetType === 'SERVER'
                    ? (config.enabledMetrics?.length ? config.enabledMetrics : allServerMetricKeys)
                    : undefined,
                ...config.thresholds,
            }))
            .catch(() => message.error('阈值配置加载失败'))
            .finally(() => setLoading(false));
    }, [form, open, targetId, targetType]);

    const handleSave = async () => {
        const values = await form.validateFields();
        const thresholds = Object.fromEntries(fields.map(([key]) => [key, Number(values[key])]));
        const payload: ThresholdConfig = {
            targetType,
            targetId: targetId ?? 0,
            enabled: values.enabled !== false,
            thresholds,
            enabledMetrics: targetType === 'SERVER' ? values.enabledMetrics : undefined,
        };
        setSaving(true);
        try {
            await updateThresholds(payload);
            message.success('阈值配置已保存');
            onSaved();
            onClose();
        } catch {
            message.error('阈值配置保存失败');
        } finally {
            setSaving(false);
        }
    };

    return (
        <Drawer
            open={open}
            width={460}
            title={targetId ? `${targetName || '目标'} · 阈值覆盖` : `${targetType === 'SERVER' ? '服务器' : 'MySQL'}全局阈值`}
            onClose={onClose}
            extra={<Button type="primary" loading={saving} disabled={loading} onClick={handleSave}>保存</Button>}
        >
            <Spin spinning={loading}>
                <Form form={form} layout="vertical">
                    <Form.Item name="enabled" label="启用监控" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                    {targetType === 'SERVER' && (
                        <Form.Item
                            name="enabledMetrics"
                            label="监控内容"
                            rules={[{
                                validator: (_, value?: ServerMetricKey[]) => value?.length
                                    ? Promise.resolve()
                                    : Promise.reject(new Error('请至少选择一个监控项')),
                            }]}
                        >
                            <Checkbox.Group options={serverMetricOptions} />
                        </Form.Item>
                    )}
                    <div className="grid grid-cols-2 gap-x-4">
                        {fields.map(([key, label, unit, metric]) => {
                            const metricEnabled = targetType !== 'SERVER'
                                || !metric
                                || selectedServerMetrics.includes(metric);
                            return (
                                <Form.Item
                                    key={key}
                                    name={key}
                                    label={label}
                                    rules={[{ required: true, message: `请输入${label}` }]}
                                >
                                    <InputNumber
                                        min={0}
                                        precision={0}
                                        className="w-full"
                                        addonAfter={unit}
                                        disabled={!metricEnabled}
                                    />
                                </Form.Item>
                            );
                        })}
                    </div>
                    {targetType === 'SERVER' && (
                        <div className="mb-3 rounded-lg border border-slate-100 bg-slate-50 p-3 text-xs leading-5 text-slate-500">
                            未勾选的 CPU、内存、磁盘不会参与健康判级；负载、网络速率和运行时间仅控制展示与趋势。
                        </div>
                    )}
                    {targetId && (
                        <div className="rounded-lg border border-blue-100 bg-blue-50 p-3 text-xs leading-5 text-blue-700">
                            保存后该目标使用当前配置；未填写对象覆盖时使用全局默认阈值。
                        </div>
                    )}
                </Form>
            </Spin>
        </Drawer>
    );
};

export default ThresholdDrawer;
