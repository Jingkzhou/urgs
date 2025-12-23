import { SystemLink, Notice, CompletionStat, TrendStat } from './types';

export const LOGO_URL = "/jlbank_logo.png";

export const SYSTEM_LINKS: SystemLink[] = [
  {
    id: '1',
    name: '反洗钱监测系统',
    description: 'Anti-Money Laundering Monitoring',
    iconName: 'Shield',
    status: 'active',
  },
  {
    id: '2',
    name: '征信报送平台',
    description: 'Credit Reporting Platform',
    iconName: 'Database',
    status: 'active',
  },
  {
    id: '3',
    name: '风险预警驾驶舱',
    description: 'Risk Early Warning Cockpit',
    iconName: 'Activity',
    status: 'active',
  },
  {
    id: '4',
    name: '监管报表报送',
    description: 'Regulatory Reporting Submission',
    iconName: 'FileText',
    status: 'active',
  },
  {
    id: '5',
    name: '跨境资金流动',
    description: 'Cross-border Capital Flow',
    iconName: 'Globe',
    status: 'beta',
  },
  {
    id: '6',
    name: '统一用户认证',
    description: 'Unified Identity Management',
    iconName: 'Users',
    status: 'active',
  },
  {
    id: '7',
    name: '数据质量核查',
    description: 'Data Quality Audit',
    iconName: 'BarChart',
    status: 'maintenance',
  },
  {
    id: '8',
    name: '安全审计日志',
    description: 'Security Audit Logs',
    iconName: 'Lock',
    status: 'active',
  },
];

export const NOTICES: Notice[] = [
  { id: '1', title: '关于2024年Q3监管数据报送的紧急通知', date: '2024-05-20', type: 'urgent', category: 'Announcement' },
  { id: '2', title: '金融机构反洗钱数据接口规范v2.1更新说明', date: '2024-05-18', type: 'normal', category: 'Announcement' },
  { id: '3', title: '系统停机维护公告 (2024-05-25)', date: '2024-05-15', type: 'normal', category: 'Announcement' },
  { id: '4', title: 'v3.5.0: 修复了Excel导入时的格式兼容性问题', date: '2024-05-10', type: 'update', category: 'Log' },
  { id: '5', title: 'v3.4.2: 优化了报表生成的查询速度', date: '2024-05-01', type: 'update', category: 'Log' },
  { id: '6', title: '新增"实时风险阻断"功能模块', date: '2024-04-28', type: 'update', category: 'Log' },
  { id: '7', title: '关于落实《金融机构反洗钱规定》的实施细则', date: '2024-06-01', type: 'regulatory', category: 'Announcement' },
];

export const COMPLETION_STATS: CompletionStat[] = [
  { institution: '分行A', submitted: 120, approved: 115, pending: 5 },
  { institution: '分行B', submitted: 98, approved: 90, pending: 8 },
  { institution: '分行C', submitted: 150, approved: 148, pending: 2 },
  { institution: '分行D', submitted: 80, approved: 60, pending: 20 },
  { institution: '子公司E', submitted: 110, approved: 105, pending: 5 },
];

export const TREND_STATS: TrendStat[] = [
  { month: 'Jan', riskScore: 65, complianceRate: 92 },
  { month: 'Feb', riskScore: 59, complianceRate: 94 },
  { month: 'Mar', riskScore: 80, complianceRate: 91 },
  { month: 'Apr', riskScore: 45, complianceRate: 96 },
  { month: 'May', riskScore: 50, complianceRate: 97 },
  { month: 'Jun', riskScore: 40, complianceRate: 98 },
];