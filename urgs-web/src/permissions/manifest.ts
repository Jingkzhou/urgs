import { FunctionPoint } from '../components/system/types';

export interface PermissionManifestMeta {
    version: string;
    generatedAt: string;
    source: 'front-end-manifest';
}

export const manifestMeta: PermissionManifestMeta = {
    version: '1.0.0',
    generatedAt: new Date().toISOString(),
    source: 'front-end-manifest',
};

// Single source of truth for all menus & buttons.
// Add new routes/buttons here (or generate this file via a build script) so they appear in“功能资源维护”与角色授权。
export const permissionManifest: FunctionPoint[] = [
    { id: '1', name: '工作台', code: 'dashboard', type: 'menu', path: '/dashboard', level: 0, parentId: 'root' },
    { id: '1-1', name: '系统跳转区', code: 'dash:systems', type: 'button', path: '-', level: 1, parentId: '1' },
    { id: '1-2', name: '统计分析区', code: 'dash:stats', type: 'button', path: '-', level: 1, parentId: '1' },
    { id: '1-3', name: '公告查看', code: 'dash:notice:view', type: 'button', path: '-', level: 1, parentId: '1' },
    { id: '1-4', name: '批量监控', code: 'dash:Batch-monitoring', type: 'button', path: '-', level: 1, parentId: '1' },
    { id: '1-5', name: '研发工作台', code: 'dash:dev', type: 'button', path: '-', level: 1, parentId: '1' },
    { id: '1-5-1', name: '流水线监控', code: 'dash:dev:pipeline', type: 'button', path: '-', level: 2, parentId: '1-5' },
    { id: '1-5-2', name: '错误日志', code: 'dash:dev:logs', type: 'button', path: '-', level: 2, parentId: '1-5' },
    { id: '1-5-3', name: 'API状态', code: 'dash:dev:api', type: 'button', path: '-', level: 2, parentId: '1-5' },
    { id: '7', name: 'Ark (方舟)', code: 'ark', type: 'menu', path: '/ark', level: 0, parentId: 'root' },
    { id: '2', name: '公告管理', code: 'announcement', type: 'menu', path: '/announcement', level: 0, parentId: 'root' },
    { id: '2-1', name: '公告列表', code: 'announcement:list', type: 'menu', path: '/announcement/list', level: 1, parentId: '2' },
    { id: '2-1-1', name: '发布公告', code: 'announcement:publish', type: 'button', path: '/announcement/publish', level: 2, parentId: '2-1' },
    { id: '2-1-2', name: '编辑公告', code: 'announcement:edit', type: 'button', path: '/announcement/edit', level: 2, parentId: '2-1' },
    { id: '2-1-3', name: '删除公告', code: 'announcement:del', type: 'button', path: '/announcement/del', level: 2, parentId: '2-1' },

    { id: '2-2', name: '任务调度管理', code: 'schedule', type: 'menu', path: '/schedule', level: 0, parentId: 'root' },
    { id: '2-2-1', name: '新建调度', code: 'schedule:create', type: 'button', path: '-', level: 1, parentId: '2-2' },
    { id: '2-2-2', name: '刷新状态', code: 'schedule:refresh', type: 'button', path: '-', level: 1, parentId: '2-2' },

    { id: '3', name: '系统管理', code: 'sys', type: 'dir', path: '/admin', level: 0, parentId: 'root' },

    { id: '3-1', name: '机构管理', code: 'sys:org', type: 'menu', path: '/admin/org', level: 1, parentId: '3' },
    { id: '3-1-1', name: '查询', code: 'sys:org:query', type: 'button', path: '-', level: 2, parentId: '3-1' },
    { id: '3-1-2', name: '新增', code: 'sys:org:add', type: 'button', path: '-', level: 2, parentId: '3-1' },
    { id: '3-1-3', name: '编辑', code: 'sys:org:edit', type: 'button', path: '-', level: 2, parentId: '3-1' },
    { id: '3-1-4', name: '删除', code: 'sys:org:del', type: 'button', path: '-', level: 2, parentId: '3-1' },

    { id: '3-2', name: '角色管理', code: 'sys:role', type: 'menu', path: '/admin/role', level: 1, parentId: '3' },
    { id: '3-2-1', name: '查询', code: 'sys:role:query', type: 'button', path: '-', level: 2, parentId: '3-2' },
    { id: '3-2-2', name: '新增', code: 'sys:role:add', type: 'button', path: '-', level: 2, parentId: '3-2' },
    { id: '3-2-3', name: '编辑', code: 'sys:role:edit', type: 'button', path: '-', level: 2, parentId: '3-2' },
    { id: '3-2-4', name: '删除', code: 'sys:role:del', type: 'button', path: '-', level: 2, parentId: '3-2' },

    { id: '3-3', name: '用户管理', code: 'sys:user', type: 'menu', path: '/admin/user', level: 1, parentId: '3' },
    { id: '3-3-1', name: '查询', code: 'sys:user:query', type: 'button', path: '-', level: 2, parentId: '3-3' },
    { id: '3-3-2', name: '新增', code: 'sys:user:add', type: 'button', path: '-', level: 2, parentId: '3-3' },
    { id: '3-3-3', name: '编辑', code: 'sys:user:edit', type: 'button', path: '-', level: 2, parentId: '3-3' },
    { id: '3-3-4', name: '删除', code: 'sys:user:del', type: 'button', path: '-', level: 2, parentId: '3-3' },

    { id: '3-4', name: '菜单功能管理', code: 'sys:menu', type: 'menu', path: '/admin/menu', level: 1, parentId: '3' },
    { id: '3-4-1', name: '动态捕捉', code: 'sys:menu:sync', type: 'button', path: '-', level: 2, parentId: '3-4' },
    { id: '3-4-2', name: '新增', code: 'sys:menu:add', type: 'button', path: '-', level: 2, parentId: '3-4' },
    { id: '3-4-3', name: '编辑', code: 'sys:menu:edit', type: 'button', path: '-', level: 2, parentId: '3-4' },
    { id: '3-4-4', name: '删除', code: 'sys:menu:del', type: 'button', path: '-', level: 2, parentId: '3-4' },

    { id: '3-5', name: '监管系统管理', code: 'sys:system', type: 'menu', path: '/admin/system', level: 1, parentId: '3' },
    { id: '3-5-1', name: '查询', code: 'sys:system:query', type: 'button', path: '-', level: 2, parentId: '3-5' },
    { id: '3-5-2', name: '新增配置', code: 'sys:system:add', type: 'button', path: '-', level: 2, parentId: '3-5' },
    { id: '3-5-3', name: '编辑配置', code: 'sys:system:edit', type: 'button', path: '-', level: 2, parentId: '3-5' },
    { id: '3-5-4', name: '删除配置', code: 'sys:system:del', type: 'button', path: '-', level: 2, parentId: '3-5' },

    { id: '3-6', name: '数据源配置', code: 'sys:datasource', type: 'menu', path: '/admin/datasource', level: 1, parentId: '3' },
    { id: '3-6-1', name: '查询', code: 'datasource:list', type: 'button', path: '-', level: 2, parentId: '3-6' },
    { id: '3-7', name: 'AI 管理', code: 'sys:ai', type: 'menu', path: '/admin/ai', level: 1, parentId: '3' },
    // API 管理模块
    { id: '3-7-1', name: 'API 管理', code: 'sys:ai:api', type: 'menu', path: '/admin/ai/api', level: 2, parentId: '3-7' },
    { id: '3-7-1-1', name: '查询', code: 'sys:ai:api:list', type: 'button', path: '-', level: 3, parentId: '3-7-1' },
    { id: '3-7-1-2', name: '新增', code: 'sys:ai:api:add', type: 'button', path: '-', level: 3, parentId: '3-7-1' },
    { id: '3-7-1-3', name: '编辑', code: 'sys:ai:api:edit', type: 'button', path: '-', level: 3, parentId: '3-7-1' },
    { id: '3-7-1-4', name: '删除', code: 'sys:ai:api:del', type: 'button', path: '-', level: 3, parentId: '3-7-1' },
    // 助手管理模块
    { id: '3-7-2', name: '助手管理', code: 'sys:ai:agent', type: 'menu', path: '/admin/ai/agent', level: 2, parentId: '3-7' },
    { id: '3-7-2-1', name: '查询', code: 'sys:ai:agent:list', type: 'button', path: '-', level: 3, parentId: '3-7-2' },
    { id: '3-7-2-2', name: '新增', code: 'sys:ai:agent:add', type: 'button', path: '-', level: 3, parentId: '3-7-2' },
    { id: '3-7-2-3', name: '编辑', code: 'sys:ai:agent:edit', type: 'button', path: '-', level: 3, parentId: '3-7-2' },
    { id: '3-7-2-4', name: '删除', code: 'sys:ai:agent:del', type: 'button', path: '-', level: 3, parentId: '3-7-2' },
    // 知识库管理模块
    { id: '3-7-3', name: '知识库管理', code: 'sys:ai:knowledge', type: 'menu', path: '/admin/ai/knowledge', level: 2, parentId: '3-7' },
    { id: '3-7-3-1', name: '查询', code: 'sys:ai:knowledge:list', type: 'button', path: '-', level: 3, parentId: '3-7-3' },
    { id: '3-7-3-2', name: '新增', code: 'sys:ai:knowledge:add', type: 'button', path: '-', level: 3, parentId: '3-7-3' },
    { id: '3-7-3-3', name: '编辑', code: 'sys:ai:knowledge:edit', type: 'button', path: '-', level: 3, parentId: '3-7-3' },
    { id: '3-7-3-4', name: '删除', code: 'sys:ai:knowledge:del', type: 'button', path: '-', level: 3, parentId: '3-7-3' },

    { id: '4', name: '版本管理', code: 'version', type: 'menu', path: '/version', level: 0, parentId: 'root' },

    // ================= Level 1 子菜单 =================

    // 1. 管理 20 套监管系统的基础信息（如系统名称、负责人、Git仓库地址）
    { id: '4-1', name: '应用系统库', code: 'version:app:list', type: 'menu', path: '/version/app', level: 1, parentId: '4' },

    // 1.5 管理 Git 仓库配置（支持 GitLab、Gitee、GitHub）
    { id: '4-1-1', name: 'Git 仓库管理', code: 'version:repo:list', type: 'menu', path: '/version/repos', level: 1, parentId: '4' },

    // 1.6 CI/CD 流水线管理
    { id: '4-1-2', name: '流水线管理', code: 'version:pipeline:list', type: 'menu', path: '/version/pipeline', level: 1, parentId: '4' },

    // 1.7 部署管理
    { id: '4-1-3', name: '部署管理', code: 'version:deploy:list', type: 'menu', path: '/version/deploy', level: 1, parentId: '4' },

    // 2. 核心页面：研发人员在此登记版本、上传包、查看历史
    { id: '4-2', name: '版本发布台账', code: 'version:release:list', type: 'menu', path: '/version/release', level: 1, parentId: '4' },

    // 3. 专门展示 AI 扫描出的风险报告、代码 Diff 分析
    { id: '4-3', name: 'AI 代码智查', code: 'version:ai:audit', type: 'menu', path: '/version/ai-audit', level: 1, parentId: '4' },

    // 4. 将技术日志转译为业务公告，并配置弹窗策略
    { id: '4-4', name: '业务公告管理', code: 'version:notice:config', type: 'menu', path: '/version/notice', level: 1, parentId: '4' },

    // 5. 统计看板：本月发布次数、各系统版本更新热度
    { id: '4-5', name: '发布数据统计', code: 'version:stats', type: 'menu', path: '/version/stats', level: 1, parentId: '4' },

    // ================= Level 2 页面内按钮/功能点 (示例) =================

    // --- 流水线管理下的按钮 ---
    { id: '4-1-2-1', name: '创建流水线', code: 'version:pipeline:add', type: 'button', path: '', level: 2, parentId: '4-1-2' },
    { id: '4-1-2-2', name: '触发执行', code: 'version:pipeline:trigger', type: 'button', path: '', level: 2, parentId: '4-1-2' },

    // --- 版本发布台账下的按钮 ---
    { id: '4-2-1', name: '版本登记', code: 'version:release:add', type: 'button', path: '', level: 2, parentId: '4-2' },
    { id: '4-2-2', name: '一键回滚', code: 'version:release:rollback', type: 'button', path: '', level: 2, parentId: '4-2' },

    // --- AI 代码智查下的按钮 ---
    { id: '4-3-1', name: '触发走查', code: 'version:ai:trigger', type: 'button', path: '', level: 2, parentId: '4-3' },
    { id: '4-3-2', name: '下载审计报告', code: 'version:ai:export', type: 'button', path: '', level: 2, parentId: '4-3' },
    { id: '5', name: '数据管理', code: 'metadata', type: 'menu', path: '/metadata', level: 0, parentId: 'root' },
    { id: '5-2', name: '数据模型', code: 'metadata:model', type: 'menu', path: '/metadata/model', level: 1, parentId: '5' },
    { id: '5-2-1', name: '同步元数据', code: 'metadata:model:sync', type: 'button', path: '-', level: 2, parentId: '5-2' },
    { id: '5-3', name: '数据查询', code: 'metadata:query', type: 'menu', path: '/metadata/query', level: 1, parentId: '5' },
    { id: '5-4', name: '监管指标资产管理', code: 'metadata:asset', type: 'menu', path: '/metadata/asset', level: 1, parentId: '5' },
    { id: '5-5', name: '血缘管理', code: 'metadata:lineage', type: 'menu', path: '/metadata/lineage', level: 1, parentId: '5' },
    { id: '5-5-1', name: '血缘溯源', code: 'metadata:lineage:origin', type: 'menu', path: '/metadata/lineage/origin', level: 2, parentId: '5-5' },
    { id: '5-5-2', name: '影响分析', code: 'metadata:lineage:analysis', type: 'menu', path: '/metadata/lineage/analysis', level: 2, parentId: '5-5' },

    { id: '6', name: '运维管理', code: 'ops', type: 'menu', path: '/ops', level: 0, parentId: 'root' },
    { id: '6-1', name: '调度管理', code: 'ops:schedule', type: 'menu', path: '/ops/schedule', level: 1, parentId: '6' },
    { id: '6-1-1', name: '工作流管理', code: 'ops:schedule:workflow', type: 'menu', path: '/ops/schedule/workflow', level: 2, parentId: '6-1' },
    { id: '6-1-1-1', name: '工作流定义', code: 'ops:schedule:workflow:define', type: 'menu', path: '/ops/schedule/workflow/define', level: 2, parentId: '6-1-1' },
    { id: '6-1-1-2', name: '工作流实例', code: 'ops:schedule:workflow:instance', type: 'menu', path: '/ops/schedule/workflow/instance', level: 2, parentId: '6-1-1' },
    { id: '6-1-2', name: '任务管理', code: 'ops:schedule:task', type: 'menu', path: '/ops/schedule/task', level: 2, parentId: '6-1' },
    { id: '6-1-2-1', name: '任务定义', code: 'ops:schedule:task:define', type: 'menu', path: '/ops/schedule/task/define', level: 2, parentId: '6-1-2' },
    { id: '6-1-2-2', name: '任务实例', code: 'ops:schedule:task:instance', type: 'menu', path: '/ops/schedule/task/instance', level: 2, parentId: '6-1-2' },
    { id: '6-2', name: '生产问题登记', code: 'ops:issue', type: 'menu', path: '/ops/issue', level: 1, parentId: '6' },
    { id: '6-2-1', name: '登记问题', code: 'ops:issue:create', type: 'button', path: '/ops/issue/create', level: 2, parentId: '6-2' },
    { id: '6-2-2', name: '删除问题', code: 'ops:issue:delete', type: 'button', path: '/ops/issue/delete', level: 2, parentId: '6-2' },
    { id: '6-2-3', name: '编辑问题', code: 'ops:issue:edit', type: 'button', path: '/ops/issue/edit', level: 2, parentId: '6-2' },
    { id: '6-2-4', name: '查看问题', code: 'ops:issue:view', type: 'button', path: '/ops/issue/view', level: 2, parentId: '6-2' },
    { id: '6-3', name: '基础设施管理', code: 'ops:infra:view', type: 'menu', path: '/ops/infra', level: 1, parentId: '6' },
];
