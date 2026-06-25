import { useEffect, useMemo, useState } from 'react';
import { queryQuartzTaskStatus } from '@/api/ops';
import { QuartzTask, QuartzTaskStatus } from '../mockData';
import { blockingStatusRank, incompleteInstanceStatuses } from './constants';
import {
    BlockingDependencyItem,
    DependencyInsightData,
    DependencyRelationItem,
    DependencyRelationType,
    DownstreamImpactMeta,
    RerunImpactItem,
} from './types';
import { getAllDependIds, getControlDependIds, getDataDependIds, normalizeStatus } from './utils';

const DEPENDENCY_DATE_INSTANCE_PAGE_SIZE = 500;
const MAX_DEPENDENCY_DATE_INSTANCE_PAGES = 8;
const MAX_DEPENDENCY_GRAPH_NODES = 800;

interface UseDependencyInsightDataParams {
    selectedInstance: QuartzTaskStatus | null;
    taskList: QuartzTask[];
    instanceList: QuartzTaskStatus[];
    taskMap: Map<number, QuartzTask>;
    enabled?: boolean;
    includeImpact?: boolean;
}

interface UpstreamQueueItem {
    taskId: number;
    level: number;
    dependencyType: DependencyRelationType;
}

const buildUpstreamTaskIdMap = (
    taskList: QuartzTask[],
    picker: (task: QuartzTask) => number[]
) => {
    const map = new Map<number, number[]>();
    taskList.forEach(task => {
        map.set(task.id, picker(task));
    });
    return map;
};

const buildDownstreamTaskIdMap = (
    taskList: QuartzTask[],
    picker: (task: QuartzTask) => number[]
) => {
    const map = new Map<number, number[]>();
    taskList.forEach(task => {
        picker(task).forEach(preTaskId => {
            const next = map.get(preTaskId) || [];
            next.push(task.id);
            map.set(preTaskId, next);
        });
    });
    return map;
};

const mergeDependencyType = (item: DependencyRelationItem, dependencyType: DependencyRelationType) => {
    if (!item.dependencyTypes.includes(dependencyType)) {
        item.dependencyTypes.push(dependencyType);
    }
};

const mergeInstanceByPlanDate = (
    map: Map<string, QuartzTaskStatus>,
    instance: QuartzTaskStatus
) => {
    const key = `${instance.plan_id}_${instance.data_date}`;
    const existing = map.get(key);
    if (!existing) {
        map.set(key, instance);
        return;
    }

    const existingTime = new Date(existing.update_time || existing.create_time).getTime();
    const incomingTime = new Date(instance.update_time || instance.create_time).getTime();
    if (incomingTime >= existingTime) {
        map.set(key, instance);
    }
};

