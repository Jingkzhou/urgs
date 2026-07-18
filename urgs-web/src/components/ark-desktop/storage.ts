import {
    DEFAULT_ARK_DESKTOP_AGENTS,
    DEFAULT_ARK_DESKTOP_AUTOMATIONS,
    DEFAULT_ARK_DESKTOP_SKILLS,
} from './catalog';
import type { ArkDesktopSnapshot } from './types';

const STORAGE_KEY = 'urgs_ark_desktop_grok_snapshot_v2';
const MAX_TASK_HISTORY = 50;

const clone = <T>(value: T): T => JSON.parse(JSON.stringify(value));

export const createDefaultArkDesktopSnapshot = (): ArkDesktopSnapshot => ({
    agents: clone(DEFAULT_ARK_DESKTOP_AGENTS),
    skills: clone(DEFAULT_ARK_DESKTOP_SKILLS),
    automations: clone(DEFAULT_ARK_DESKTOP_AUTOMATIONS),
    tasks: [],
    settings: {
        workspace: '',
        grokModel: 'grok-4.5-build-free',
        defaultAgentId: 'grok-general',
        defaultSkillIds: [],
    },
});

export const loadArkDesktopSnapshot = (): ArkDesktopSnapshot => {
    const defaults = createDefaultArkDesktopSnapshot();
    if (typeof window === 'undefined') return defaults;
    try {
        const raw = localStorage.getItem(STORAGE_KEY);
        if (!raw) return defaults;
        const stored = JSON.parse(raw) as Partial<ArkDesktopSnapshot>;
        return {
            agents: Array.isArray(stored.agents) && stored.agents.length > 0 ? stored.agents : defaults.agents,
            skills: Array.isArray(stored.skills) && stored.skills.length > 0 ? stored.skills : defaults.skills,
            automations: Array.isArray(stored.automations) ? stored.automations : defaults.automations,
            tasks: Array.isArray(stored.tasks) ? stored.tasks.slice(0, MAX_TASK_HISTORY).map((task) => task.status === 'running'
                ? { ...task, status: 'failed' as const, error: '桌面客户端已重新启动，本次执行已中断', updatedAt: Date.now() }
                : task) : [],
            settings: { ...defaults.settings, ...(stored.settings || {}) },
        };
    } catch (error) {
        console.error('读取 ARK Desktop 本地配置失败', error);
        return defaults;
    }
};

export const saveArkDesktopSnapshot = (snapshot: ArkDesktopSnapshot) => {
    if (typeof window === 'undefined') return;
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
        ...snapshot,
        tasks: snapshot.tasks.slice(0, MAX_TASK_HISTORY),
    }));
};

export const resetArkDesktopSnapshot = () => {
    if (typeof window !== 'undefined') {
        localStorage.removeItem(STORAGE_KEY);
    }
    return createDefaultArkDesktopSnapshot();
};
