import React, { useState, useEffect } from 'react';
import { Card, Tag, Space, Button, message, Layout, Input, Drawer, Empty, Spin, Progress, Tooltip, Badge, Typography } from 'antd';
import {
    DatabaseOutlined,
    ReloadOutlined,
    SearchOutlined,
    FileTextOutlined,
    ThunderboltOutlined,
    ExperimentOutlined,
    RobotOutlined,
    ReadOutlined
} from '@ant-design/icons';
import { get, post } from '../../../utils/request';

const { Sider, Content } = Layout;
const { Search, TextArea } = Input;
const { Paragraph, Text, Title } = Typography;

interface CollectionInfo {
    name: string;
    metadata?: any;
}

interface VectorDoc {
    id: string;
    content: string;
    metadata: any;
}

interface RagQueryResult {
    page_content: string;
    metadata: any;
    score?: number; // Similarity score if available
}

interface Props {
    initialCollection?: string | null;
}

const VectorDbDashboard: React.FC<Props> = ({ initialCollection }) => {
    // Data States
    const [collections, setCollections] = useState<CollectionInfo[]>([]);
    const [selectedCollection, setSelectedCollection] = useState<string | null>(null);
    const [docs, setDocs] = useState<VectorDoc[]>([]);
    const [totalCount, setTotalCount] = useState(0);

    // UI States
    const [loading, setLoading] = useState(false);
    const [docLoading, setDocLoading] = useState(false);
    const [selectedFile, setSelectedFile] = useState<string | null>(null);
    const [detailDoc, setDetailDoc] = useState<VectorDoc | null>(null);
    const [drawerOpen, setDrawerOpen] = useState(false);

    // Query States
    const [queryText, setQueryText] = useState('');
    const [queryResults, setQueryResults] = useState<any[]>([]);
    const [queryLoading, setQueryLoading] = useState(false);
    const [showQueryPanel, setShowQueryPanel] = useState(true);

    const fetchCollections = async () => {
        console.log('[RAG-Dashboard] 正在获取集合列表...');
        setLoading(true);
        try {
            const data = await get<CollectionInfo[]>('/api/ai/rag/collections');
            console.log('[RAG-Dashboard] 成功获取集合:', data);
            setCollections(data || []);
            if (data && data.length > 0 && !selectedCollection && !initialCollection) {
                setSelectedCollection(data[0].name);
            }
        } catch (e) {
            console.error('[RAG-Dashboard] 获取集合列表失败:', e);
            message.error('获取集合列表失败');
        } finally {
            setLoading(false);
        }
    };

    const fetchDocs = async (name: string) => {
        console.log(`[RAG-Dashboard] 正在加载详情: ${name}`);
        setDocLoading(true);
        try {
            // 1. First try the base name
            let data = await get<any>(`/api/ai/rag/collections/${name}/peek`, { limit: '100' });
            console.log(`[RAG-Dashboard] [1] 基础查询结果:`, data);

            // 2. If base is empty and it's a standard KB name (doesn't end with RAG suffix), try _semantic
            const isSuffix = name.endsWith('_semantic') || name.endsWith('_logic') || name.endsWith('_summary');
            if ((!data || !data.results || data.results.length === 0) && !isSuffix) {
                const semanticName = `${name}_semantic`;
                console.log(`[RAG-Dashboard] [2] 基础集合为空，尝试探测全息路径: ${semanticName}`);
                const semanticData = await get<any>(`/api/ai/rag/collections/${semanticName}/peek`, { limit: '100' });
                if (semanticData && semanticData.results && semanticData.results.length > 0) {
                    console.log(`[RAG-Dashboard] [3] 在全息路径命中数据:`, semanticData);
                    data = semanticData;
                }
            }

            if (data) {
                let parsedDocs: VectorDoc[] = [];
                let total = 0;

                // Case 1: Standard Wrapper Result
                if (Array.isArray(data.results)) {
                    parsedDocs = data.results;
                    total = data.total_count || data.results.length;
                }
                // Case 2: Raw Chroma Result (Columnar)
                else if (Array.isArray(data.ids) && Array.isArray(data.documents)) {
                    console.log('[RAG-Dashboard] 检测到 Raw Chroma 格式数据，执行前端适配...');
                    parsedDocs = data.ids.map((id: string, index: number) => ({
                        id: id,
                        content: data.documents[index] || '',
                        metadata: data.metadatas ? data.metadatas[index] : {}
                    }));
                    total = data.total_count || parsedDocs.length;
                }

                console.log(`[RAG-Dashboard] 数据适配完成, 渲染分片数量: ${parsedDocs.length}`);
                setDocs(parsedDocs);
                setTotalCount(total);
            }
        } catch (e) {
            console.error('[RAG-Dashboard] 获取文档详情失败:', e);
            message.error('获取文档详情失败');
        } finally {
            setDocLoading(false);
        }
    };

    const handleQuery = async () => {
        if (!queryText.trim() || !selectedCollection) return;

        console.log(`[RAG-Dashboard] 发起检索测试. 集合: ${selectedCollection}, 问题: "${queryText}"`);
        setQueryLoading(true);
        try {
            const res = await post<any>('/api/ai/rag/query', {
                query: queryText,
                collection_names: [selectedCollection],
                k: 4
            });

            if (res && res.results) {
                console.log(`[RAG-Dashboard] 检索测试返回结果 (${res.results.length}):`, res.results);
                setQueryResults(res.results);
            } else {
                console.warn('[RAG-Dashboard] 检索测试未命中任何结果');
                setQueryResults([]);
            }
        } catch (e) {
            console.error('[RAG-Dashboard] 检索测试异常:', e);
            message.error('检索失败');
        } finally {
            setQueryLoading(false);
        }
    };

    useEffect(() => {
        fetchCollections();
    }, []);

    useEffect(() => {
        if (initialCollection) {
            setSelectedCollection(initialCollection);
        }
    }, [initialCollection]);

    useEffect(() => {
        if (selectedCollection) {
            fetchDocs(selectedCollection);
            // Reset states when collection changes
            setSelectedFile(null);
            setQueryResults([]);
            setQueryText('');
        }
    }, [selectedCollection]);

    // Derived states
    const uniqueFiles = Array.from(new Set(docs.map(d => d.metadata?.file_name).filter(Boolean))) as string[];

    const filteredDocs = selectedFile
        ? docs.filter(d => d.metadata?.file_name === selectedFile)
        : docs;

    const renderMetadataTags = (metadata: any) => {
        if (!metadata) return null;
        return (
            <div className="flex flex-wrap gap-1 mt-2">
                {Object.entries(metadata).map(([key, value]) => {
                    // Skip long values for card view
                    const strVal = String(value);
                    if (strVal.length > 30) return null;

                    let color = 'default';
                    if (key === 'file_name') color = 'blue';
                    if (key === 'page') color = 'cyan';
                    if (key === 'source') color = 'purple';

                    return (
                        <Tag key={key} color={color} className="text-[10px] m-0 px-1 py-0 h-5 leading-5 border-none bg-opacity-10">
                            {key}: {strVal}
                        </Tag>
                    );
                })}
            </div>
        );
    };

    return (
        <div className="h-full flex flex-col bg-slate-50">
            {/* Header Toolbar */}
            <div className="px-6 py-3 bg-white border-b flex justify-between items-center shrink-0 shadow-sm z-10">
                <div className="flex items-center gap-4">
                    <div className="flex items-center gap-2">
                        <DatabaseOutlined className="text-blue-600 text-lg" />
                        <div>
                            <div className="font-bold text-slate-800 leading-tight">
                                {selectedCollection || '选择集合'}
                            </div>
                            <div className="text-[10px] text-slate-400">
                                Total: {totalCount} chunks | Displaying: {docs.length}
                            </div>
                        </div>
                    </div>

                    {uniqueFiles.length > 0 && (
                        <div className="h-6 w-px bg-slate-200 mx-2" />
                    )}

                    {uniqueFiles.length > 0 && (
                        <div className="flex gap-1 overflow-x-auto max-w-[600px] no-scrollbar py-1">
                            <Tag.CheckableTag
                                checked={selectedFile === null}
                                onChange={() => setSelectedFile(null)}
                                className={selectedFile === null ? "bg-slate-800 text-white" : ""}
                            >
                                全部文件
                            </Tag.CheckableTag>
                            {uniqueFiles.map(file => (
                                <Tag.CheckableTag
                                    key={file}
                                    checked={selectedFile === file}
                                    onChange={(checked) => setSelectedFile(checked ? file : null)}
                                    className={selectedFile === file ? "bg-blue-600 text-white border-transparent" : "bg-white border-slate-200"}
                                >
                                    <FileTextOutlined className="mr-1" />{file}
                                </Tag.CheckableTag>
                            ))}
                        </div>
                    )}
                </div>

                <Space>
                    {/* Toggle Query Panel Button */}
                    <Button
                        type={showQueryPanel ? "primary" : "default"}
                        ghost={showQueryPanel}
                        icon={<ExperimentOutlined />}
                        onClick={() => setShowQueryPanel(!showQueryPanel)}
                    >
                        实验面板
                    </Button>
                    <Button
                        icon={<ReloadOutlined />}
                        onClick={() => {
                            if (selectedCollection) fetchDocs(selectedCollection);
                        }}
                        loading={loading || docLoading}
                    >
                        刷新数据
                    </Button>
                </Space>
            </div>

            <Layout className="flex-1 overflow-hidden bg-slate-50">
                {/* Main Content: Chunk Grid */}
                <Content className="flex-1 overflow-y-auto p-6">
                    {docLoading ? (
                        <div className="flex justify-center items-center h-full">
                            <Spin tip="加载向量数据..." size="large" />
                        </div>
                    ) : filteredDocs.length === 0 ? (
                        <div className="flex justify-center items-center h-full">
                            <Empty description={selectedFile ? "该文件没有切片数据" : "暂无切片数据"} />
                        </div>
                    ) : (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3 2xl:grid-cols-4 gap-4">
                            {filteredDocs.map((doc, idx) => (
                                <Card
                                    key={doc.id || idx}
                                    hoverable
                                    variant="borderless"
                                    className="shadow-sm hover:shadow-md transition-all duration-200 border border-slate-200 flex flex-col h-[280px]"
                                    styles={{ body: { padding: '16px', height: '100%', display: 'flex', flexDirection: 'column' } }}
                                    onClick={() => {
                                        setDetailDoc(doc);
                                        setDrawerOpen(true);
                                    }}
                                >
                                    {/* Card Header: File & ID */}
                                    <div className="flex justify-between items-start mb-2">
                                        <div className="flex items-center gap-1 min-w-0">
                                            <FileTextOutlined className="text-slate-400 shrink-0" />
                                            <span className="text-xs font-medium text-slate-600 truncate max-w-[150px]" title={doc.metadata?.file_name}>
                                                {doc.metadata?.file_name || 'Unknown Source'}
                                            </span>
                                        </div>
                                        <div className="text-[10px] text-slate-300 font-mono bg-slate-50 px-1 rounded shrink-0">
                                            #{doc.id?.substring(0, 8)}
                                        </div>
                                    </div>

                                    {/* Card Content: Preview */}
                                    <div className="flex-1 overflow-hidden relative mb-2 group">
                                        <div className="text-sm text-slate-700 leading-relaxed font-mono whitespace-pre-wrap break-words h-full overflow-hidden mask-image-b">
                                            {doc.content}
                                        </div>
                                        {/* Hover Gradient Overlay */}
                                        <div className="absolute inset-0 bg-gradient-to-t from-white via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end justify-center pb-2">
                                            <span className="text-xs text-blue-500 font-medium bg-blue-50 px-2 py-1 rounded-full">点击查看详情</span>
                                        </div>
                                    </div>

                                    {/* Card Footer: Metadata */}
                                    <div className="mt-auto pt-2 border-t border-slate-50">
                                        {renderMetadataTags(doc.metadata)}
                                    </div>
                                </Card>
                            ))}
                        </div>
                    )}
                </Content>

                {/* Right Panel: Q&A Testing */}
                {showQueryPanel && (
                    <Sider
                        width={400}
                        className="bg-white border-l border-slate-200 shadow-xl z-20"
                        theme="light"
                    >
                        <div className="h-full flex flex-col">
                            <div className="p-4 border-b bg-slate-50">
                                <h4 className="font-bold text-slate-700 flex items-center gap-2 mb-3">
                                    <RobotOutlined className="text-purple-600" /> 检索测试实验室
                                </h4>
                                <Search
                                    placeholder="输入问题测试检索效果..."
                                    allowClear
                                    enterButton={
                                        <Button type="primary" icon={<ThunderboltOutlined />}>
                                            检索
                                        </Button>
                                    }
                                    size="middle"
                                    value={queryText}
                                    onChange={e => setQueryText(e.target.value)}
                                    onSearch={handleQuery}
                                    loading={queryLoading}
                                />
                                <div className="mt-2 text-[10px] text-slate-400 flex justify-between">
                                    <span>Top K: 4</span>
                                    <span>Model: Text-Embedding-3</span>
                                </div>
                            </div>

                            <div className="flex-1 overflow-y-auto p-4 bg-slate-50/50">
                                {queryLoading ? (
                                    <div className="py-10 text-center text-slate-400">
                                        <Spin />
                                        <div className="mt-2 text-xs">正在计算向量相似度...</div>
                                    </div>
                                ) : queryResults.length > 0 ? (
                                    <div className="space-y-4">
                                        <div className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">
                                            检索结果 ({queryResults.length})
                                        </div>
                                        {queryResults.map((result, idx) => (
                                            <Card
                                                key={idx}
                                                size="small"
                                                variant="borderless"
                                                className="shadow-sm border border-purple-100 bg-white"
                                            >
                                                <div className="flex justify-between items-center mb-2">
                                                    <Tag color="purple">Rank {idx + 1}</Tag>
                                                    {result.score !== undefined && (
                                                        <span className="text-xs font-mono text-slate-500">
                                                            Score: {(result.score * 100).toFixed(1)}%
                                                        </span>
                                                    )}
                                                </div>
                                                <div className="text-xs text-slate-600 line-clamp-4 leading-relaxed font-mono bg-slate-50 p-2 rounded mb-2 border border-slate-100">
                                                    {result.snippet || result.page_content}
                                                </div>
                                                <div className="flex flex-wrap gap-1">
                                                    <Tag className="text-[10px] m-0 bg-transparent border-slate-200 text-slate-500">
                                                        {result.metadata?.file_name}
                                                    </Tag>
                                                    {result.metadata?.page !== undefined && (
                                                        <Tag className="text-[10px] m-0 bg-transparent border-slate-200 text-slate-500">
                                                            P.{result.metadata.page}
                                                        </Tag>
                                                    )}
                                                </div>
                                            </Card>
                                        ))}
                                    </div>
                                ) : (
                                    <Empty
                                        image={Empty.PRESENTED_IMAGE_SIMPLE}
                                        description="输入问题开始测试检索命中情况"
                                        className="mt-10 opacity-60"
                                    />
                                )}
                            </div>
                        </div>
                    </Sider>
                )}
            </Layout>

            {/* Chunk Detail Drawer */}
            <Drawer
                title={
                    <div className="flex items-center gap-2">
                        <ReadOutlined className="text-blue-500" />
                        <span>切片详情</span>
                        <Tag className="ml-2 font-mono font-normal bg-slate-100 border-none text-slate-500">
                            {detailDoc?.id}
                        </Tag>
                    </div>
                }
                placement="right"
                width={600}
                onClose={() => setDrawerOpen(false)}
                open={drawerOpen}
            >
                {detailDoc && (
                    <div className="flex flex-col gap-6">
                        {/* Metadata Section */}
                        <div className="bg-slate-50 p-4 rounded-lg border border-slate-100">
                            <h5 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-3">元数据信息</h5>
                            <div className="grid grid-cols-2 gap-4">
                                {Object.entries(detailDoc.metadata || {}).map(([key, value]) => (
                                    <div key={key}>
                                        <div className="text-[10px] text-slate-400 mb-0.5">{key}</div>
                                        <div className="text-sm font-medium text-slate-700 break-all">
                                            {String(value)}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Content Section */}
                        <div>
                            <h5 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-3 flex justify-between items-center">
                                <span>切片内容</span>
                                <Button
                                    size="small"
                                    type="text"
                                    className="text-blue-500 text-xs"
                                    icon={<SearchOutlined />}
                                    onClick={() => {
                                        setQueryText(detailDoc.content.substring(0, 50));
                                        setShowQueryPanel(true);
                                    }}
                                >
                                    以此内容测试检索
                                </Button>
                            </h5>
                            <div className="p-4 bg-slate-900 text-slate-200 rounded-lg font-mono text-sm leading-loose whitespace-pre-wrap shadow-inner border border-slate-700">
                                {detailDoc.content}
                            </div>
                        </div>
                    </div>
                )}
            </Drawer>
        </div>
    );
};

export default VectorDbDashboard;
