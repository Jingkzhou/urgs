import { permissionManifest } from '../permissions/manifest';

/**
 * Strict Permission Check
 * 
 * Logic:
 * 1. Validity Check: The code MUST exist in the local manifest.
 * 2. Authorization Check: The user MUST have the code in their permissions list.
 * 
 * @param code The permission code to check (e.g., 'sys:user:add')
 * @returns true if visible, false otherwise
 */
export const hasPermission = (code: string): boolean => {
    if (!code) return false;

    // 1. Validity Check: Check if code exists in Manifest
    // We use a simple find here. For larger datasets, consider creating a Set once.
    const isDefinedInManifest = permissionManifest.some(item => item.code === code);

    if (!isDefinedInManifest) {
        // Code is not defined in the system (e.g. deprecated, typo, or backend-only)
        // Strict mode: Hide it.
        return false;
    }

    // 2. Authorization Check: Check if user has this permission
    try {
        // Bypass check if user is a System Administrator
        const userStr = localStorage.getItem('auth_user');
        if (userStr) {
            const user = JSON.parse(userStr);
            if (user.roleName === '系统管理员') return true;
        }

        const permissionsStr = localStorage.getItem('user_permissions');
        if (!permissionsStr) return false;

        const userPermissions: string[] = JSON.parse(permissionsStr);
        if (!Array.isArray(userPermissions)) return false;

        return userPermissions.includes(code);
    } catch (e) {
        // Any error -> restrict permission
        return false;
    }
};
