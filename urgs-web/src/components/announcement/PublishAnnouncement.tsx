import React, { useState, useEffect } from 'react';
import { Card, Form, Input, Select, Button, message, Space, Breadcrumb, Upload } from 'antd';
import { Save, RotateCcw, Megaphone, Home, Upload as UploadIcon } from 'lucide-react';
import type { UploadFile } from 'antd/es/upload/interface';
import '@wangeditor/editor/dist/css/style.css'; // import css
import { Editor, Toolbar } from '@wangeditor/editor-for-react';
import { IDomEditor, IEditorConfig, IToolbarConfig } from '@wangeditor/editor';

const PublishAnnouncement: React.FC = () => {
    const [editor, setEditor] = useState<IDomEditor | null>(null);
    const [html, setHtml] = useState('');
    const [fileList, setFileList] = useState<UploadFile[]>([]);
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [userSystems, setUserSystems] = useState<string[]>([]);

    useEffect(() => {
        const userStr = localStorage.getItem('auth_user');
        if (userStr) {
            try {
                const user = JSON.parse(userStr);
                const systems = user.system ? user.system.split(',') : [];
                setUserSystems(systems);
            } catch (e) {
                console.error("Failed to parse user systems", e);
            }
        }
    }, []);

    // Publish API call
    const publishAPI = async (data: any) => {
        const userStr = localStorage.getItem('auth_user');
        let userId = 'admin';
        if (userStr) {
            const user = JSON.parse(userStr);
            userId = user.empId || 'admin';
        }

        const token = localStorage.getItem('auth_token');
        const response = await fetch('/api/announcement/publish', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`,
                'X-User-Id': encodeURIComponent(userId)
            },
            body: JSON.stringify(data)
        });

        if (!response.ok) {
            throw new Error('Publish failed');
        }
        return await response.json();
    };

    // Editor config
    const toolbarConfig: Partial<IToolbarConfig> = {};
    const editorConfig: Partial<IEditorConfig> = {
        placeholder: '请输入公告详细内容...',
    };

    // Timely destruction of the editor
    useEffect(() => {
        return () => {
            if (editor == null) return;
            editor.destroy();
            setEditor(null);
        };
    }, [editor]);

    const onFinish = async (values: any) => {
        if (!html || html === '<p><br></p>') {
            message.error('请输入公告内容');
            return;
        }

        setLoading(true);
        try {
            const attachments = fileList.map(item => ({
                name: item.name,
                url: item.response?.url || item.url
            }));
            await publishAPI({ ...values, content: html, attachments });
            message.success('公告发布成功！');
            form.resetFields();
            setFileList([]);
            editor?.clear();
            setHtml('');
        } catch (error) {
            message.error('发布失败，请重试');
        } finally {
            setLoading(false);
        }
    };

    const handleReset = () => {
        form.resetFields();
        setFileList([]);
        editor?.clear();
        setHtml('');
    };

    return (
        <div className="space-y-4">
            <Card bordered={false} className="shadow-sm">
                <Form
                    form={form}
                    layout="vertical"
                    onFinish={onFinish}
                    initialValues={{
                        type: 'normal',
                        category: 'Announcement'
                    }}
                >
                    <Form.Item
                        name="title"
                        label="公告标题"
                        rules={[{ required: true, message: '请输入公告标题' }]}
                    >
                        <Input placeholder="请输入公告标题" size="large" />
                    </Form.Item>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <Form.Item
                            name="type"
                            label="公告类型"
                            rules={[{ required: true, message: '请选择公告类型' }]}
                        >
                            <Select size="large">
                                <Select.Option value="normal">一般公告</Select.Option>
                                <Select.Option value="urgent">紧急通知</Select.Option>
                                <Select.Option value="update">系统更新</Select.Option>
                                <Select.Option value="regulatory">监管发文</Select.Option>
                            </Select>
                        </Form.Item>

                        <Form.Item
                            name="category"
                            label="所属分类"
                            rules={[{ required: true, message: '请选择所属分类' }]}
                        >
                            <Select size="large">
                                <Select.Option value="Announcement">通知公告</Select.Option>
                                <Select.Option value="Log">更新日志</Select.Option>
                            </Select>
                        </Form.Item>
                    </div>

                    <Form.Item
                        name="systems"
                        label="所属系统"
                        rules={[{ required: true, message: '请选择所属系统' }]}
                    >
                        <Select
                            mode="multiple"
                            placeholder="请选择所属系统"
                            size="large"
                            allowClear
                        >
                            {userSystems.map(sys => (
                                <Select.Option key={sys} value={sys}>{sys}</Select.Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item
                        label="附件上传"
                        name="attachments"
                        tooltip="支持上传相关文档"
                    >
                        <Upload
                            action="/api/common/upload"
                            fileList={fileList}
                            onChange={({ fileList }) => setFileList(fileList)}
                            name="file"
                            headers={{
                                Authorization: `Bearer ${typeof localStorage !== 'undefined' ? localStorage.getItem('auth_token') : ''}`
                            }}
                        >
                            <Button icon={<UploadIcon size={16} />}>上传附件</Button>
                        </Upload>
                    </Form.Item>

                    <Form.Item
                        label="公告内容"
                        required
                        tooltip="支持富文本编辑"
                    >
                        <div className="border border-slate-200 rounded-lg overflow-hidden z-10 relative">
                            <Toolbar
                                editor={editor}
                                defaultConfig={toolbarConfig}
                                mode="default"
                                style={{ borderBottom: '1px solid #e2e8f0' }}
                            />
                            <Editor
                                defaultConfig={editorConfig}
                                value={html}
                                onCreated={setEditor}
                                onChange={editor => setHtml(editor.getHtml())}
                                mode="default"
                                style={{ height: '400px', overflowY: 'hidden' }}
                            />
                        </div>
                    </Form.Item>

                    <Form.Item>
                        <Space>
                            <Button
                                type="primary"
                                htmlType="submit"
                                icon={<Save size={16} />}
                                loading={loading}
                                size="large"
                                className="bg-red-600 hover:bg-red-500"
                            >
                                发布公告
                            </Button>
                            <Button
                                icon={<RotateCcw size={16} />}
                                onClick={handleReset}
                                size="large"
                            >
                                重置
                            </Button>
                        </Space>
                    </Form.Item>
                </Form>
            </Card>
        </div>
    );
};

export default PublishAnnouncement;
