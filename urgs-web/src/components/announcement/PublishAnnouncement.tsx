import React, { useState, useEffect } from 'react';
import { Card, Form, Input, Select, Button, message, Space, Upload, Tooltip, Divider } from 'antd';
import { Save, RotateCcw, Megaphone, Upload as UploadIcon, Eye, Settings, FileText, ChevronRight, Layout } from 'lucide-react';
import type { UploadFile } from 'antd/es/upload/interface';
import '@wangeditor/editor/dist/css/style.css';
import { Editor, Toolbar } from '@wangeditor/editor-for-react';
import { IDomEditor, IEditorConfig, IToolbarConfig } from '@wangeditor/editor';

interface PublishAnnouncementProps {
    editId?: string | null;
    onSuccess?: () => void;
}

const PublishAnnouncement: React.FC<PublishAnnouncementProps> = ({ editId, onSuccess }) => {
    const [editor, setEditor] = useState<IDomEditor | null>(null);
    const [html, setHtml] = useState('');
    const [fileList, setFileList] = useState<UploadFile[]>([]);
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [userSystems, setUserSystems] = useState<string[]>([]);
    const [activeSection, setActiveSection] = useState<'edit' | 'preview'>('edit');

    // 获取当前表单值用于预览
    const [previewData, setPreviewData] = useState<any>({});

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

    useEffect(() => {
        if (editId) {
            setLoading(true);
            const token = localStorage.getItem('auth_token');
            fetch(`/api/announcement/${editId}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            })
                .then(res => res.json())
                .then(data => {
                    let systems = [];
                    try {
                        systems = typeof data.systems === 'string' ? JSON.parse(data.systems) : data.systems;
                    } catch (e) { }

                    const formData = {
                        title: data.title,
                        type: data.type,
                        category: data.category,
                        systems: systems
                    };
                    form.setFieldsValue(formData);
                    setPreviewData(formData);
                    setHtml(data.content);

                    if (data.attachments) {
                        try {
                            const atts = typeof data.attachments === 'string' ? JSON.parse(data.attachments) : data.attachments;
                            setFileList(atts.map((a: any) => ({
                                uid: a.url,
                                name: a.name,
                                status: 'done',
                                url: a.url
                            })));
                        } catch (e) { }
                    }
                })
                .catch(err => {
                    message.error('获取详情失败');
                })
                .finally(() => setLoading(false));
        } else {
            handleReset();
        }
    }, [editId, form]);

    const toolbarConfig: Partial<IToolbarConfig> = {};
    const editorConfig: Partial<IEditorConfig> = {
        placeholder: '在此输入公告详细内容，支持图文混排...',
    };

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
            const userStr = localStorage.getItem('auth_user');
            let userId = 'admin';
            if (userStr) {
                const user = JSON.parse(userStr);
                userId = user.empId || 'admin';
            }

            const token = localStorage.getItem('auth_token');
            const url = editId ? '/api/announcement/update' : '/api/announcement/publish';

            const payload = { ...values, content: html, attachments };
            const response = await fetch(url, {
                method: editId ? 'PUT' : 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                    'X-User-Id': encodeURIComponent(userId)
                },
                body: JSON.stringify(editId ? { ...payload, id: editId } : payload)
            });

            if (response.ok) {
                message.success(editId ? '保存成功！' : '公告发布成功！');
                if (onSuccess) onSuccess();
            } else {
                throw new Error();
            }
        } catch (error) {
            message.error(editId ? '保存失败' : '发布失败，请重试');
        } finally {
            setLoading(false);
        }
    };

    const handleReset = () => {
        form.resetFields();
        setFileList([]);
        editor?.clear();
        setHtml('');
        setPreviewData({});
    };

    return (
        <div className="max-w-[1400px] mx-auto">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">

                {/* 左侧编辑器 */}
                <div className="lg:col-span-8 space-y-6">
                    <Card variant="borderless" className="shadow-sm border border-slate-100 rounded-3xl overflow-hidden">
                        <div className="flex items-center gap-2 mb-6 text-slate-400 text-xs font-bold uppercase tracking-widest px-1">
                            <FileText size={14} className="text-violet-500" />
                            <span>公告内容编辑</span>
                        </div>

                        <Form
                            form={form}
                            layout="vertical"
                            onFinish={onFinish}
                            initialValues={{ type: 'normal', category: 'Announcement' }}
                            onValuesChange={(_, all) => setPreviewData(all)}
                        >
                            <Form.Item
                                name="title"
                                label={<span className="text-slate-700 font-semibold">公告标题</span>}
                                rules={[{ required: true, message: '请输入公告标题' }]}
                            >
                                <Input
                                    placeholder="起一个吸引人的标题..."
                                    size="large"
                                    className="border-slate-200 rounded-xl hover:border-violet-400 focus:border-violet-500 focus:ring-4 focus:ring-violet-500/10 h-12 text-lg font-bold"
                                />
                            </Form.Item>

                            <Form.Item
                                label={<span className="text-slate-700 font-semibold">正文内容</span>}
                                required
                            >
                                <div className="border border-slate-200 rounded-2xl overflow-hidden focus-within:border-violet-500 focus-within:ring-4 focus-within:ring-violet-500/10 transition-all">
                                    <Toolbar
                                        editor={editor}
                                        defaultConfig={toolbarConfig}
                                        mode="default"
                                        style={{ borderBottom: '1px solid #f1f5f9' }}
                                        className="bg-slate-50/50"
                                    />
                                    <Editor
                                        defaultConfig={editorConfig}
                                        value={html}
                                        onCreated={setEditor}
                                        onChange={editor => setHtml(editor.getHtml())}
                                        mode="default"
                                        style={{ height: '450px', overflowY: 'hidden' }}
                                    />
                                </div>
                            </Form.Item>
                        </Form>
                    </Card>

                    <Card variant="borderless" className="shadow-sm border border-slate-100 rounded-3xl">
                        <div className="flex items-center gap-2 mb-6 text-slate-400 text-xs font-bold uppercase tracking-widest">
                            <UploadIcon size={14} className="text-violet-500" />
                            <span>相关附件</span>
                        </div>
                        <Upload
                            action="/api/common/upload"
                            fileList={fileList}
                            onChange={({ fileList }) => setFileList(fileList)}
                            name="file"
                            className="bg-slate-50 p-4 rounded-2xl border-2 border-dashed border-slate-200 hover:border-violet-400 transition-colors block text-center"
                            headers={{
                                Authorization: `Bearer ${typeof localStorage !== 'undefined' ? localStorage.getItem('auth_token') : ''}`
                            }}
                        >
                            <div className="py-4">
                                <div className="w-12 h-12 bg-white rounded-xl shadow-sm flex items-center justify-center mx-auto mb-3">
                                    <UploadIcon className="text-violet-500" size={24} />
                                </div>
                                <p className="text-slate-600 font-medium">点击或将文件拖拽到此处上传</p>
                                <p className="text-slate-400 text-xs mt-1">支持PDF, DOC, ZIP等常用业务文件</p>
                            </div>
                        </Upload>
                    </Card>
                </div>

                {/* 右侧设置与预览 */}
                <div className="lg:col-span-4 space-y-6 lg:sticky lg:top-4">
                    {/* 设置面板 */}
                    <Card variant="borderless" className="shadow-lg border border-slate-100 rounded-3xl">
                        <div className="flex items-center gap-2 mb-6 text-slate-400 text-xs font-bold uppercase tracking-widest px-1">
                            <Settings size={14} className="text-violet-500" />
                            <span>发布设置</span>
                        </div>

                        <div className="space-y-4">
                            <div>
                                <label className="text-xs font-bold text-slate-500 mb-1.5 block">公告类型</label>
                                <Select
                                    className="w-full"
                                    size="large"
                                    value={previewData.type}
                                    onChange={v => { form.setFieldsValue({ type: v }); setPreviewData({ ...previewData, type: v }); }}
                                >
                                    <Select.Option value="normal">一般公告</Select.Option>
                                    <Select.Option value="urgent">紧急通知</Select.Option>
                                    <Select.Option value="update">系统更新</Select.Option>
                                    <Select.Option value="regulatory">监管发文</Select.Option>
                                </Select>
                            </div>

                            <div>
                                <label className="text-xs font-bold text-slate-500 mb-1.5 block">所属分类</label>
                                <Select
                                    className="w-full"
                                    size="large"
                                    value={previewData.category}
                                    onChange={v => { form.setFieldsValue({ category: v }); setPreviewData({ ...previewData, category: v }); }}
                                >
                                    <Select.Option value="Announcement">通知公告</Select.Option>
                                    <Select.Option value="Log">更新日志</Select.Option>
                                </Select>
                            </div>

                            <div>
                                <label className="text-xs font-bold text-slate-500 mb-1.5 block">可见系统范围</label>
                                <Select
                                    mode="multiple"
                                    placeholder="请选择所属系统"
                                    size="large"
                                    className="w-full"
                                    allowClear
                                    value={previewData.systems}
                                    onChange={v => { form.setFieldsValue({ systems: v }); setPreviewData({ ...previewData, systems: v }); }}
                                >
                                    {userSystems.map(sys => (
                                        <Select.Option key={sys} value={sys}>{sys}</Select.Option>
                                    ))}
                                </Select>
                            </div>

                            <Divider className="my-6 border-slate-100" />

                            <div className="flex gap-3">
                                <Button
                                    type="primary"
                                    onClick={() => form.submit()}
                                    icon={<Save size={18} />}
                                    loading={loading}
                                    block
                                    size="large"
                                    className="bg-violet-600 hover:bg-violet-700 h-12 rounded-xl font-bold shadow-lg shadow-violet-200"
                                >
                                    {editId ? '保存修改' : '确认发布'}
                                </Button>
                                <Button
                                    icon={<RotateCcw size={18} />}
                                    onClick={handleReset}
                                    size="large"
                                    className="h-12 rounded-xl border-slate-200 text-slate-500"
                                >
                                    重置
                                </Button>
                            </div>
                        </div>
                    </Card>

                    {/* 实时预览卡片 */}
                    <div className="hidden lg:block relative group">
                        <div className="absolute -inset-1 bg-gradient-to-r from-violet-500 to-indigo-500 rounded-[2rem] blur opacity-10 group-hover:opacity-20 transition duration-1000"></div>
                        <Card variant="borderless" className="relative shadow-xl border border-slate-100 rounded-[2rem] overflow-hidden bg-white/80 backdrop-blur-xl">
                            <div className="flex items-center justify-between mb-4">
                                <div className="flex items-center gap-2">
                                    <div className="w-2 h-2 rounded-full bg-violet-500" />
                                    <span className="text-[10px] font-black text-violet-500 uppercase tracking-widest">LIVE PREVIEW</span>
                                </div>
                                <Eye size={14} className="text-slate-300" />
                            </div>

                            <h4 className="text-lg font-bold text-slate-800 mb-3 leading-tight min-h-[3rem]">
                                {previewData.title || '这里将显示公告标题'}
                            </h4>
                            <div className="flex items-center gap-2 mb-4">
                                <span className={`text-[10px] font-bold px-2 py-0.5 rounded-lg border uppercase ${previewData.type === 'urgent' ? 'bg-red-50 text-red-600 border-red-100' :
                                        previewData.type === 'update' ? 'bg-amber-50 text-amber-600 border-amber-100' :
                                            'bg-blue-50 text-blue-600 border-blue-100'
                                    }`}>
                                    {previewData.type || 'normal'}
                                </span>
                                <span className="text-[10px] text-slate-400 font-medium">Just now</span>
                            </div>

                            <div
                                className="text-slate-400 text-xs line-clamp-3 leading-relaxed opacity-60 prose prose-sm overflow-hidden"
                                dangerouslySetInnerHTML={{ __html: html || '在此处编写的正文内容将实时显示在预览区域。' }}
                            />

                            <div className="mt-4 pt-4 border-t border-slate-50 flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <div className="w-6 h-6 rounded-full bg-slate-100" />
                                    <div className="h-2 w-12 bg-slate-100 rounded" />
                                </div>
                                <ChevronRight size={16} className="text-slate-200" />
                            </div>
                        </Card>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default PublishAnnouncement;
