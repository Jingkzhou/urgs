import { useState } from 'react';
import { MarkerType } from 'reactflow';
import { get } from '../../../../utils/request';

export const useTaskDependencies = () => {
    const [dependencyGraph, setDependencyGraph] = useState<{ visible: boolean, nodes: any[], edges: any[] }>({ visible: false, nodes: [], edges: [] });

    const handleShowDependencies = async (task: any, type: 'upstream' | 'downstream', referenceInstance?: any) => {
        try {
            // Fetch all tasks and workflows to ensure we have complete data for resolution
            const [taskRes, workflowData] = await Promise.all([
                get<any>('/api/task/list?size=10000'),
                get<any[]>('/api/workflow/list')
            ]);

            let allTasks: any[] = [];

            // 1. Add tasks from sys_task
            const taskList = Array.isArray(taskRes) ? taskRes : (taskRes?.records || []);
            if (taskList) {
                allTasks = taskList.map((t: any) => ({
                    id: t.id,
                    name: t.name,
                    ...JSON.parse(t.content || '{}')
                }));
            }

            // 2. Add tasks from workflows (if not already present)
            if (workflowData) {
                workflowData.forEach((w: any) => {
                    if (w.content) {
                        try {
                            const content = JSON.parse(w.content);
                            if (content.nodes && Array.isArray(content.nodes)) {
                                content.nodes.forEach((node: any) => {
                                    // Check if task already exists (by ID)
                                    const exists = allTasks.some(t => String(t.id) === String(node.id) || String(t.id) === String(node.data?.id));
                                    if (!exists) {
                                        allTasks.push({
                                            id: node.data?.id || node.id, // Prefer data.id (UUID) if available
                                            name: node.data?.label || node.data?.name || node.id,
                                            type: node.data?.taskType || node.type || 'SHELL',
                                            ...node.data
                                        });
                                    }
                                });
                            }
                        } catch (e) {
                            console.error('Failed to parse workflow content during dependency resolution', e);
                        }
                    }
                });
            }

            // Helper to find task by ID
            const findTask = (id: any) => allTasks.find(t => String(t.id) === String(id));

            // Helper to resolve real source task (skipping DEPENDENT nodes)
            const resolveRealSource = (startTask: any, visitedChain = new Set<string>()): any => {
                if (!startTask) return null;
                if (visitedChain.has(startTask.id)) return null; // Cycle in dependent chain
                visitedChain.add(startTask.id);

                if ((startTask.type === 'DEPENDENT' || startTask.taskType === 'DEPENDENT') && startTask.taskId) {
                    const nextTask = findTask(startTask.taskId);
                    return resolveRealSource(nextTask, visitedChain);
                }
                return startTask;
            };

            let nodes: any[] = [];
            let edges: any[] = [];

            if (type === 'upstream') {
                // Build Graph for Upstream
                const visited = new Set<string>();
                const queue = [task];
                visited.add(task.id);

                while (queue.length > 0) {
                    const current = queue.shift();
                    if (!current) continue;

                    // Add Node
                    nodes.push({
                        id: current.id,
                        data: { label: current.name, taskType: current.type || current.taskType, ...current },
                        position: { x: 0, y: 0 },
                        type: 'taskNode'
                    });

                    // 1. Process Normal Upstream Dependencies
                    const currentDepIds = current.dependentTasks || [];
                    currentDepIds.forEach((depId: string) => {
                        const depTask = findTask(depId);

                        if (!depTask) {
                            console.warn(`Dependency task not found: ${depId}`);
                            // Add missing node visual
                            const missingId = `missing-${depId}`;
                            if (!nodes.some(n => n.id === missingId)) {
                                nodes.push({
                                    id: missingId,
                                    data: { label: `Missing: ${depId.substring(0, 8)}...`, taskType: 'UNKNOWN' },
                                    position: { x: 0, y: 0 },
                                    type: 'default',
                                    style: { background: '#fee2e2', border: '1px solid #ef4444', color: '#b91c1c' }
                                });
                            }
                            // Add edge from missing node
                            edges.push({
                                id: `e${missingId}-${current.id}`,
                                source: missingId,
                                target: current.id,
                                type: 'smoothstep',
                                animated: true,
                                style: { stroke: '#ef4444', strokeDasharray: '5,5' }
                            });
                            return;
                        }

                        const realSource = resolveRealSource(depTask);

                        if (realSource) {
                            // Add Edge: RealSource -> Current
                            // Use dashed line if we skipped nodes (i.e. realSource != depTask)
                            const isIndirect = realSource.id !== depId;

                            edges.push({
                                id: `e${realSource.id}-${current.id}`,
                                source: realSource.id,
                                target: current.id,
                                type: 'smoothstep',
                                animated: true,
                                markerEnd: { type: MarkerType.ArrowClosed },
                                style: {
                                    stroke: isIndirect ? '#f59e0b' : '#94a3b8',
                                    strokeDasharray: isIndirect ? '5,5' : undefined
                                }
                            });

                            if (!visited.has(realSource.id)) {
                                visited.add(realSource.id);
                                queue.push(realSource);
                            }
                        }
                    });

                    // 2. Process DEPENDENT type (Implicit Upstream)
                    if ((current.type === 'DEPENDENT' || current.taskType === 'DEPENDENT') && current.taskId) {
                        const targetTask = findTask(current.taskId);
                        const realSource = resolveRealSource(targetTask);

                        if (realSource) {
                            // Add Edge: RealSource -> Current
                            edges.push({
                                id: `e${realSource.id}-${current.id}`,
                                source: realSource.id,
                                target: current.id,
                                type: 'smoothstep',
                                animated: true,
                                markerEnd: { type: MarkerType.ArrowClosed },
                                style: { stroke: '#f59e0b', strokeDasharray: '5,5' }
                            });

                            if (!visited.has(realSource.id)) {
                                visited.add(realSource.id);
                                queue.push(realSource);
                            }
                        }
                    }
                }

            } else {
                // Build Graph for Downstream
                const visited = new Set<string>();
                const queue = [task];
                visited.add(task.id);

                // Helper to resolve real target task (skipping DEPENDENT nodes that act as proxies)
                // If a task is DEPENDENT, it points to a real task. 
                // In downstream view, if we have Current -> DepNode(points to Real), effectively Current -> Real.
                const resolveRealTarget = (startTask: any, visitedChain = new Set<string>()): any => {
                    if (!startTask) return null;
                    if (visitedChain.has(startTask.id)) return null;
                    visitedChain.add(startTask.id);

                    if ((startTask.type === 'DEPENDENT' || startTask.taskType === 'DEPENDENT') && startTask.taskId) {
                        const nextTask = findTask(startTask.taskId);
                        return resolveRealTarget(nextTask, visitedChain);
                    }
                    return startTask;
                };

                while (queue.length > 0) {
                    const current = queue.shift();
                    if (!current) continue;

                    // Add Node
                    nodes.push({
                        id: current.id,
                        data: { label: current.name, taskType: current.type || current.taskType, ...current },
                        position: { x: 0, y: 0 },
                        type: 'taskNode'
                    });

                    // 1. Find Local Dependents (tasks that have current.id in their dependentTasks)
                    const localDependents = allTasks.filter(t => (t.dependentTasks || []).includes(current.id));

                    localDependents.forEach(dep => {
                        const realTarget = resolveRealTarget(dep);

                        if (realTarget) {
                            const isIndirect = realTarget.id !== dep.id;
                            // Add Edge: Current -> RealTarget
                            edges.push({
                                id: `e${current.id}-${realTarget.id}`,
                                source: current.id,
                                target: realTarget.id,
                                type: 'smoothstep',
                                animated: true,
                                markerEnd: { type: MarkerType.ArrowClosed },
                                style: {
                                    stroke: isIndirect ? '#f59e0b' : '#94a3b8',
                                    strokeDasharray: isIndirect ? '5,5' : undefined
                                }
                            });

                            if (!visited.has(realTarget.id)) {
                                visited.add(realTarget.id);
                                queue.push(realTarget);
                            }
                        }
                    });

                    // 2. Find Remote Proxies (DEPENDENT tasks that point to current)
                    // These are tasks in other workflows that represent 'current'.
                    // We want to find what depends on THEM.
                    const remoteProxies = allTasks.filter(t =>
                        (t.type === 'DEPENDENT' || t.taskType === 'DEPENDENT') && t.taskId === current.id
                    );

                    remoteProxies.forEach(proxy => {
                        // Find tasks that depend on the proxy
                        const proxyDependents = allTasks.filter(t => (t.dependentTasks || []).includes(proxy.id));

                        proxyDependents.forEach(pDep => {
                            const realTarget = resolveRealTarget(pDep);

                            if (realTarget) {
                                // Add Edge: Current -> RealTarget (Dashed, as it jumps via proxy)
                                edges.push({
                                    id: `e${current.id}-${realTarget.id}`,
                                    source: current.id,
                                    target: realTarget.id,
                                    type: 'smoothstep',
                                    animated: true,
                                    markerEnd: { type: MarkerType.ArrowClosed },
                                    style: { stroke: '#f59e0b', strokeDasharray: '5,5' }
                                });

                                if (!visited.has(realTarget.id)) {
                                    visited.add(realTarget.id);
                                    queue.push(realTarget);
                                }
                            }
                        });
                    });
                }
            }

            // 3. Inject Status if referenceInstance is provided
            if (referenceInstance && nodes.length > 0) {
                try {
                    const nodeIds = nodes.map(n => String(n.id));
                    // Fetch instances for the specific data date
                    const instances = await get<any[]>('/api/task/instance/list', {
                        dataDate: referenceInstance.dataDate
                    });

                    if (instances) {
                        const instanceMap = new Map<string, any>();
                        instances.forEach(inst => {
                            const taskIdStr = String(inst.taskId);
                            if (nodeIds.includes(taskIdStr) && !instanceMap.has(taskIdStr)) {
                                instanceMap.set(taskIdStr, inst);
                            }
                        });

                        // Update nodes with status and instanceId
                        nodes.forEach(node => {
                            const nodeIdStr = String(node.id);
                            if (instanceMap.has(nodeIdStr)) {
                                const inst = instanceMap.get(nodeIdStr);
                                node.data = {
                                    ...node.data,
                                    status: inst.status,
                                    instanceId: inst.id, // Store real instance ID
                                    startTime: inst.startTime,
                                    endTime: inst.endTime
                                };
                            } else {
                                // If no instance found for this date, it might be WAITING or not scheduled
                                node.data = { ...node.data, status: 'WAITING' };
                            }
                        });
                    }
                } catch (e) {
                    console.error('Failed to fetch instance status for dependency graph', e);
                }
            }

            setDependencyGraph({ visible: true, nodes, edges });
        } catch (error) {
            console.error('Failed to resolve dependencies:', error);
        }
    };

    return {
        dependencyGraph,
        setDependencyGraph,
        handleShowDependencies
    };
};
