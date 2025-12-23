export interface OrgNode {
    id: string;
    name: string;
    code: string;
    type: 'HEAD' | 'BRANCH' | 'DEPT' | 'SUB_BRANCH';
    typeName: string;
    status: 'active' | 'inactive';
    parentId?: string;
    orderNum?: number;
    children?: OrgNode[];
}

export interface Role {
    id: string;
    name: string;
    code: string;
    permission: string;
    count: number;
    status: 'active' | 'inactive';
    desc: string;
}

export interface User {
    id: string;
    name: string;
    empId: string;
    orgName: string;
    roleName: string;
    roleId?: number; // New: Added for role association
    ssoSystem?: string;
    phone: string;
    lastLogin: string;
    status: 'active' | 'inactive';
}

export interface SsoConfig {
    id: string;
    name: string;
    protocol: string;
    clientId: string;
    callbackUrl: string;
    algorithm: string;
    network: string;
    status: string;
    icon?: string;
}

export interface FunctionPoint {
    id: string;
    name: string;
    code: string;
    type: 'menu' | 'dir' | 'button';
    path: string;
    level: number;
    parentId: string;
}

export interface TreeNode extends FunctionPoint {
    children?: TreeNode[];
}
