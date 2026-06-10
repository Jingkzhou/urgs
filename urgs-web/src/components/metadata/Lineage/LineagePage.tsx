import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Layout, Input, Button, Drawer, message, Empty, Tag, Pagination, Tooltip } from 'antd';
import {
    SearchOutlined,
    TableOutlined,
    LeftOutlined,
    RightOutlined,
    DownOutlined,
    DownloadOutlined,
    UserOutlined,
    FullscreenOutlined,
    FullscreenExitOutlined,
} from '@ant-design/icons';
import {
    searchTables,
    exportLineage,
    LineageSearchOwnerGroup,
    LineageSearchTableItem,
    LineageGraphDirection,
} from '@/api/lineage';
import LineageGraphContent from './analysis/components/LineageGraphContent';
import LineagePageActionBar, { LineageDirectionOption, LineageViewMode } from './analysis/components/LineagePageActionBar';
import { useLineageEngineController } from './analysis/hooks/useLineageEngineController';
import { useLineageGraphLoader } from './analysis/hooks/useLineageGraphLoader';
import type { LineageDisplayMode } from './analysis/utils/endToEndLineage';
import { hasPermission } from '@/utils/permission';
import AICodeReport from '@/components/version/AICodeReport';

const { Content } = Layout;

interface LineagePageProps {
    mode?: 'trace' | 'impact';
}

