import { QuartzTask, QuartzTaskStatus } from '../mockData';

export interface DependencyRelationItem {
    taskId: number;
    taskName: string;
    taskSystem: string;
    theme: string;
    relatedInstance?: QuartzTaskStatus;
    missingTask?: boolean;
}

export interface BlockingDependencyItem extends DependencyRelationItem {
    level: number;
}

export interface DownstreamImpactMeta extends DependencyRelationItem {
    impacted: boolean;
    hasImpactedDescendant: boolean;
    directChildIds: number[];
    descendantCount: number;
}

export interface DependencyInsightData {
    selectedTask?: QuartzTask;
    blockingUpstream: BlockingDependencyItem[];
    downstreamRootTaskIds: number[];
    downstreamMetaMap: Map<number, DownstreamImpactMeta>;
    downstreamTotalCount: number;
    impactedDownstreamCount: number;
    failedUpstreamCount: number;
}

export interface RowContextMenuState {
    x: number;
    y: number;
    instance: QuartzTaskStatus;
}

export interface TaskInstanceStats {
    waitingInstances: number;
    runningInstances: number;
    successInstances: number;
    failedInstances: number;
}

export interface TaskInstanceProps {
    onStatsChange?: (stats: TaskInstanceStats) => void;
}

export type InstanceDetailTabKey =
    | 'overview'
    | 'task'
    | 'schedule'
    | 'dependency'
    | 'execution'
    | 'runtimeLog'
    | 'notify';
