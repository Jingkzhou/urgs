import React from 'react';
import { hasPermission } from '../utils/permission';

interface AuthProps {
    code: string;
    children: React.ReactNode;
}

/**
 * Auth Component
 * 
 * Renders children only if the user has the specified permission code
 * AND the code is valid (defined in manifest).
 * 
 * Usage:
 * <Auth code="sys:user:add">
 *   <Button>Add User</Button>
 * </Auth>
 */
const Auth: React.FC<AuthProps> = ({ code, children }) => {
    if (hasPermission(code)) {
        return <>{children}</>;
    }
    return null;
};

export default Auth;
