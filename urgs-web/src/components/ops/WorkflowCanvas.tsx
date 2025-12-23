import React, { useState, useCallback, useRef, useMemo } from 'react';
import { Modal, Button, message } from 'antd';
import {
    Play, FileText, AlertTriangle, CheckCircle, XCircle, RotateCw,
    Boxes, Code2, Database, Flame, Globe2, HardDrive, Save, Terminal, Settings, ListChecks, Link
} from 'lucide-react';
import ReactFlow, {
    ReactFlowProvider,
    useNodesState,
    useEdgesState,
    addEdge,
    Controls,
    Background,
    Connection,
    Edge,
    MarkerType,
    Node,
    useReactFlow,
    Panel,
    BackgroundVariant,
    Handle,
    Position,
    NodeProps
} from 'reactflow';
import 'reactflow/dist/style.css';
import Auth from '../Auth';
import TaskConfigForm from './schedule/TaskConfigForm';
import dagre from 'dagre';

const nodeWidth = 172;
const nodeHeight = 36;

const getLayoutedElements = (nodes: Node[], edges: Edge[], direction = 'LR') => {
    const dagreGraph = new dagre.graphlib.Graph();
    dagreGraph.setDefaultEdgeLabel(() => ({}));

    const isHorizontal = direction === 'LR';
    dagreGraph.setGraph({ rankdir: direction });

    nodes.forEach((node) => {
        dagreGraph.setNode(node.id, { width: nodeWidth, height: nodeHeight });
    });

    edges.forEach((edge) => {
        dagreGraph.setEdge(edge.source, edge.target);
    });

    dagre.layout(dagreGraph);

    const layoutedNodes = nodes.map((node) => {
        const nodeWithPosition = dagreGraph.node(node.id);

        // Safety check
        if (!nodeWithPosition) {
            return node;
        }

        // Create a new object to avoid mutation
        return {
            ...node,
            targetPosition: isHorizontal ? Position.Left : Position.Top,
            sourcePosition: isHorizontal ? Position.Right : Position.Bottom,
            position: {
                x: nodeWithPosition.x - nodeWidth / 2,
                y: nodeWithPosition.y - nodeHeight / 2,
            }
        };
    });

    return { nodes: layoutedNodes, edges };
};

// ... (inside FlowEditor component)

// ... (inside FlowEditor component)

// --- Mock Data & Constants ---

const MOCK_TASK_STATUS: Record<string, any> = {
    '2': { // Shell Task
        id: '1001', name: 'Rpt_East_Deposit', workflow: 'East_Report_Flow', cron: '0 0 2 * * ?', lastRun: '2024-05-27 02:00:00', nextRun: '2024-05-28 02:00:00', status: 'failure', owner: '张三',
        logs: ['[INFO] Starting task...', '[ERROR] Connection timeout to DB']
    },
    '3': { // End Node (Mocking another task)
        id: '1002', name: 'Rpt_East_Loan', workflow: 'East_Report_Flow', cron: '0 30 2 * * ?', lastRun: '2024-05-27 02:30:00', nextRun: '2024-05-28 02:30:00', status: 'success', owner: '李四'
    }
};

const taskTypes = [
    { label: 'SHELL', icon: Terminal, type: 'taskNode' },
    { label: 'PROCEDURE', icon: Database, type: 'taskNode' },
    { label: 'PYTHON', icon: Code2, type: 'taskNode' },
    { label: 'HTTP', icon: Globe2, type: 'taskNode' },
    { label: 'DataX', icon: HardDrive, type: 'taskNode' },
    { label: 'DEPENDENT', icon: Link, type: 'taskNode' },
];

