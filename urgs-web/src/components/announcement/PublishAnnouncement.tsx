import React, { useState, useEffect } from 'react';
import { Card, Form, Input, Select, Button, message, Space, Upload, Tooltip, Divider } from 'antd';
import { Save, RotateCcw, Megaphone, Upload as UploadIcon, Eye, Settings, FileText, ChevronRight, Layout, Sparkles } from 'lucide-react';
import type { UploadFile } from 'antd/es/upload/interface';
import '@wangeditor/editor/dist/css/style.css';
import { Editor, Toolbar } from '@wangeditor/editor-for-react';
import { IDomEditor, IEditorConfig, IToolbarConfig } from '@wangeditor/editor';

interface PublishAnnouncementProps {
    editId?: string | null;
    onSuccess?: (category?: string) => void;
}

const PublishAnnouncement: React.FC<PublishAnnouncementProps> = ({ editId, onSuccess }) => {
    const [editor, setEditor] = useState<IDomEditor | null>(null);
    const [html, setHtml] = useState('');
    const [fileList, setFileList] = useState<UploadFile[]>([]);
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [userSystems, setUserSystems] = useState<string[]>([]);
    const [activeSection, setActiveSection] = useState<'edit' | 'preview'>('edit');
    const [polishing, setPolishing] = useState(false);

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
                if (onSuccess) onSuccess(values.category);
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

    const handleAiPolish = async () => {
        if (!html || html === '<p><br></p>') {
            message.warning('请先输入一些内容再进行润色');
            return;
        }

        setPolishing(true);
        try {
            const category = form.getFieldValue('category');

            let systemPrompt = `你是一个资深的公文写作评审专家。请对用户提供的草稿进行提炼和润色，使其完全符合专业『通知公告发布范式』。
具体要求：
1. 语言风格：必须庄重、严谨、客观、得体，使用标准的书面语规范和官方公文用语（如“鉴于”、“为了”、“兹定于”等）。
2. 结构范式：须包含发文缘由（目的背景）、通知事项（具体内容）、工作要求或总结（呼吁与执行）。
3. 信息降噪：去除口语化词汇、多余的感情色彩及冗余修饰，保证文字精炼准确。
4. 格式输出：必须直接返回润色后的纯 HTML 源码。强制保留原有的 HTML 标签嵌套结构（如 <p>, <b>, <ul>, <li> 等），但可根据结构逻辑适当增加分段和列表标签，严禁输出任何 Markdown 标记或多余的解释性文本。`;

            if (category === 'Log') {
                systemPrompt = `你是一个资深的高级产品经理与技术架构师。请将用户提供的零散信息整理并润色成符合业界标准『软件版本发布报告（Release Notes）格式范式』的技术文本。
具体要求：
1. 语言风格：专业、清晰、精炼，使用准确的技术工程术语，避免口头表达和模糊描述。
2. 结构范式：必须强逻辑性，按重要度将内容聚类划分，通常应涵盖：
   - 🌟 主要特性 (New Features / Highlights)：核心的业务价值与最重要的功能新增。
   - 🚀 性能优化与改进 (Improvements)：已有功能的升级、前端或后端的优化改进。
   - 🐛 问题修复 (Bug Fixes)：解决了哪些关键的体验阻断或安全漏洞。
3. 表述规范：每一个关键点以动词驱动，直击痛点和解决的业务场景。
4. 格式输出：必须直接返回高度排版优化的纯 HTML 源码。请通过 <h3>, <ul>, <li>, <strong> 等标签构建层次分明的视觉结构，严禁输出任何 Markdown 标记或解释性前缀后缀。`;
            }

            const token = localStorage.getItem('auth_token');
            const response = await fetch('/api/ai/chat/completions', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    systemPrompt,
                    userPrompt: html
                })
            });

            if (!response.ok) throw new Error('AI 响应异常');

            const data = await response.json();
            if (data.content) {
                setHtml(data.content);
                message.success('AI 润色完成！');
            } else {
                throw new Error('未获取到润色内容');
            }
        } catch (error) {
            console.error('AI 润色失败:', error);
            message.error('AI 润色失败，请重试');
        } finally {
            setPolishing(false);
        }
    };

    return (
        <div className="max-w-[1400px] mx-auto pb-10">
            <Form
                form={form}
                layout="vertical"
                onFinish={onFinish}
                initialValues={{ type: 'normal', category: 'Announcement', systems: [] }}
                onValuesChange={(_, all) => setPreviewData(all)}
                className="w-full"
            >
                <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">

                    {/* 左侧编辑器 */}
                    <div className="lg:col-span-8 space-y-6">
                        <Card variant="borderless" className="shadow-sm border border-slate-100 rounded-3xl overflow-hidden bg-white/50 backdrop-blur-sm">
                            <div className="flex items-center gap-2 mb-6 text-slate-400 text-xs font-bold uppercase tracking-widest px-1">
                                <FileText size={14} className="text-violet-500" />
                                <span>公告内容编辑</span>
                            </div>

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
                                label={
                                    <div className="flex items-center justify-between w-full">
                                        <span className="text-slate-700 font-semibold">正文内容</span>
                                        <Button
                                            type="text"
                                            size="small"
                                            icon={<Sparkles size={14} className={polishing ? "animate-pulse" : ""} />}
                                            onClick={handleAiPolish}
                                            loading={polishing}
                                            className="text-violet-600 hover:text-violet-700 hover:bg-violet-50 font-bold text-xs flex items-center gap-1"
                                        >
                                            AI 润色
                                        </Button>
                                    </div>
                                }
                                required
                            >
                                <div className="border border-slate-200 rounded-2xl overflow-hidden focus-within:border-violet-500 focus-within:ring-4 focus-within:ring-violet-500/10 transition-all bg-white">
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
                                        style={{ height: '500px', overflowY: 'hidden' }}
                                    />
                                </div>
                            </Form.Item>
                        </Card>

                        <Card variant="borderless" className="shadow-sm border border-slate-100 rounded-3xl bg-white/50 backdrop-blur-sm">
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
                        <Card variant="borderless" className="shadow-lg border border-slate-100 rounded-3xl bg-white">
                            <div className="flex items-center gap-2 mb-6 text-slate-400 text-xs font-bold uppercase tracking-widest px-1">
                                <Settings size={14} className="text-violet-500" />
                                <span>发布设置</span>
                            </div>

                            <div className="space-y-5">
                                <Form.Item
                                    name="type"
                                    label={<span className="text-xs font-bold text-slate-500">公告类型</span>}
                                    className="mb-0"
                                >
                                    <Select className="w-full" size="large">
                                        <Select.Option value="normal">一般公告</Select.Option>
                                        <Select.Option value="urgent">紧急通知</Select.Option>
                                        <Select.Option value="update">系统更新</Select.Option>
                                        <Select.Option value="regulatory">监管发文</Select.Option>
                                    </Select>
                                </Form.Item>

                                <Form.Item
                                    name="category"
                                    label={<span className="text-xs font-bold text-slate-500">所属分类</span>}
                                    className="mb-0"
                                >
                                    <Select className="w-full" size="large">
                                        <Select.Option value="Announcement">通知公告</Select.Option>
                                        <Select.Option value="Log">更新日志</Select.Option>
                                    </Select>
                                </Form.Item>

                                <Form.Item
                                    name="systems"
                                    label={<span className="text-xs font-bold text-slate-500">可见系统范围</span>}
                                    className="mb-0"
                                >
                                    <Select
                                        mode="multiple"
                                        placeholder="请选择所属系统"
                                        size="large"
                                        className="w-full"
                                        allowClear
                                        maxTagCount="responsive"
                                    >
                                        {userSystems.map(sys => (
                                            <Select.Option key={sys} value={sys}>{sys}</Select.Option>
                                        ))}
                                    </Select>
                                </Form.Item>

                                <Divider className="my-6 border-slate-100" />

                                <div className="flex gap-3">
                                    <Button
                                        type="primary"
                                        htmlType="submit"
                                        icon={<Save size={18} />}
                                        loading={loading}
                                        block
                                        size="large"
                                        className="bg-violet-600 hover:bg-violet-700 h-12 rounded-xl font-bold shadow-lg shadow-violet-200 border-none"
                                    >
                                        {editId ? '保存修改' : '确认发布'}
                                    </Button>
                                    <Button
                                        icon={<RotateCcw size={18} />}
                                        onClick={handleReset}
                                        size="large"
                                        className="h-12 rounded-xl border-slate-200 text-slate-500 hover:text-violet-600 hover:border-violet-200"
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
                                    className="text-slate-400 text-xs line-clamp-4 leading-relaxed opacity-60 prose prose-sm overflow-hidden"
                                    dangerouslySetInnerHTML={{ __html: html || '在此处编写的正文内容将实时显示在预览区域。' }}
                                />

                                <div className="mt-4 pt-4 border-t border-slate-100 flex items-center justify-between">
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
            </Form>
        </div>
    );
};

export default PublishAnnouncement;
