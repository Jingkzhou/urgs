export interface SystemLink {
  id: string;
  name: string;
  description: string;
  iconName: 'Shield' | 'BarChart' | 'FileText' | 'Globe' | 'Users' | 'Database' | 'Activity' | 'Lock';
  status: 'active' | 'maintenance' | 'beta';
}

export interface Notice {
  id: string;
  title: string;
  date: string;
  type: 'urgent' | 'normal' | 'update' | 'regulatory';
  category: 'Announcement' | 'Log';
  content?: string;
  systems?: string;
  createBy?: string;
  hasRead?: boolean;
}

export interface CompletionStat {
  institution: string;
  submitted: number;
  approved: number;
  pending: number;
}

export interface TrendStat {
  month: string;
  riskScore: number;
  complianceRate: number;
}