const initialNodes: Node[] = [
    {
        id: '1',
        type: 'input',
        data: { label: 'Start' },
        position: { x: 250, y: 100 },
        style: { background: '#fff', border: '1px solid #cbd5e1', borderRadius: '8px', width: 120, boxShadow: '0 1px 2px 0 rgb(0 0 0 / 0.05)' }
    },
    {
        id: '2',
        data: { label: 'Rpt_East_Deposit' },
        position: { x: 100, y: 250 },
        style: { background: '#fff', border: '1px solid #ef4444', borderRadius: '8px', width: 160, boxShadow: '0 4px 6px -1px rgb(239 68 68 / 0.1)' } // Red border for failure
    },
    {
        id: '3',
        type: 'output',
        data: { label: 'Rpt_East_Loan' },
        position: { x: 400, y: 250 },
        style: { background: '#fff', border: '1px solid #22c55e', borderRadius: '8px', width: 160, boxShadow: '0 4px 6px -1px rgb(34 197 94 / 0.1)' } // Green for success
    },
];

const initialEdges: Edge[] = [
    { id: 'e1-2', source: '1', target: '2', animated: true, type: 'default', style: { stroke: '#94a3b8' } },
    { id: 'e1-3', source: '1', target: '3', animated: true, type: 'default', style: { stroke: '#94a3b8' } },
];

interface WorkflowDefinitionProps {
    onTurnToIssue?: (task: any) => void;
    initialNodes?: Node[];
    initialEdges?: Edge[];
    onChange?: (nodes: Node[], edges: Edge[]) => void;
    autoLayoutOnMount?: boolean;
    readOnly?: boolean;
    onNodeContextMenu?: (event: React.MouseEvent, node: Node) => void;
    showStatus?: boolean;
}

const TaskNode = ({ data, selected, sourcePosition = Position.Right, targetPosition = Position.Left }: NodeProps) => {
    // Resolve icon from taskTypes based on taskType or label
    const taskType = taskTypes.find(t => t.label === (data.taskType || data.label));
    const Icon = taskType ? taskType.icon : (data.icon || Terminal); // Fallback to data.icon or Terminal

    // Status Styling
    let statusStyle = 'border-slate-300';
    let statusIconColor = 'text-slate-500';
    let statusBg = 'bg-white';

    // Only apply status styling if showStatus is true
    if (data.showStatus) {
        if (data.status === 'SUCCESS') {
            statusStyle = 'border-green-500 ring-1 ring-green-500';
            statusIconColor = 'text-green-600';
            statusBg = 'bg-green-50';
        } else if (data.status === 'FORCE_SUCCESS') {
            statusStyle = 'border-purple-500 ring-1 ring-purple-500';
            statusIconColor = 'text-purple-600';
            statusBg = 'bg-purple-50';
        } else if (data.status === 'FAILURE' || data.status === 'FAIL') {
            statusStyle = 'border-red-500 ring-1 ring-red-500';
            statusIconColor = 'text-red-600';
            statusBg = 'bg-red-50';
        } else if (data.status === 'RUNNING') {
            statusStyle = 'border-blue-500 ring-1 ring-blue-500';
            statusIconColor = 'text-blue-600';
            statusBg = 'bg-blue-50';
        } else if (data.status === 'PENDING') {
            statusStyle = 'border-yellow-500 dashed border-2';
            statusIconColor = 'text-yellow-600';
            statusBg = 'bg-yellow-50';
        } else if (data.status === 'WAITING') {
            statusStyle = 'border-cyan-500 dashed border-2';
            statusIconColor = 'text-cyan-600';
            statusBg = 'bg-cyan-50';
        }
    }

    const STATUS_MAP: Record<string, string> = {
        'WAITING': '等待下发',
        'PENDING': '依赖等待',
        'RUNNING': '运行中',
        'SUCCESS': '成功',
        'FAILURE': '失败',
        'FAIL': '失败',
        'FORCE_SUCCESS': '强制成功',
        'STOPPED': '已停止'
    };

    // Dependent Node Styling
    const isDependent = data.taskType === 'DEPENDENT';
    const isExternal = isDependent; // Alias for clarity

    // Highlight Styling
    let highlightStyle = '';
    if (data.highlight === 'upstream') {
        highlightStyle = 'ring-2 ring-orange-400 border-orange-400 bg-orange-50';
    } else if (data.highlight === 'downstream') {
        highlightStyle = 'ring-2 ring-blue-400 border-blue-400 bg-blue-50';
    }

    // Base Style overrides for Dependent Nodes
    if (isDependent) {
        statusBg = 'bg-slate-50';
        statusStyle = 'border-slate-300 border-dashed';
        if (!data.highlight) {
            // Only apply grey if not highlighted
            statusBg = 'bg-slate-100';
        }
    }

    return (
        <div className={`flex items-center gap-2 px-3 py-2 border rounded-lg shadow-sm min-w-[150px] max-w-[300px] transition-all 
            ${highlightStyle || statusBg} 
            ${selected ? 'border-blue-500 ring-2 ring-blue-500 !bg-white' : statusStyle}
        `}>
            <Handle type="target" position={targetPosition} className="!bg-slate-400 !w-2 !h-2" />

            {data.showStatus && data.status === 'RUNNING' ? (
                <RotateCw size={16} className="text-blue-600 animate-spin min-w-[16px]" />
            ) : (
                Icon && <Icon size={16} className={`${statusIconColor} min-w-[16px]`} />
            )}

            <div className="flex flex-col overflow-hidden">
                <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-slate-700 break-words leading-tight" title={data.label}>{data.label}</span>
                    {isExternal && (
                        <span className="text-[10px] px-1 py-0.5 bg-slate-200 text-slate-600 rounded border border-slate-300 whitespace-nowrap">
                            外部
                        </span>
                    )}
                </div>
                {data.showStatus && data.status && (
                    <span className="text-[10px] uppercase font-bold tracking-wider opacity-70">
                        {STATUS_MAP[data.status] || data.status}
                    </span>
                )}
            </div>
            <Handle type="source" position={sourcePosition} className="!bg-slate-400 !w-2 !h-2" />
        </div>
    );
};





