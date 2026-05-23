import { useMemo } from 'react';
import { QuartzTask, QuartzTaskStatus } from '../mockData';
import { blockingStatusRank, incompleteInstanceStatuses } from './constants';
import {
    BlockingDependencyItem,
    DependencyInsightData,
    DependencyRelationItem,
    DependencyRelationType,
    DownstreamImpactMeta,
} from './types';
import { getAllDependIds, getControlDependIds, getDataDependIds } from './utils';

interface UseDependencyInsightDataParams {
    selectedInstance: QuartzTaskStatus | null;
    taskList: QuartzTask[];
    instanceList: QuartzTaskStatus[];
    taskMap: Map<number, QuartzTask>;
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

export const useDependencyInsightData = ({
    selectedInstance,
    taskList,
    instanceList,
    taskMap,
}: UseDependencyInsightDataParams): DependencyInsightData | null => {
    const instanceByPlanDate = useMemo(() => {
        const map = new Map<string, QuartzTaskStatus>();
        instanceList.forEach(instance => {
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
        });
        return map;
    }, [instanceList]);

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

    return useMemo<DependencyInsightData | null>(() => {
        if (!selectedInstance) return null;

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

        const downstreamMetaMap = new Map<number, DownstreamImpactMeta>();
        const downstreamDescendantIdSetMap = new Map<number, Set<number>>();

        const buildDownstreamMeta = (
            taskId: number,
            path: Set<number>
        ): DownstreamImpactMeta => {
            const cached = downstreamMetaMap.get(taskId);
            if (cached) {
                return cached;
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

        const downstreamRootTaskIds = dataDownstreamTaskIdMap.get(selectedInstance.plan_id) || [];
        downstreamRootTaskIds.forEach(taskId => {
            buildDownstreamMeta(taskId, new Set([selectedInstance.plan_id, taskId]));
        });

        const blockingUpstream = Array.from(blockingUpstreamMap.values()).sort((a, b) => {
            const aStatus = a.relatedInstance?.status ?? 99;
            const bStatus = b.relatedInstance?.status ?? 99;
            const rankDiff = (blockingStatusRank[aStatus] ?? 99) - (blockingStatusRank[bStatus] ?? 99);
            if (rankDiff !== 0) {
                return rankDiff;
            }
            return a.level - b.level;
        });

        return {
            selectedTask,
            blockingUpstream,
            downstreamRootTaskIds,
            downstreamMetaMap,
            downstreamTotalCount: downstreamMetaMap.size,
            impactedDownstreamCount: Array.from(downstreamMetaMap.values()).filter(item => item.impacted).length,
            failedUpstreamCount: blockingUpstream.filter(item => item.relatedInstance?.status === 4).length,
        };
    }, [
        allUpstreamTaskIdMap,
        controlUpstreamTaskIdMap,
        dataDownstreamTaskIdMap,
        dataUpstreamTaskIdMap,
        instanceByPlanDate,
        selectedInstance,
        taskMap,
    ]);
};
