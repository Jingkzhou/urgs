import { QuartzTask, QuartzTaskStatus } from '../mockData';

export type DependencyRelationType = 'DATA' | 'CONTROL';

export interface DependencyRelationItem {
    taskId: number;
    taskName: string;
    taskSystem: string;
    theme: string;
    relatedInstance?: QuartzTaskStatus;
    missingTask?: boolean;
    dependencyTypes: DependencyRelationType[];
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

export interface RerunImpactItem extends DownstreamImpactMeta {
    level: number;
    routeKey: string;
    current?: boolean;
}

export interface DependencyInsightData {
    selectedTask?: QuartzTask;
    blockingUpstream: BlockingDependencyItem[];
    downstreamRootTaskIds: number[];
    downstreamMetaMap: Map<number, DownstreamImpactMeta>;
    allDownstreamRootTaskIds: number[];
    allDownstreamMetaMap: Map<number, DownstreamImpactMeta>;
    rerunImpactItems: RerunImpactItem[];
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
    totalInstances: number;
    waitingInstances: number;
    runningInstances: number;
    successInstances: number;
    failedInstances: number;
}

export interface TaskInstanceInitialFilters {
    keyword?: string;
    taskSystem?: string;
    theme?: string;
    remark?: string;
    dataDate?: string;
    createDate?: string;
    status?: string;
}

export interface TaskInstanceProps {
    onStatsChange?: (stats: TaskInstanceStats) => void;
    initialFilters?: TaskInstanceInitialFilters;
}

export type InstanceDetailTabKey =
    | 'overview'
    | 'task'
    | 'dependency'
    | 'execution'
    | 'runtimeLog'
    | 'notify';
