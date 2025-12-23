import React, { useState } from 'react';
import { Modal, Form, Input, message } from 'antd';
import { changePassword } from '../api/user';

interface ChangePasswordModalProps {
    visible: boolean;
    onCancel: () => void;
    onSuccess: () => void;
}

const ChangePasswordModal: React.FC<ChangePasswordModalProps> = ({ visible, onCancel, onSuccess }) => {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            if (values.newPassword !== values.confirmPassword) {
                form.setFields([
                    {
                        name: 'confirmPassword',
                        errors: ['两次输入的密码不一致']
                    }
                ]);
                return;
            }

            setLoading(true);
            await changePassword({
                oldPassword: values.oldPassword,
                newPassword: values.newPassword
            });
            message.success('密码修改成功，请重新登录');
            form.resetFields();
            onSuccess();
        } catch (error: any) {
            message.error(error.message || '修改失败');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Modal
            title="修改密码"
            open={visible}
            onOk={handleSubmit}
            onCancel={() => {
                form.resetFields();
                onCancel();
            }}
            confirmLoading={loading}
            okText="确认修改"
            cancelText="取消"
        >
            <Form form={form} layout="vertical">
                <Form.Item
                    name="oldPassword"
                    label="原密码"
                    rules={[{ required: true, message: '请输入原密码' }]}
                >
                    <Input.Password placeholder="请输入原密码" />
                </Form.Item>
                <Form.Item
                    name="newPassword"
                    label="新密码"
                    rules={[
                        { required: true, message: '请输入新密码' },
                        { min: 6, message: '密码长度至少6位' }
                    ]}
                >
                    <Input.Password placeholder="请输入新密码" />
                </Form.Item>
                <Form.Item
                    name="confirmPassword"
                    label="确认新密码"
                    rules={[{ required: true, message: '请再次输入新密码' }]}
                >
                    <Input.Password placeholder="请再次输入新密码" />
                </Form.Item>
            </Form>
        </Modal>
    );
};

export default ChangePasswordModal;