export const useDependencyInsightData = ({
    selectedInstance,
    taskList,
    instanceList,
    taskMap,
    enabled = true,
    includeImpact = true,
}: UseDependencyInsightDataParams): DependencyInsightData | null => {
    const [dateInstances, setDateInstances] = useState<QuartzTaskStatus[]>([]);
    const [dateInstanceMeta, setDateInstanceMeta] = useState({
        total: 0,
        loaded: 0,
        truncated: false,
    });

    useEffect(() => {
        const dataDate = selectedInstance?.data_date;
        if (!enabled || !dataDate) {
            setDateInstances([]);
            setDateInstanceMeta({ total: 0, loaded: 0, truncated: false });
            return;
        }

        let canceled = false;

        const loadDateInstances = async () => {
            try {
                const firstResponse = await queryQuartzTaskStatus({
                    dataDate,
                    pageNum: 1,
                    pageSize: DEPENDENCY_DATE_INSTANCE_PAGE_SIZE,
                });
                if (!firstResponse?.success) {
                    throw new Error(firstResponse?.msg || '加载依赖实例失败');
                }

                const totalPages = Number(firstResponse.data?.pages || 1);
                const totalCount = Number(firstResponse.data?.total || firstResponse.data?.list?.length || 0);
                const pagesToLoad = Math.min(totalPages, MAX_DEPENDENCY_DATE_INSTANCE_PAGES);
                const mergedInstances = [...(firstResponse.data?.list || []).map(normalizeStatus)];

                for (let pageNum = 2; pageNum <= pagesToLoad; pageNum += 1) {
                    const response = await queryQuartzTaskStatus({
                        dataDate,
                        pageNum,
                        pageSize: DEPENDENCY_DATE_INSTANCE_PAGE_SIZE,
                    });
                    if (canceled) {
                        return;
                    }
                    if (response?.success) {
                        mergedInstances.push(...(response.data?.list || []).map(normalizeStatus));
                    }
                }

                if (!canceled) {
                    setDateInstances(mergedInstances);
                    setDateInstanceMeta({
                        total: totalCount,
                        loaded: mergedInstances.length,
                        truncated: totalPages > pagesToLoad,
                    });
                }
            } catch (error) {
                if (!canceled) {
                    console.warn(error);
                    setDateInstances([]);
                    setDateInstanceMeta({ total: 0, loaded: 0, truncated: false });
                }
            }
        };

        void loadDateInstances();

        return () => {
            canceled = true;
        };
    }, [enabled, selectedInstance?.data_date]);

    const instanceByPlanDate = useMemo(() => {
        const map = new Map<string, QuartzTaskStatus>();
        dateInstances.forEach(instance => {
            mergeInstanceByPlanDate(map, instance);
        });
        instanceList.forEach(instance => {
            mergeInstanceByPlanDate(map, instance);
        });
        if (selectedInstance) {
            mergeInstanceByPlanDate(map, selectedInstance);
        }
        return map;
    }, [dateInstances, instanceList, selectedInstance]);

    const dataUpstreamTaskIdMap = useMemo(
        () => buildUpstreamTaskIdMap(taskList, getDataDependIds),
        [taskList]
    );
    const controlUpstreamTaskIdMap = useMemo(
        () => buildUpstreamTaskIdMap(taskList, getControlDependIds),
        [taskList]
    );
    const allUpstreamTaskIdMap = useMemo(
        () => buildUpstreamTaskIdMap(taskList, getAllDependIds),
        [taskList]
    );
    const dataDownstreamTaskIdMap = useMemo(
        () => buildDownstreamTaskIdMap(taskList, getDataDependIds),
        [taskList]
    );
    const controlDownstreamTaskIdMap = useMemo(
        () => buildDownstreamTaskIdMap(taskList, getControlDependIds),
        [taskList]
    );

    return useMemo<DependencyInsightData | null>(() => {
        if (!enabled || !selectedInstance) return null;

        let graphTruncated = false;
        const canAppendNode = (map: Map<number, unknown>, taskId: number) => {
            if (map.has(taskId)) {
                return true;
            }
            if (map.size >= MAX_DEPENDENCY_GRAPH_NODES) {
                graphTruncated = true;
                return false;
            }
            return true;
        };

        const selectedTask = taskMap.get(selectedInstance.plan_id);
        const pickRelatedInstance = (taskId: number) => {
            return instanceByPlanDate.get(`${taskId}_${selectedInstance.data_date}`);
        };

        const toRelationItem = (
            taskId: number,
            dependencyTypes: DependencyRelationType[]
        ): DependencyRelationItem => {
            const relationTask = taskMap.get(taskId);
            return {
                taskId,
                taskName: relationTask?.task_name || `任务 #${taskId}`,
                taskSystem: relationTask?.task_system || '-',
                theme: relationTask?.theme || '-',
                relatedInstance: pickRelatedInstance(taskId),
                missingTask: !relationTask,
                dependencyTypes,
            };
        };

        const enqueueUpstream = (queue: UpstreamQueueItem[], taskIds: number[], level: number, dependencyType: DependencyRelationType) => {
            taskIds.forEach(taskId => queue.push({ taskId, level, dependencyType }));
        };

        const blockingUpstreamMap = new Map<number, BlockingDependencyItem>();
        const upstreamQueue: UpstreamQueueItem[] = [];
        enqueueUpstream(upstreamQueue, dataUpstreamTaskIdMap.get(selectedInstance.plan_id) || [], 1, 'DATA');
        enqueueUpstream(upstreamQueue, controlUpstreamTaskIdMap.get(selectedInstance.plan_id) || [], 1, 'CONTROL');
        const visitedUpstreamIds = new Set<number>();

        while (upstreamQueue.length > 0) {
            const current = upstreamQueue.shift();
            if (!current) {
                continue;
            }
            if (visitedUpstreamIds.size >= MAX_DEPENDENCY_GRAPH_NODES) {
                graphTruncated = true;
                break;
            }

            const existingBlocking = blockingUpstreamMap.get(current.taskId);
            if (existingBlocking) {
                mergeDependencyType(existingBlocking, current.dependencyType);
                existingBlocking.level = Math.min(existingBlocking.level, current.level);
            }

            if (visitedUpstreamIds.has(current.taskId)) {
                continue;
            }
            visitedUpstreamIds.add(current.taskId);

            const relation = toRelationItem(current.taskId, [current.dependencyType]);
            const status = relation.relatedInstance?.status;
            if (!status || incompleteInstanceStatuses.has(status)) {
                blockingUpstreamMap.set(current.taskId, {
                    ...relation,
                    level: current.level,
                });
            }

            (allUpstreamTaskIdMap.get(current.taskId) || []).forEach(nextTaskId => {
                if (!visitedUpstreamIds.has(nextTaskId)) {
                    const isData = (dataUpstreamTaskIdMap.get(current.taskId) || []).includes(nextTaskId);
                    upstreamQueue.push({
                        taskId: nextTaskId,
                        level: current.level + 1,
                        dependencyType: isData ? 'DATA' : 'CONTROL',
                    });
                }
            });
        }

        const blockingUpstream = Array.from(blockingUpstreamMap.values()).sort((a, b) => {
            const aStatus = a.relatedInstance?.status ?? 99;
            const bStatus = b.relatedInstance?.status ?? 99;
            const rankDiff = (blockingStatusRank[aStatus] ?? 99) - (blockingStatusRank[bStatus] ?? 99);
            if (rankDiff !== 0) {
                return rankDiff;
            }
            return a.level - b.level;
        });
        const downstreamMetaMap = new Map<number, DownstreamImpactMeta>();
        const allDownstreamMetaMap = new Map<number, DownstreamImpactMeta>();

        if (!includeImpact) {
            return {
                selectedTask,
                blockingUpstream,
                downstreamRootTaskIds: [],
                downstreamMetaMap,
                allDownstreamRootTaskIds: [],
                allDownstreamMetaMap,
                rerunImpactItems: [],
                downstreamTotalCount: 0,
                impactedDownstreamCount: 0,
                failedUpstreamCount: blockingUpstream.filter(item => item.relatedInstance?.status === 4).length,
                graphTruncated,
                instanceDataTruncated: dateInstanceMeta.truncated,
                loadedDateInstanceCount: dateInstanceMeta.loaded,
                totalDateInstanceCount: dateInstanceMeta.total,
            };
        }

        const downstreamDescendantIdSetMap = new Map<number, Set<number>>();
        const allDownstreamDescendantIdSetMap = new Map<number, Set<number>>();

        const mergeTaskIds = (...groups: number[][]) =>
            Array.from(new Set(groups.flat()));

        const getAllDownstreamChildEntries = (taskId: number) => {
            const childTypeMap = new Map<number, DependencyRelationType[]>();
            const append = (childTaskId: number, dependencyType: DependencyRelationType) => {
                const types = childTypeMap.get(childTaskId) || [];
                if (!types.includes(dependencyType)) {
                    types.push(dependencyType);
                }
                childTypeMap.set(childTaskId, types);
            };

            (dataDownstreamTaskIdMap.get(taskId) || []).forEach(childTaskId => append(childTaskId, 'DATA'));
            (controlDownstreamTaskIdMap.get(taskId) || []).forEach(childTaskId => append(childTaskId, 'CONTROL'));
            return Array.from(childTypeMap.entries()).map(([childTaskId, dependencyTypes]) => ({
                taskId: childTaskId,
                dependencyTypes,
            }));
        };

        const buildDownstreamMeta = (
            taskId: number,
            path: Set<number>
        ): DownstreamImpactMeta => {
            const cached = downstreamMetaMap.get(taskId);
            if (cached) {
                return cached;
            }

            if (!canAppendNode(downstreamMetaMap, taskId)) {
                return {
                    ...toRelationItem(taskId, ['DATA']),
                    impacted: false,
                    hasImpactedDescendant: false,
                    directChildIds: [],
                    descendantCount: 0,
                };
            }

            const relation = toRelationItem(taskId, ['DATA']);
            const directChildIds = (dataDownstreamTaskIdMap.get(taskId) || []).filter(childTaskId => !path.has(childTaskId));
            const meta = {
                ...relation,
                impacted: relation.relatedInstance?.status !== 3,
                hasImpactedDescendant: false,
                directChildIds,
                descendantCount: 0,
            };
            downstreamMetaMap.set(taskId, meta);

            const descendantIdSet = new Set<number>();
            let hasImpactedDescendant = false;

            directChildIds.forEach(childTaskId => {
                const nextPath = new Set(path);
                nextPath.add(childTaskId);
                const childMeta = buildDownstreamMeta(childTaskId, nextPath);
                descendantIdSet.add(childTaskId);
                const childDescendantIdSet = downstreamDescendantIdSetMap.get(childTaskId);
                childDescendantIdSet?.forEach(descendantTaskId => {
                    descendantIdSet.add(descendantTaskId);
                });
                if (childMeta.impacted || childMeta.hasImpactedDescendant) {
                    hasImpactedDescendant = true;
                }
            });

            downstreamDescendantIdSetMap.set(taskId, descendantIdSet);
            meta.descendantCount = descendantIdSet.size;
            meta.hasImpactedDescendant = hasImpactedDescendant;
            return meta;
        };

        const buildAllDownstreamMeta = (
            taskId: number,
            path: Set<number>,
            dependencyTypes: DependencyRelationType[]
        ): DownstreamImpactMeta => {
            const childEntries = getAllDownstreamChildEntries(taskId)
                .filter(child => !path.has(child.taskId));
            const directChildIds = childEntries.map(child => child.taskId);
            const cached = allDownstreamMetaMap.get(taskId);
            if (cached) {
                dependencyTypes.forEach(type => mergeDependencyType(cached, type));
                cached.directChildIds = mergeTaskIds(cached.directChildIds, directChildIds);
                return cached;
            }

            if (!canAppendNode(allDownstreamMetaMap, taskId)) {
                return {
                    ...toRelationItem(taskId, dependencyTypes),
                    impacted: false,
                    hasImpactedDescendant: false,
                    directChildIds: [],
                    descendantCount: 0,
                };
            }

            const relation = toRelationItem(taskId, dependencyTypes);
            const meta = {
                ...relation,
                impacted: relation.relatedInstance?.status !== 3,
                hasImpactedDescendant: false,
                directChildIds,
                descendantCount: 0,
            };
            allDownstreamMetaMap.set(taskId, meta);

            const descendantIdSet = new Set<number>();
            let hasImpactedDescendant = false;

            childEntries.forEach(child => {
                const nextPath = new Set(path);
                nextPath.add(child.taskId);
                const childMeta = buildAllDownstreamMeta(child.taskId, nextPath, child.dependencyTypes);
                descendantIdSet.add(child.taskId);
                const childDescendantIdSet = allDownstreamDescendantIdSetMap.get(child.taskId);
                childDescendantIdSet?.forEach(descendantTaskId => {
                    descendantIdSet.add(descendantTaskId);
                });
                if (childMeta.impacted || childMeta.hasImpactedDescendant) {
                    hasImpactedDescendant = true;
                }
            });

            allDownstreamDescendantIdSetMap.set(taskId, descendantIdSet);
            meta.descendantCount = descendantIdSet.size;
            meta.hasImpactedDescendant = hasImpactedDescendant;
            return meta;
        };

        const rerunImpactItemMap = new Map<number, RerunImpactItem>();
        const rerunImpactOrder: number[] = [];
        const visitedRerunDataIds = new Set<number>();
        const visitedRerunControlIds = new Set<number>();

        const ensureRerunImpactItem = (
            taskId: number,
            dependencyTypes: DependencyRelationType[],
            level: number,
            routeKey: string,
            current = false
        ) => {
            const existing = rerunImpactItemMap.get(taskId);
            if (existing) {
                dependencyTypes.forEach(type => mergeDependencyType(existing, type));
                if (level < existing.level) {
                    existing.level = level;
                    existing.routeKey = routeKey;
                }
                existing.current = existing.current || current;
                return existing;
            }

            if (!canAppendNode(rerunImpactItemMap, taskId)) {
                return null;
            }

            const relation = toRelationItem(taskId, [...dependencyTypes]);
            const relatedInstance = current ? selectedInstance : relation.relatedInstance;
            const item: RerunImpactItem = {
                ...relation,
                relatedInstance,
                impacted: relatedInstance?.status !== 3,
                hasImpactedDescendant: false,
                directChildIds: [],
                descendantCount: 0,
                level,
                routeKey,
                current,
            };
            rerunImpactItemMap.set(taskId, item);
            rerunImpactOrder.push(taskId);
            return item;
        };

        const splitRerunDataChildren = (taskIds: number[]) => {
            const mainDataChildIds: number[] = [];
            const leafDataChildIds: number[] = [];
            taskIds.forEach(taskId => {
                if ((dataDownstreamTaskIdMap.get(taskId) || []).length > 0) {
                    mainDataChildIds.push(taskId);
                    return;
                }
                leafDataChildIds.push(taskId);
            });
            return { mainDataChildIds, leafDataChildIds };
        };

        const visitRerunControlChain = (taskId: number, level: number, ancestors: number[]) => {
            if (ancestors.includes(taskId)) {
                return;
            }

            const route = [...ancestors, taskId];
            const item = ensureRerunImpactItem(taskId, ['CONTROL'], level, route.join('>'));
            if (!item) {
                return;
            }
            if (visitedRerunDataIds.has(taskId) || visitedRerunControlIds.has(taskId)) {
                return;
            }
            visitedRerunControlIds.add(taskId);

            const childIds = (controlDownstreamTaskIdMap.get(taskId) || [])
                .filter(childTaskId => !route.includes(childTaskId));
            item.directChildIds = mergeTaskIds(item.directChildIds, childIds);
            childIds.forEach(childTaskId => visitRerunControlChain(childTaskId, level + 1, route));
        };

        const visitRerunDataChain = (taskId: number, level: number, ancestors: number[]) => {
            if (ancestors.includes(taskId)) {
                return;
            }

            const route = [...ancestors, taskId];
            const item = ensureRerunImpactItem(taskId, ['DATA'], level, route.join('>'));
            if (!item) {
                return;
            }
            if (visitedRerunDataIds.has(taskId)) {
                return;
            }
            visitedRerunDataIds.add(taskId);

            const dataChildIds = (dataDownstreamTaskIdMap.get(taskId) || [])
                .filter(childTaskId => !route.includes(childTaskId));
            const controlChildIds = (controlDownstreamTaskIdMap.get(taskId) || [])
                .filter(childTaskId => !route.includes(childTaskId));
            const { mainDataChildIds, leafDataChildIds } = splitRerunDataChildren(dataChildIds);
            item.directChildIds = mergeTaskIds(item.directChildIds, mainDataChildIds, controlChildIds, leafDataChildIds);
            mainDataChildIds.forEach(childTaskId => visitRerunDataChain(childTaskId, level + 1, route));
            controlChildIds.forEach(childTaskId => visitRerunControlChain(childTaskId, level + 1, route));
            leafDataChildIds.forEach(childTaskId => visitRerunDataChain(childTaskId, level + 1, route));
        };

        const sourceItem = ensureRerunImpactItem(
            selectedInstance.plan_id,
            [],
            0,
            `${selectedInstance.plan_id}`,
            true
        );
        if (!sourceItem) return null;
        visitedRerunDataIds.add(selectedInstance.plan_id);
        const sourceDataChildIds = (dataDownstreamTaskIdMap.get(selectedInstance.plan_id) || [])
            .filter(childTaskId => childTaskId !== selectedInstance.plan_id);
        const sourceControlChildIds = (controlDownstreamTaskIdMap.get(selectedInstance.plan_id) || [])
            .filter(childTaskId => childTaskId !== selectedInstance.plan_id);
        const sourceDataChildren = splitRerunDataChildren(sourceDataChildIds);
        sourceItem.directChildIds = mergeTaskIds(
            sourceItem.directChildIds,
            sourceDataChildren.mainDataChildIds,
            sourceControlChildIds,
            sourceDataChildren.leafDataChildIds
        );
        sourceDataChildren.mainDataChildIds.forEach(childTaskId => visitRerunDataChain(childTaskId, 1, [selectedInstance.plan_id]));
        sourceControlChildIds.forEach(childTaskId => visitRerunControlChain(childTaskId, 1, [selectedInstance.plan_id]));
        sourceDataChildren.leafDataChildIds.forEach(childTaskId => visitRerunDataChain(childTaskId, 1, [selectedInstance.plan_id]));

        const resolveRerunDescendants = (taskId: number, path: Set<number>) => {
            const item = rerunImpactItemMap.get(taskId);
            const descendantIds = new Set<number>();
            if (!item) {
                return descendantIds;
            }

            item.directChildIds = item.directChildIds.filter(childTaskId =>
                rerunImpactItemMap.has(childTaskId) && !path.has(childTaskId)
            );
            let hasImpactedDescendant = false;
            item.directChildIds.forEach(childTaskId => {
                const nextPath = new Set(path);
                nextPath.add(childTaskId);
                const childDescendants = resolveRerunDescendants(childTaskId, nextPath);
                const childItem = rerunImpactItemMap.get(childTaskId);
                descendantIds.add(childTaskId);
                childDescendants.forEach(descendantTaskId => descendantIds.add(descendantTaskId));
                if (childItem?.impacted || childItem?.hasImpactedDescendant) {
                    hasImpactedDescendant = true;
                }
            });
            item.descendantCount = descendantIds.size;
            item.hasImpactedDescendant = hasImpactedDescendant;
            return descendantIds;
        };
        resolveRerunDescendants(selectedInstance.plan_id, new Set([selectedInstance.plan_id]));
        const rerunImpactItems = rerunImpactOrder
            .map(taskId => rerunImpactItemMap.get(taskId))
            .filter((item): item is RerunImpactItem => !!item);

        const downstreamRootTaskIds = dataDownstreamTaskIdMap.get(selectedInstance.plan_id) || [];
        downstreamRootTaskIds.forEach(taskId => {
            buildDownstreamMeta(taskId, new Set([selectedInstance.plan_id, taskId]));
        });

        const allDownstreamRootEntries = getAllDownstreamChildEntries(selectedInstance.plan_id);
        const allDownstreamRootTaskIds = allDownstreamRootEntries.map(child => child.taskId);
        allDownstreamRootEntries.forEach(child => {
            buildAllDownstreamMeta(child.taskId, new Set([selectedInstance.plan_id, child.taskId]), child.dependencyTypes);
        });

        return {
            selectedTask,
            blockingUpstream,
            downstreamRootTaskIds,
            downstreamMetaMap,
            allDownstreamRootTaskIds,
            allDownstreamMetaMap,
            rerunImpactItems,
            downstreamTotalCount: downstreamMetaMap.size,
            impactedDownstreamCount: Array.from(downstreamMetaMap.values()).filter(item => item.impacted).length,
            failedUpstreamCount: blockingUpstream.filter(item => item.relatedInstance?.status === 4).length,
            graphTruncated,
            instanceDataTruncated: dateInstanceMeta.truncated,
            loadedDateInstanceCount: dateInstanceMeta.loaded,
            totalDateInstanceCount: dateInstanceMeta.total,
        };
    }, [
        allUpstreamTaskIdMap,
        controlUpstreamTaskIdMap,
        controlDownstreamTaskIdMap,
        dataDownstreamTaskIdMap,
        dataUpstreamTaskIdMap,
        dateInstanceMeta,
        instanceByPlanDate,
        enabled,
        includeImpact,
        selectedInstance,
        taskMap,
    ]);
};