const LineagePage: React.FC<LineagePageProps> = () => {
    const containerRef = useRef<HTMLDivElement>(null);
    const canvasRef = useRef<HTMLElement>(null);
    const lastDirectionRef = useRef<LineageGraphDirection>('downstream');
    const initialLineageTargetLoadedRef = useRef(false);
    const [searchText, setSearchText] = useState('');
    const [searchResults, setSearchResults] = useState<LineageSearchOwnerGroup[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const pageSize = 20;
    const [total, setTotal] = useState(0);
    const [totalOwners, setTotalOwners] = useState(0);
    const [selectedOwnerTotal, setSelectedOwnerTotal] = useState(0);
    const [selectedOwnerName, setSelectedOwnerName] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [expandedTables, setExpandedTables] = useState<Set<string>>(new Set());
    const [searchDrawerOpen, setSearchDrawerOpen] = useState(false);
    const [workspaceMode, setWorkspaceMode] = useState<'catalog' | 'canvas'>('catalog');
    const [canvasMaximized, setCanvasMaximized] = useState(false);
    const [viewMode, setViewMode] = useState<LineageViewMode>('canvas');
    const [displayMode, setDisplayMode] = useState<LineageDisplayMode>('full');
    const [directionOptions, setDirectionOptions] = useState<LineageDirectionOption[]>(['downstream']);
    const [lineageReturnHash, setLineageReturnHash] = useState<string | null>(null);
    const queryDirection = useMemo<LineageGraphDirection>(() => (
        directionOptions.length === 2 ? 'both' : directionOptions[0] || 'both'
    ), [directionOptions]);
    const canExport = true;
    const canOpenAuditBoard = hasPermission('version:ai:audit');
    const engineController = useLineageEngineController();
    const [showAuditBoard, setShowAuditBoard] = useState(false);
    const {
        selectedTable,
        selectedQualifiedName,
        selectedColumnName,
        selectedField,
        nodes,
        links,
        listNodes,
        listLinks,
        graphLoading,
        listLoading,
        listDetailsLoaded,
        handleSelectTable,
        loadListDetails,
    } = useLineageGraphLoader(queryDirection);
    const selectedDisplayName = useMemo(() => {
        if (!selectedQualifiedName) {
            return null;
        }
        return selectedColumnName ? `${selectedQualifiedName}.${selectedColumnName}` : selectedQualifiedName;
    }, [selectedColumnName, selectedQualifiedName]);

    const toggleTableExpand = (qualifiedName: string) => {
        setExpandedTables(prev => {
            const next = new Set(prev);
            if (next.has(qualifiedName)) {
                next.delete(qualifiedName);
            } else {
                next.add(qualifiedName);
            }
            return next;
        });
    };

    useEffect(() => {
        handleSearch();
    }, []);

    useEffect(() => {
        if ((viewMode === 'list' || displayMode !== 'full') && selectedTable && !listDetailsLoaded && !listLoading) {
            loadListDetails();
        }
    }, [displayMode, listDetailsLoaded, listLoading, loadListDetails, selectedTable, viewMode]);

    useEffect(() => {
        if (lastDirectionRef.current === queryDirection) {
            return;
        }
        lastDirectionRef.current = queryDirection;
        if (selectedTable) {
            handleSelectTable(selectedTable, selectedQualifiedName || undefined, selectedColumnName || undefined);
        }
    }, [handleSelectTable, queryDirection, selectedColumnName, selectedQualifiedName, selectedTable]);

    useEffect(() => {
        const handleFullscreenChange = () => {
            setCanvasMaximized(document.fullscreenElement === canvasRef.current);
        };
        document.addEventListener('fullscreenchange', handleFullscreenChange);
        return () => document.removeEventListener('fullscreenchange', handleFullscreenChange);
    }, []);

    const handleDirectionChange = (checkedValues: LineageDirectionOption[]) => {
        const next = checkedValues;
        if (next.length === 0) {
            message.warning('至少选择一个查询方向');
            return;
        }
        setDirectionOptions(next);
    };

    const handleCanvasMaximize = async () => {
        const canvasElement = canvasRef.current;
        if (!canvasElement) {
            return;
        }
        if (canvasMaximized) {
            if (document.fullscreenElement) {
                await document.exitFullscreen();
            } else {
                setCanvasMaximized(false);
            }
            return;
        }
        try {
            await canvasElement.requestFullscreen();
            setCanvasMaximized(true);
        } catch (error) {
            setCanvasMaximized(true);
        }
    };

    const handleGraphTableDoubleClick = useCallback((tableName: string, qualifiedName: string) => {
        setWorkspaceMode('canvas');
        setViewMode('canvas');
        handleSelectTable(tableName, qualifiedName);
    }, [handleSelectTable]);

    const handleGraphFieldDoubleClick = useCallback((tableName: string, qualifiedName: string, columnName: string) => {
        setWorkspaceMode('canvas');
        setViewMode('canvas');
        handleSelectTable(tableName, qualifiedName, columnName);
    }, [handleSelectTable]);

    const handleLineageSelect = useCallback((tableName: string, qualifiedName: string, columnName?: string) => {
        setWorkspaceMode('canvas');
        setViewMode('canvas');
        setSearchDrawerOpen(false);
        handleSelectTable(tableName, qualifiedName, columnName);
    }, [handleSelectTable]);

    useEffect(() => {
        if (initialLineageTargetLoadedRef.current) {
            return;
        }
        const hashQuery = window.location.hash.includes('?') ? window.location.hash.split('?')[1] : '';
        const params = new URLSearchParams(hashQuery);
        const tableName = params.get('lineageTable');
        if (!tableName) {
            initialLineageTargetLoadedRef.current = true;
            return;
        }

        initialLineageTargetLoadedRef.current = true;
        const qualifiedName = params.get('lineageQualifiedName') || tableName;
        const columnName = params.get('lineageColumn') || undefined;
        const returnHash = params.get('lineageReturn') === 'regAsset'
            ? (params.get('lineageReturnHash') || '/metadata?subtab=asset')
            : null;
        const directionParam = params.get('lineageDirection');
        const initialDirection: LineageGraphDirection | undefined = (
            directionParam === 'upstream' || directionParam === 'downstream' || directionParam === 'both'
                ? directionParam
                : undefined
        );

        setWorkspaceMode('canvas');
        setViewMode('canvas');
        setSearchDrawerOpen(false);
        setSearchText(columnName || tableName);
        setLineageReturnHash(returnHash);
        if (initialDirection === 'both') {
            lastDirectionRef.current = 'both';
            setDirectionOptions(['upstream', 'downstream']);
        } else if (initialDirection === 'upstream') {
            lastDirectionRef.current = 'upstream';
            setDirectionOptions(['upstream']);
        } else if (initialDirection === 'downstream') {
            lastDirectionRef.current = 'downstream';
            setDirectionOptions(['downstream']);
        }
        handleSelectTable(tableName, qualifiedName, columnName, initialDirection);
    }, [handleSelectTable]);

    const handleBackFromCanvas = () => {
        if (lineageReturnHash) {
            window.location.hash = lineageReturnHash;
            return;
        }
        setWorkspaceMode('catalog');
    };

    const sortedOwnerGroups = useMemo(() => (
        [...searchResults].sort((a, b) => a.ownerName.localeCompare(b.ownerName))
    ), [searchResults]);

    const selectedOwnerGroup = useMemo(() => (
        sortedOwnerGroups.find(group => group.ownerName === selectedOwnerName) || null
    ), [selectedOwnerName, sortedOwnerGroups]);

    const selectedOwnerTables = useMemo(() => (
        selectedOwnerGroup?.tables?.slice().sort((a, b) => a.tableName.localeCompare(b.tableName)) || []
    ), [selectedOwnerGroup]);

    const handleSearch = async (page: number = 1, ownerName: string | null = selectedOwnerName) => {
        setLoading(true);
        try {
            const res = await searchTables(searchText, page, pageSize, ownerName || undefined);
            if (res && res.groupedList) {
                setSearchResults(res.groupedList);
                setTotal(res.total || 0);
                setTotalOwners(res.totalOwners || 0);
                setSelectedOwnerTotal(res.selectedOwnerTotal || 0);
                setCurrentPage(page);
                setExpandedTables(new Set());
            } else {
                setSearchResults([]);
                setTotal(0);
                setTotalOwners(0);
                setSelectedOwnerTotal(0);
                setExpandedTables(new Set());
                if (searchText.trim()) {
                    message.info('未找到相关表');
                }
            }
        } catch (error: any) {
            message.error(`查询失败: ${error.message || '未知错误'}`);
        } finally {
            setLoading(false);
        }
    };

    const handleKeywordSearch = () => {
        setSelectedOwnerName(null);
        handleSearch(1, null);
    };

    const handleSearchSubmit = () => {
        if (selectedOwnerName) {
            handleSearch(1, selectedOwnerName);
            return;
        }
        handleKeywordSearch();
    };

    const handleOwnerSelect = (ownerName: string) => {
        setSelectedOwnerName(ownerName);
        handleSearch(1, ownerName);
    };

    const handleOwnerBack = () => {
        setSelectedOwnerName(null);
        setSelectedOwnerTotal(0);
        setCurrentPage(1);
        setExpandedTables(new Set());
        handleSearch(1, null);
    };

    const handleExport = async (tableName: string, e: React.MouseEvent, columnName?: string, qualifiedName?: string) => {
        e.stopPropagation();
        if (!canExport) {
            return;
        }
        try {
            message.loading({ content: '正在导出...', key: 'export' });
            const blob = await exportLineage(tableName, columnName, qualifiedName);
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            let filename = `${qualifiedName || tableName}`;
            if (columnName) {
                filename += `_${columnName}`;
            }
            filename += `_血缘导出.xlsx`;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
            message.success({ content: '导出成功', key: 'export' });
        } catch (error) {
            message.error({ content: '导出失败', key: 'export' });
        }
    };

    const renderSearchPanel = (inDrawer = false) => (
        <div className={`lineage-search-panel ${inDrawer ? 'lineage-search-panel-drawer' : ''}`}>
            <div className="lineage-catalog-hero">
                <div className="lineage-catalog-title">
                    <div className="lineage-catalog-icon">
                        <SearchOutlined />
                    </div>
                    <div>
                        <h3>血缘入口</h3>
                        <p>先定位 Schema、表或字段，再进入全屏画布分析上下游关系。</p>
                    </div>
                </div>
                {inDrawer ? (
                    <Button type="text" size="small" onClick={() => setSearchDrawerOpen(false)}>
                        关闭
                    </Button>
                ) : null}
            </div>
            <div className="lineage-catalog-stats">
                <div>
                    <span className="lineage-stat-value">{totalOwners}</span>
                    <span className="lineage-stat-label">Schema</span>
                </div>
                <div>
                    <span className="lineage-stat-value">{total}</span>
                    <span className="lineage-stat-label">表 / 报表</span>
                </div>
                <div>
                    <span className="lineage-stat-value">{selectedOwnerName ? selectedOwnerTotal : total}</span>
                    <span className="lineage-stat-label">{selectedOwnerName ? '当前 Schema' : '可检索对象'}</span>
                </div>
            </div>
            <div className="lineage-search-input-row">
                <Input
                    size="large"
                    placeholder="搜索用户、表名、qualifiedName 或字段名"
                    value={searchText}
                    onChange={e => setSearchText(e.target.value)}
                    onPressEnter={handleSearchSubmit}
                    allowClear
                />
                <Button type="primary" size="large" icon={<SearchOutlined />} onClick={handleSearchSubmit} loading={loading}>
                    查询
                </Button>
            </div>
            <div className="lineage-catalog-layout">
                <aside className="lineage-owner-rail">
                    <div className="lineage-section-label">用户 / Schema</div>
                    <div className="lineage-owner-list">
                        {sortedOwnerGroups.map((group) => (
                            <button
                                key={group.ownerName}
                                type="button"
                                onClick={() => handleOwnerSelect(group.ownerName)}
                                className={`lineage-owner-item ${selectedOwnerName === group.ownerName ? 'lineage-owner-item-active' : ''}`}
                            >
                                <UserOutlined style={{ color: selectedOwnerName === group.ownerName ? '#1677ff' : '#8c8c8c' }} />
                                <span className="lineage-owner-name">{group.ownerName}</span>
                                <Tag color={selectedOwnerName === group.ownerName ? 'blue' : undefined} style={{ margin: 0 }}>{group.tableCount}</Tag>
                                <RightOutlined style={{ color: '#cbd5e1', fontSize: 12 }} />
                            </button>
                        ))}
                    </div>
                    {searchResults.length === 0 && !loading ? (
                        <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无 Schema" />
                    ) : null}
                </aside>
                <main className="lineage-table-pane">
                    {selectedOwnerName ? (
                        <>
                            <div className="lineage-table-pane-header">
                                <div>
                                    <div className="lineage-pane-eyebrow">当前 Schema</div>
                                    <div className="lineage-pane-title">{selectedOwnerName}</div>
                                    <div className="lineage-pane-subtitle">展开表查看字段，点击表或字段进入画布。</div>
                                </div>
                                <div className="lineage-pane-actions">
                                    <Tag color="blue" style={{ margin: 0 }}>{selectedOwnerTotal} 张表</Tag>
                                    <Button type="text" size="small" icon={<LeftOutlined />} onClick={handleOwnerBack}>
                                        全部 Schema
                                    </Button>
                                </div>
                            </div>
                            {selectedOwnerTables.length > 0 ? (
                                <div className="lineage-table-list">
                                    {selectedOwnerTables.map((item: LineageSearchTableItem) => (
                                        <div key={item.qualifiedName} className="lineage-table-item">
                                            <div className="lineage-table-row">
                                                <button
                                                    type="button"
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        toggleTableExpand(item.qualifiedName);
                                                    }}
                                                    className="lineage-expand-button"
                                                    aria-label={expandedTables.has(item.qualifiedName) ? '收起字段' : '展开字段'}
                                                >
                                                    {expandedTables.has(item.qualifiedName)
                                                        ? <DownOutlined style={{ fontSize: 10, color: '#666' }} />
                                                        : <RightOutlined style={{ fontSize: 10, color: '#666' }} />}
                                                </button>
                                                <button
                                                    type="button"
                                                    onClick={() => handleLineageSelect(item.tableName, item.qualifiedName)}
                                                    className="lineage-table-main"
                                                >
                                                    <span className="lineage-table-icon"><TableOutlined /></span>
                                                    <span className="lineage-table-text">
                                                        <span className="lineage-table-name">{item.tableName}</span>
                                                        <span className="lineage-table-qualified">{item.qualifiedName}</span>
                                                    </span>
                                                </button>
                                                <Button type="primary" size="small" onClick={() => handleLineageSelect(item.tableName, item.qualifiedName)}>
                                                    打开画布
                                                </Button>
                                                {canExport ? (
                                                    <Tooltip title="导出血缘 Excel">
                                                        <Button
                                                            type="text"
                                                            size="small"
                                                            icon={<DownloadOutlined />}
                                                            onClick={(e) => handleExport(item.tableName, e, undefined, item.qualifiedName)}
                                                        />
                                                    </Tooltip>
                                                ) : null}
                                            </div>
                                            {expandedTables.has(item.qualifiedName) && item.columns && item.columns.length > 0 && (
                                                <div className="lineage-column-list">
                                                    {item.columns.map((col: string) => (
                                                        <Tag
                                                            key={`${item.qualifiedName}.${col}`}
                                                            onClick={(e) => {
                                                                e.stopPropagation();
                                                                handleLineageSelect(item.tableName, item.qualifiedName, col);
                                                            }}
                                                            className="lineage-column-tag group hover:text-blue-500 hover:border-blue-500"
                                                            style={searchText && col.toLowerCase().includes(searchText.toLowerCase()) ? {
                                                                backgroundColor: '#e6f7ff',
                                                                borderColor: '#1890ff'
                                                            } : undefined}
                                                        >
                                                            <span className="lineage-column-name">{col}</span>
                                                            {canExport ? (
                                                                <Tooltip title="导出字段血缘">
                                                                    <DownloadOutlined
                                                                        className="opacity-0 group-hover:opacity-100 transition-opacity"
                                                                        style={{ fontSize: 10, color: '#666' }}
                                                                        onClick={(e) => handleExport(item.tableName, e, col, item.qualifiedName)}
                                                                    />
                                                                </Tooltip>
                                                            ) : null}
                                                        </Tag>
                                                    ))}
                                                </div>
                                            )}
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <div className="lineage-pane-empty">
                                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="该 Schema 暂无匹配表" />
                                </div>
                            )}
                        </>
                    ) : (
                        <div className="lineage-pane-empty lineage-pane-empty-large">
                            <TableOutlined style={{ fontSize: 34, color: '#1677ff' }} />
                            <div className="lineage-pane-empty-title">选择左侧 Schema 查看表和字段</div>
                            <div className="lineage-pane-empty-desc">字段很多时先展开目标表，再点击字段进入字段级血缘画布。</div>
                        </div>
                    )}
                </main>
            </div>
            <div className="lineage-search-footer">
                <div style={{ color: '#64748b', fontSize: 12 }}>
                    {selectedOwnerName
                        ? `${selectedOwnerName}：${selectedOwnerTotal} 张表`
                        : `共 ${totalOwners} 个用户/Schema，${total} 张表`}
                </div>
                {selectedOwnerName ? (
                    <Pagination
                        simple
                        size="small"
                        current={currentPage}
                        pageSize={pageSize}
                        total={selectedOwnerTotal}
                        onChange={(page) => handleSearch(page, selectedOwnerName)}
                    />
                ) : null}
            </div>
        </div>
    );

    return (
        <div
            ref={containerRef}
            style={{
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                minHeight: 0
            }}
        >
            <style>{`
                .ant-spin-nested-loading, .ant-spin-container {
                    height: 100% !important;
                }
                .lineage-page-toolbar {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    gap: 16px;
                    flex-wrap: wrap;
                }
                .lineage-action-bar {
                    display: flex;
                    align-items: center;
                    gap: 12px;
                    flex-wrap: wrap;
                    justify-content: flex-end;
                }
                .lineage-direction-filter {
                    display: inline-flex;
                    align-items: center;
                    gap: 10px;
                    padding: 5px 12px;
                    border: 1px solid #e5e7eb;
                    border-radius: 8px;
                    background: #f8fafc;
                    box-shadow: inset 0 0 0 1px rgba(255,255,255,0.55);
                    white-space: nowrap;
                }
                .lineage-display-mode-filter {
                    display: inline-flex;
                    align-items: center;
                    gap: 10px;
                    padding: 5px 12px;
                    border: 1px solid #e5e7eb;
                    border-radius: 8px;
                    background: #f8fafc;
                    box-shadow: inset 0 0 0 1px rgba(255,255,255,0.55);
                    white-space: nowrap;
                }
                .lineage-direction-filter .ant-checkbox-group {
                    display: inline-flex;
                    align-items: center;
                    gap: 10px;
                }
                .lineage-direction-filter .ant-checkbox-wrapper {
                    margin-inline-start: 0;
                    color: #1f2937;
                }
                .lineage-entry-content {
                    min-height: 0;
                    overflow: auto;
                    padding: 0;
                    background: #fff;
                }
                .lineage-entry-shell {
                    width: 100%;
                    height: 100%;
                    min-height: 640px;
                    margin: 0;
                    border: 0;
                    border-radius: 0;
                    background: #fff;
                    box-shadow: none;
                    overflow: hidden;
                }
                .lineage-search-panel {
                    height: 100%;
                    min-height: 0;
                    display: flex;
                    flex-direction: column;
                    background: #fff;
                }
                .lineage-catalog-hero {
                    padding: 20px 24px 16px;
                    border-bottom: 1px solid #e8eef7;
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    gap: 16px;
                    background: linear-gradient(180deg, #fbfdff 0%, #fff 100%);
                }
                .lineage-catalog-title {
                    min-width: 0;
                    display: flex;
                    align-items: center;
                    gap: 14px;
                }
                .lineage-catalog-title h3 {
                    margin: 0;
                    color: #111827;
                    font-size: 20px;
                    font-weight: 750;
                }
                .lineage-catalog-title p {
                    margin: 5px 0 0;
                    color: #64748b;
                    font-size: 13px;
                }
                .lineage-catalog-icon {
                    width: 40px;
                    height: 40px;
                    border-radius: 8px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    background: #eff6ff;
                    color: #1677ff;
                    border: 1px solid #dbeafe;
                    flex: 0 0 auto;
                }
                .lineage-catalog-stats {
                    display: grid;
                    grid-template-columns: repeat(3, minmax(0, 1fr));
                    gap: 1px;
                    background: #e8eef7;
                    border-bottom: 1px solid #e8eef7;
                }
                .lineage-catalog-stats > div {
                    padding: 14px 24px;
                    background: #fff;
                    display: flex;
                    align-items: baseline;
                    gap: 8px;
                }
                .lineage-stat-value {
                    color: #0f172a;
                    font-size: 22px;
                    font-weight: 760;
                    line-height: 1;
                    font-variant-numeric: tabular-nums;
                }
                .lineage-stat-label {
                    color: #64748b;
                    font-size: 12px;
                    font-weight: 650;
                }
                .lineage-search-input-row {
                    padding: 16px 24px;
                    display: flex;
                    gap: 8px;
                    border-bottom: 1px solid #e8eef7;
                    background: #fff;
                }
                .lineage-catalog-layout {
                    flex: 1;
                    min-height: 0;
                    display: grid;
                    grid-template-columns: 300px minmax(0, 1fr);
                    background: #f8fafc;
                }
                .lineage-owner-rail {
                    min-height: 0;
                    overflow: auto;
                    padding: 18px 16px;
                    border-right: 1px solid #e8eef7;
                    background: #fbfdff;
                }
                .lineage-table-pane {
                    min-width: 0;
                    min-height: 0;
                    overflow: auto;
                    padding: 18px;
                    background: #fff;
                }
                .lineage-search-footer {
                    padding: 10px 24px;
                    border-top: 1px solid #e8eef7;
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    gap: 12px;
                    min-height: 48px;
                    background: #fff;
                }
                .lineage-section-label {
                    color: #64748b;
                    font-size: 12px;
                    font-weight: 700;
                    margin-bottom: 10px;
                }
                .lineage-owner-list,
                .lineage-table-list {
                    display: flex;
                    flex-direction: column;
                    gap: 8px;
                }
                .lineage-owner-item {
                    width: 100%;
                    padding: 12px 10px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    border-radius: 8px;
                    background: #fff;
                    border: 1px solid #eef2f7;
                    cursor: pointer;
                    text-align: left;
                    transition: border-color 0.2s, background 0.2s, box-shadow 0.2s;
                }
                .lineage-owner-item:hover,
                .lineage-table-item:hover {
                    border-color: #bfdbfe;
                    background: #f8fbff;
                }
                .lineage-owner-item-active {
                    border-color: #91caff;
                    background: #eff6ff;
                    box-shadow: inset 3px 0 0 #1677ff;
                }
                .lineage-owner-name {
                    font-weight: 600;
                    flex: 1;
                    min-width: 0;
                    overflow: hidden;
                    text-overflow: ellipsis;
                    white-space: nowrap;
                }
                .lineage-table-pane-header {
                    padding: 2px 2px 16px;
                    display: flex;
                    align-items: flex-start;
                    justify-content: space-between;
                    gap: 16px;
                    border-bottom: 1px solid #eef2f7;
                    margin-bottom: 12px;
                }
                .lineage-pane-eyebrow {
                    color: #1677ff;
                    font-size: 12px;
                    font-weight: 700;
                }
                .lineage-pane-title {
                    color: #111827;
                    font-size: 22px;
                    font-weight: 780;
                    margin-top: 2px;
                }
                .lineage-pane-subtitle {
                    color: #64748b;
                    font-size: 12px;
                    margin-top: 4px;
                }
                .lineage-pane-actions {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    flex-wrap: wrap;
                    justify-content: flex-end;
                }
                .lineage-pane-empty {
                    min-height: 260px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    flex-direction: column;
                    gap: 8px;
                    color: #64748b;
                }
                .lineage-pane-empty-large {
                    min-height: 420px;
                    border: 1px dashed #cbd5e1;
                    border-radius: 8px;
                    background: #f8fafc;
                }
                .lineage-pane-empty-title {
                    color: #1f2937;
                    font-size: 16px;
                    font-weight: 720;
                }
                .lineage-pane-empty-desc {
                    color: #64748b;
                    font-size: 12px;
                }
                .lineage-table-item {
                    border: 1px solid #eef2f7;
                    border-radius: 8px;
                    background: #fff;
                    transition: border-color 0.2s, background 0.2s, box-shadow 0.2s;
                    box-shadow: 0 1px 2px rgba(15, 23, 42, 0.03);
                }
                .lineage-table-row {
                    padding: 12px 14px;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
                .lineage-expand-button,
                .lineage-table-main {
                    border: 0;
                    background: transparent;
                    cursor: pointer;
                }
                .lineage-expand-button {
                    width: 26px;
                    height: 26px;
                    display: inline-flex;
                    align-items: center;
                    justify-content: center;
                    padding: 0;
                    border-radius: 6px;
                    flex: 0 0 auto;
                }
                .lineage-expand-button:hover {
                    background: #eff6ff;
                }
                .lineage-table-main {
                    flex: 1;
                    min-width: 0;
                    padding: 0;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    text-align: left;
                }
                .lineage-table-main:hover .lineage-table-name {
                    color: #1677ff;
                }
                .lineage-table-text {
                    min-width: 0;
                    display: flex;
                    flex-direction: column;
                    gap: 2px;
                }
                .lineage-table-icon {
                    width: 30px;
                    height: 30px;
                    border-radius: 8px;
                    display: inline-flex;
                    align-items: center;
                    justify-content: center;
                    background: #eff6ff;
                    color: #1677ff;
                    flex: 0 0 auto;
                }
                .lineage-table-name {
                    font-weight: 650;
                    color: #1f2937;
                    overflow-wrap: anywhere;
                }
                .lineage-table-qualified {
                    color: #94a3b8;
                    font-size: 12px;
                    overflow-wrap: anywhere;
                }
                .lineage-column-list {
                    padding: 0 14px 14px 58px;
                    display: flex;
                    flex-wrap: wrap;
                    gap: 8px;
                    border-top: 1px solid #f1f5f9;
                    padding-top: 12px;
                }
                .lineage-column-tag {
                    cursor: pointer;
                    margin: 0;
                    max-width: 100%;
                    display: inline-flex;
                    align-items: center;
                    gap: 6px;
                    min-height: 28px;
                    padding: 3px 8px;
                    border-radius: 6px;
                }
                .lineage-column-name {
                    overflow-wrap: anywhere;
                }
                .lineage-canvas-content {
                    background: #fff;
                    position: relative;
                    min-height: 640px;
                    display: flex;
                    overflow: hidden;
                }
                .lineage-canvas-content:fullscreen {
                    width: 100vw;
                    height: 100vh;
                    min-height: 100vh;
                    background: #fff;
                }
                .lineage-canvas-content-maximized {
                    position: fixed !important;
                    inset: 0;
                    z-index: 1000;
                    width: 100vw;
                    height: 100vh;
                    min-height: 100vh;
                    background: #fff;
                }
                .lineage-canvas-search-button {
                    box-shadow: 0 8px 18px rgba(22, 119, 255, 0.22);
                }
                .lineage-canvas-toolbar-actions {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    flex-wrap: wrap;
                }
                .lineage-canvas-exit-fullscreen {
                    position: absolute;
                    z-index: 20;
                    top: 10px;
                    right: 10px;
                    box-shadow: 0 8px 20px rgba(15, 23, 42, 0.12);
                }
                @media (max-width: 900px) {
                    .lineage-entry-content {
                        padding: 0;
                    }
                    .lineage-entry-shell {
                        height: auto;
                        min-height: 640px;
                    }
                    .lineage-catalog-layout,
                    .lineage-search-panel-drawer .lineage-catalog-layout {
                        grid-template-columns: 1fr;
                    }
                    .lineage-owner-rail {
                        max-height: 220px;
                        border-right: 0;
                        border-bottom: 1px solid #e8eef7;
                    }
                    .lineage-catalog-stats {
                        grid-template-columns: 1fr;
                    }
                }
                .lineage-search-panel-drawer .lineage-catalog-layout {
                    grid-template-columns: 1fr;
                }
                .lineage-search-panel-drawer .lineage-owner-rail {
                    max-height: 260px;
                    border-right: 0;
                    border-bottom: 1px solid #e8eef7;
                }
            `}</style>
            <div className="lineage-page-toolbar" style={{ padding: '12px 16px', borderBottom: '1px solid #f0f0f0', background: '#fff' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <div>
                            <div style={{ fontSize: 14, fontWeight: 600, color: '#1f2937' }}>SQL Lineage</div>
                            <div style={{ fontSize: 12, color: '#8c8c8c' }}>血缘模块</div>
                        </div>
                    {selectedDisplayName && <Tag color="blue">{selectedDisplayName}</Tag>}
                    {workspaceMode === 'canvas' ? (
                        <div className="lineage-canvas-toolbar-actions">
                            <Button
                                icon={<LeftOutlined />}
                                onClick={handleBackFromCanvas}
                            >
                                返回列表
                            </Button>
                            <Button
                                type="primary"
                                icon={<SearchOutlined />}
                                onClick={() => setSearchDrawerOpen(true)}
                                className="lineage-canvas-search-button"
                            >
                                切换表/字段
                            </Button>
                        </div>
                    ) : null}
                </div>
                <LineagePageActionBar
                    viewMode={viewMode}
                    displayMode={displayMode}
                    directionOptions={directionOptions}
                    controller={engineController}
                    canOpenAuditBoard={canOpenAuditBoard}
                    onViewModeChange={setViewMode}
                    onDisplayModeChange={setDisplayMode}
                    onDirectionChange={handleDirectionChange}
                    onOpenAuditBoard={() => setShowAuditBoard(true)}
                />
            </div>
            <Layout style={{ flex: 1, minHeight: 0, background: '#f8fafc' }}>
                {workspaceMode === 'catalog' ? (
                    <Content className="lineage-entry-content">
                        <div className="lineage-entry-shell">
                            {renderSearchPanel(false)}
                        </div>
                    </Content>
                ) : (
                    <Content
                        ref={canvasRef}
                        className={`lineage-canvas-content ${canvasMaximized ? 'lineage-canvas-content-maximized' : ''}`}
                    >
                        {canvasMaximized ? (
                            <Button
                                className="lineage-canvas-exit-fullscreen"
                                icon={<FullscreenExitOutlined />}
                                onClick={handleCanvasMaximize}
                            >
                                退出最大化
                            </Button>
                        ) : null}
                        <LineageGraphContent
                            graphLoading={graphLoading}
                            nodes={nodes}
                            links={links}
                            listLoading={listLoading}
                            listNodes={listNodes}
                            listLinks={listLinks}
                            listDetailsLoaded={listDetailsLoaded}
                            viewMode={viewMode}
                            displayMode={displayMode}
                            selectedTable={selectedTable}
                            selectedField={selectedField}
                            onLoadFieldDetails={loadListDetails}
                            onTableDoubleClick={handleGraphTableDoubleClick}
                            onFieldDoubleClick={handleGraphFieldDoubleClick}
                        />
                    </Content>
                )}
                <Drawer
                    title="血缘列表"
                    open={searchDrawerOpen}
                    onClose={() => setSearchDrawerOpen(false)}
                    placement="left"
                    width={560}
                    destroyOnHidden
                    styles={{ body: { padding: 0, background: '#fff' } }}
                >
                    {renderSearchPanel(true)}
                </Drawer>
                <Drawer
                    title="SQL 血缘事后校验"
                    open={showAuditBoard}
                    onClose={() => setShowAuditBoard(false)}
                    size="92vw"
                    destroyOnHidden
                    styles={{ body: { padding: 16, background: '#f8fafc' } }}
                >
                    <AICodeReport />
                </Drawer>
            </Layout>
        </div>
    );
};

export default LineagePage;
