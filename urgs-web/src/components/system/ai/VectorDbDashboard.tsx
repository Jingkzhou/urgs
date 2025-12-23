import React, { useState, useEffect } from 'react';
import { Table, Card, Tag, Space, Button, message, Layout, Menu, Empty, Spin } from 'antd';
import { DatabaseOutlined, TableOutlined, ReloadOutlined } from '@ant-design/icons';
import { get } from '../../../utils/request';

const { Sider, Content } = Layout;

interface CollectionInfo {
    name: string;
    metadata?: any;
}

interface VectorDoc {
    id: string;
    content: string;
    metadata: any;
}

interface Props {
    initialCollection?: string | null;
}

const VectorDbDashboard: React.FC<Props> = ({ initialCollection }) => {
    const [collections, setCollections] = useState<CollectionInfo[]>([]);
    const [selectedCollection, setSelectedCollection] = useState<string | null>(null);
    const [docs, setDocs] = useState<VectorDoc[]>([]);
    const [loading, setLoading] = useState(false);
    const [docLoading, setDocLoading] = useState(false);
    const [totalCount, setTotalCount] = useState(0);

    const fetchCollections = async () => {
        setLoading(true);
        try {
            const data = await get<CollectionInfo[]>('/api/ai/rag/collections');
            setCollections(data || []);
            if (data && data.length > 0 && !selectedCollection) {
                setSelectedCollection(data[0].name);
            }
        } catch (e) {
            message.error('获取集合列表失败');
        } finally {
            setLoading(false);
        }
    };

    const fetchDocs = async (name: string) => {
        setDocLoading(true);
        try {
            const data = await get<any>(`/api/ai/rag/collections/${name}/peek`, { limit: '50' });
            if (data) {
                setDocs(data.results || []);
                setTotalCount(data.total_count || 0);
            }
        } catch (e) {
            message.error('获取文档详情失败');
        } finally {
            setDocLoading(false);
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
        }
    }, [selectedCollection]);

    const columns = [
        {
            title: 'ID',
            dataIndex: 'id',
            key: 'id',
            width: 200,
            render: (id: string) => <code className="text-xs bg-slate-100 p-1 rounded font-mono">{id}</code>
        },
        {
            title: '内容预览 (Document Content)',
            dataIndex: 'content',
            key: 'content',
            ellipsis: true,
            render: (content: string) => (
                <div className="max-h-24 overflow-y-auto text-sm leading-relaxed text-slate-700">
                    {content}
                </div>
            )
        },
        {
            title: '元数据 (Metadata)',
            dataIndex: 'metadata',
            key: 'metadata',
            width: 300,
            render: (metadata: any) => (
                <div className="flex flex-wrap gap-1">
                    {Object.entries(metadata || {}).map(([key, value]) => (
                        <Tag key={key} className="m-0 text-[10px]" color="blue">
                            <span className="opacity-60">{key}:</span> {String(value)}
                        </Tag>
                    ))}
                    {(!metadata || Object.keys(metadata).length === 0) && <span className="text-slate-300">-</span>}
                </div>
            )
        }
    ];

    return (
        <div className="h-full flex flex-col bg-white">
            <div className="px-6 py-3 border-b flex justify-between items-center shrink-0">
                <div className="flex items-center gap-2">
                    <DatabaseOutlined className="text-blue-500" />
                    <span className="font-bold text-slate-700">集合管理与预览</span>
                    <span className="text-xs text-slate-400 font-normal ml-2">浏览 ChromaDB 中的底层向量数据</span>
                </div>
                <Button
                    icon={<ReloadOutlined />}
                    size="small"
                    onClick={() => {
                        fetchCollections();
                        if (selectedCollection) fetchDocs(selectedCollection);
                    }}
                    loading={loading || docLoading}
                >
                    刷新
                </Button>
            </div>

            <Layout className="bg-white flex-1 overflow-hidden">
                <Sider width={280} className="bg-slate-50 border-r border-slate-100 overflow-y-auto">
                    <div className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">
                        Collections ({collections.length})
                    </div>
                    {loading ? (
                        <div className="p-10 text-center"><Spin size="small" /></div>
                    ) : (
                        <Menu
                            mode="inline"
                            selectedKeys={[selectedCollection || '']}
                            onClick={(e) => setSelectedCollection(e.key)}
                            className="bg-transparent border-none"
                            items={collections.map(c => ({
                                key: c.name,
                                icon: <TableOutlined />,
                                label: (
                                    <div className="flex justify-between items-center w-full pr-2">
                                        <span className="truncate">{c.name}</span>
                                    </div>
                                )
                            }))}
                        />
                    )}
                </Sider>
                <Content className="bg-white flex flex-col">
                    {selectedCollection ? (
                        <div className="flex flex-col h-full">
                            <div className="p-4 border-b bg-white flex justify-between items-center">
                                <div className="flex items-center gap-3">
                                    <span className="text-slate-400 font-medium">PREVIEW:</span>
                                    <Tag color="blue" className="px-3 py-0.5 rounded-full font-bold ml-1">{selectedCollection}</Tag>
                                    <span className="text-xs text-slate-400">Total: {totalCount} records</span>
                                </div>
                                <div className="text-xs text-slate-400 italic">Showing top 50 results</div>
                            </div>
                            <div className="flex-1 overflow-auto">
                                <Table
                                    columns={columns}
                                    dataSource={docs}
                                    rowKey="id"
                                    pagination={false}
                                    loading={docLoading}
                                    size="small"
                                    sticky
                                    className="px-4"
                                />
                            </div>
                        </div>
                    ) : (
                        <div className="flex items-center justify-center h-full">
                            <Empty description="请选择一个集合进行预览" />
                        </div>
                    )}
                </Content>
            </Layout>
        </div>
    );
};

export default VectorDbDashboard;