const FlowEditor: React.FC<WorkflowDefinitionProps> = ({ onTurnToIssue, initialNodes: propNodes, initialEdges: propEdges, onChange, autoLayoutOnMount, readOnly, onNodeContextMenu, showStatus = false }) => {
    const reactFlowWrapper = useRef<HTMLDivElement>(null);
    const [nodes, setNodes, onNodesChange] = useNodesState(propNodes || initialNodes);
    const [edges, setEdges, onEdgesChange] = useEdgesState(propEdges || initialEdges);
    const { screenToFlowPosition, fitView } = useReactFlow();
    const [selectedNode, setSelectedNode] = useState<Node | null>(null);
    const [editingNode, setEditingNode] = useState<Node | null>(null);

    const nodeTypes = useMemo(() => ({ taskNode: TaskNode }), []);
    const edgeTypes = useMemo(() => ({}), []);

    // Sync showStatus to nodes
    React.useEffect(() => {
        setNodes((nds) => nds.map(n => ({
            ...n,
            data: { ...n.data, showStatus }
        })));
    }, [showStatus, setNodes]);

    // Notify parent of changes
    React.useEffect(() => {
        if (onChange) {
            onChange(nodes, edges);
        }
    }, [nodes, edges, onChange]);

    // Fit view on mount to center the graph
    React.useEffect(() => {
        if (autoLayoutOnMount) {
            // Small delay to ensure nodes are loaded
            setTimeout(() => {
                onLayout('LR');
            }, 100);
        } else {
            setTimeout(() => {
                fitView({ padding: 0.2, duration: 500 });
            }, 100);
        }
    }, [fitView, autoLayoutOnMount]);

    // State for new node creation
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [pendingNode, setPendingNode] = useState<Node | null>(null);
    const [pendingData, setPendingData] = useState<any>({});

    const onConnect = useCallback(
        (params: Connection) => {
            // 1. Add Edge
            setEdges((eds) => addEdge({
                ...params,
                type: 'default',
                markerEnd: { type: MarkerType.ArrowClosed },
                style: { stroke: '#94a3b8' }
            }, eds));

            // 2. Update Target Node Data (Sync dependency)
            const { source, target } = params;
            if (source && target) {
                setNodes((nds) => {
                    const sourceNode = nds.find((n) => n.id === source);
                    if (!sourceNode) return nds;

                    const sourceId = sourceNode.data.id || sourceNode.id;

                    return nds.map((node) => {
                        if (node.id === target) {
                            // For all tasks, update the internal dependency list (BasicSettings)
                            const currentDeps = node.data.dependentTasks || [];
                            const newDeps = currentDeps.includes(sourceId) ? currentDeps : [...currentDeps, sourceId];

                            return {
                                ...node,
                                data: {
                                    ...node.data,
                                    useDependency: true, // Enable dependency mode
                                    dependentTasks: newDeps, // Add source to dependentTasks

                                    // Keep specific logic for DEPENDENT type if needed, 
                                    // but usually edges imply internal dependency.
                                    // If it was DEPENDENT type specific logic:
                                    ...(node.data.taskType === 'DEPENDENT' ? {
                                        taskId: sourceId // Also set taskId for DependentForm if compatible
                                    } : {})
                                }
                            };
                        }
                        return node;
                    });
                });
            }
        },
        [setEdges, setNodes],
    );

    const onDragStart = (event: React.DragEvent, nodeType: string, label: string) => {
        event.dataTransfer.setData('application/reactflow', nodeType);
        event.dataTransfer.setData('application/reactflow-label', label);
        event.dataTransfer.effectAllowed = 'move';
    };

    const onDragOver = useCallback((event: React.DragEvent) => {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }, []);

    const onDrop = useCallback(
        (event: React.DragEvent) => {
            event.preventDefault();
            const type = event.dataTransfer.getData('application/reactflow');
            const label = event.dataTransfer.getData('application/reactflow-label');

            if (typeof type === 'undefined' || !type) {
                return;
            }

            const position = screenToFlowPosition({
                x: event.clientX,
                y: event.clientY,
            });

            // Find the task configuration to get the icon
            const taskConfig = taskTypes.find(t => t.label === label);
            const Icon = taskConfig?.icon;

            const newNode: Node = {
                id: `${+new Date()}`,
                type,
                position,
                data: {
                    label: label,
                    taskType: label,
                    icon: Icon, // Persist the icon component
                    showStatus: showStatus
                },
                style: { background: '#fff', border: '1px solid #cbd5e1', borderRadius: '8px', width: 150 }
            };

            setPendingNode(newNode);
            setPendingData(newNode.data);
            setIsModalOpen(true);
        },
        [screenToFlowPosition]
    );

    const handleSaveNode = () => {
        if (pendingNode) {
            // Generate UUID for the new node
            const newId = crypto.randomUUID();

            const finalNode = {
                ...pendingNode,
                id: newId,
                data: {
                    ...pendingNode.data,
                    ...pendingData,
                    id: newId, // Store UUID in data
                    taskType: pendingNode.data.taskType || pendingNode.data.label
                }
            };
            setNodes((nds) => nds.concat(finalNode));
            setIsModalOpen(false);
            setPendingNode(null);
            setPendingData({});
            message.success('任务已添加到画布 (ID已生成)');
        }
    };

    const handleCancelNode = () => {
        setIsModalOpen(false);
        setPendingNode(null);
        setPendingData({});
    };

    const onNodeClick = useCallback((event: React.MouseEvent, node: Node) => {
        setSelectedNode(node);
        // Single click only selects, doesn't open edit panel (clears editing state if open)
        setEditingNode(null);

        // 1. Identify Neighbors
        const upstreamNodeIds = new Set<string>();
        const downstreamNodeIds = new Set<string>();

        edges.forEach(edge => {
            if (edge.target === node.id) {
                upstreamNodeIds.add(edge.source);
            }
            if (edge.source === node.id) {
                downstreamNodeIds.add(edge.target);
            }
        });

        // 2. Update Nodes with Highlight Status
        setNodes((nds) => nds.map(n => {
            let highlight = undefined;
            if (upstreamNodeIds.has(n.id)) highlight = 'upstream';
            if (downstreamNodeIds.has(n.id)) highlight = 'downstream';

            // Clear highlight if not related, or set new highlight
            if (n.data.highlight !== highlight) {
                return { ...n, data: { ...n.data, highlight } };
            }
            return n;
        }));

        // 3. Highlight Edges
        setEdges((eds) =>
            eds.map((edge) => {
                const isConnected = edge.source === node.id || edge.target === node.id;
                if (isConnected) {
                    return { ...edge, style: { stroke: '#2563eb', strokeWidth: 2 }, animated: true };
                }
                return { ...edge, style: { stroke: '#94a3b8', strokeWidth: 1 }, animated: false };
            })
        );
    }, [edges, setNodes, setEdges]);

    const onNodeDoubleClick = useCallback((event: React.MouseEvent, node: Node) => {
        setSelectedNode(node);
        setEditingNode(node);
    }, []);

    const onPaneClick = useCallback(() => {
        setSelectedNode(null);
        setEditingNode(null);

        // Clear Highlights
        setNodes((nds) => nds.map(n => {
            if (n.data.highlight) {
                return { ...n, data: { ...n.data, highlight: undefined } };
            }
            return n;
        }));

        setEdges((eds) =>
            eds.map((edge) => ({ ...edge, style: { stroke: '#94a3b8', strokeWidth: 1 }, animated: false }))
        );
    }, [setEdges, setNodes]);

    // Get mock status for selected node
    const nodeStatus = useMemo(() => {
        if (!selectedNode) return null;
        return MOCK_TASK_STATUS[selectedNode.id] || null;
    }, [selectedNode]);

    const onLayout = useCallback(
        (direction: string) => {
            const { nodes: layoutedNodes, edges: layoutedEdges } = getLayoutedElements(
                nodes,
                edges,
                direction
            );

            setNodes([...layoutedNodes]);
            setEdges([...layoutedEdges]);

            // Wait for state update and render to complete before fitting view
            setTimeout(() => {
                fitView({ padding: 0.2, duration: 500 });
            }, 50);
        },
        [nodes, edges, setNodes, setEdges, fitView]
    );

    // Handle node data change from form
    const handleNodeDataChange = (newData: any) => {
        if (!editingNode) return;

        console.log('handleNodeDataChange called', { newData, editingNode });

        // 1. Update Node Data
        setNodes((nds) =>
            nds.map((node) => {
                if (node.id === editingNode.id) {
                    return { ...node, data: { ...node.data, ...newData } };
                }
                return node;
            })
        );
        // Update both selected and editing node states to reflect changes immediately
        const updatedNode = { ...editingNode, data: { ...editingNode.data, ...newData } };
        setEditingNode(updatedNode);
        if (selectedNode?.id === editingNode.id) {
            setSelectedNode(updatedNode);
        }

        // 2. Sync Edges if dependentTasks changed
        const oldDeps = editingNode.data.dependentTasks || [];
        const newDeps = newData.dependentTasks || [];

        // Check if dependencies actually changed
        const isDepsChanged = oldDeps.length !== newDeps.length || !oldDeps.every((d: string) => newDeps.includes(d));

        if (isDepsChanged) {
            const currentTargetId = editingNode.id;

            setEdges((eds) => {
                // Keep edges that don't target this node
                const otherEdges = eds.filter(e => e.target !== currentTargetId);

                // Create new edges for dependencies
                const newEdges = newDeps.map((sourceId: string) => {
                    // sourceId is the Task ID (data.id) or Node ID depending on what was saved.
                    // We need to find the corresponding ReactFlow Node ID.
                    // Use 'nodes' from component scope instead of 'nds'
                    const sourceNode = nodes.find(n => (n.data.id === sourceId) || (n.id === sourceId));

                    if (!sourceNode) {
                        return null;
                    }

                    const actualSourceId = sourceNode.id;

                    // Try to preserve existing edge properties if it existed
                    const existingEdge = eds.find(e => e.source === actualSourceId && e.target === currentTargetId);
                    if (existingEdge) return existingEdge;

                    return {
                        id: `e${actualSourceId}-${currentTargetId}`,
                        source: actualSourceId,
                        target: currentTargetId,
                        type: 'default',
                        markerEnd: { type: MarkerType.ArrowClosed },
                        style: { stroke: '#94a3b8' }
                    };
                }).filter(Boolean) as Edge[];

                return [...otherEdges, ...newEdges];
            });
        }
    };

    return (
        <div className="h-full w-full bg-slate-50 overflow-hidden flex relative animate-fade-in">
            {/* Main Canvas */}
            <div className="flex-1 relative" ref={reactFlowWrapper}>
                {/* Left Floating Palette */}
                {!readOnly && (
                    <div className="absolute left-4 top-4 bottom-4 z-10 flex flex-col gap-4 pointer-events-none">
                        <div className="bg-white/90 backdrop-blur-sm p-2 rounded-xl shadow-lg border border-slate-200 pointer-events-auto w-14 hover:w-48 transition-all duration-300 group overflow-hidden">
                            <div className="flex flex-col gap-2">
                                <div className="p-2 text-slate-400 border-b border-slate-100 mb-1 flex items-center gap-3">
                                    <Boxes size={20} className="min-w-[20px]" />
                                    <span className="text-xs font-bold uppercase tracking-wider opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">Components</span>
                                </div>
                                {taskTypes.map((task, idx) => (
                                    <div
                                        key={idx}
                                        className="flex items-center gap-3 p-2 rounded-lg cursor-move text-slate-600 hover:bg-slate-100 hover:text-blue-600 transition-colors"
                                        draggable
                                        onDragStart={(event) => onDragStart(event, task.type, task.label)}
                                        title={task.label}
                                    >
                                        <task.icon size={20} className="min-w-[20px]" />
                                        <span className="text-sm font-medium opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">{task.label}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                )}

                <ReactFlow
                    nodes={nodes}
                    edges={edges}
                    onNodesChange={onNodesChange}
                    onEdgesChange={onEdgesChange}
                    nodeTypes={nodeTypes}
                    edgeTypes={edgeTypes}
                    onConnect={onConnect}
                    onNodeClick={onNodeClick}
                    onNodeDoubleClick={onNodeDoubleClick}
                    onPaneClick={onPaneClick}
                    onDragOver={onDragOver}
                    onDrop={onDrop}
                    onNodeContextMenu={onNodeContextMenu}
                    fitView
                    attributionPosition="bottom-right"
                    snapToGrid
                    minZoom={0.1}
                    maxZoom={1.5}
                >
                    <Background color="#94a3b8" gap={50} size={1} variant={BackgroundVariant.Dots} />
                    <Controls className="bg-white/90 backdrop-blur-sm border border-slate-200 shadow-sm rounded-lg !m-4">
                        <div className="react-flow__controls-button" onClick={() => onLayout('LR')} title="自动整理布局">
                            <RotateCw size={12} />
                        </div>
                    </Controls>
                </ReactFlow>
            </div>

            {/* Right Context Panel */}
            {!readOnly && (
                <div className={`
                absolute right-0 top-0 bottom-0 w-[600px] bg-white border-l border-slate-200 shadow-xl z-20 
                transform transition-transform duration-300 ease-in-out flex flex-col
                ${editingNode ? 'translate-x-0' : 'translate-x-full'}
            `}>
                    {editingNode && (
                        <>
                            <TaskConfigForm
                                data={editingNode.data}
                                type={editingNode.data.taskType || editingNode.data.label || 'SHELL'} // Use taskType from data
                                onChange={handleNodeDataChange}
                                availableTasks={nodes
                                    .filter(n => n.id !== editingNode.id) // Exclude self
                                    .map(n => ({
                                        label: n.data.label || n.id,
                                        value: n.data.id || n.id // Use backend ID if available
                                    }))
                                }
                            />
                        </>
                    )}
                </div>
            )}


            {/* New Node Configuration Modal */}
            <Modal
                title="新建任务配置"
                open={isModalOpen}
                onOk={handleSaveNode}
                onCancel={handleCancelNode}
                width={800}
                okText="保存并添加"
                cancelText="取消"
                destroyOnHidden
            >
                {pendingNode && (
                    <div className="max-h-[60vh] overflow-y-auto p-1">
                        <TaskConfigForm
                            data={pendingData}
                            type={pendingNode.data.taskType || 'SHELL'}
                            onChange={(newData) => setPendingData(newData)}
                        />
                    </div>
                )}
            </Modal>
        </div >
    );
};

const WorkflowCanvas: React.FC<WorkflowDefinitionProps> = (props) => (
    <ReactFlowProvider>
        <FlowEditor {...props} />
    </ReactFlowProvider>
);

export default WorkflowCanvas;
