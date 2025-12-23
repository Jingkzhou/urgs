import React, { useRef, useState } from 'react';
import { User, Mail, Phone, Building, Briefcase, Camera } from 'lucide-react';
import { userService } from '../services/userService';

interface UserInfo {
    name?: string;
    empId?: string;
    roleName?: string;
    email?: string;
    phone?: string;
    department?: string;
    avatarUrl?: string; // Should come from SysUser now
    userId?: number;
    id?: string; // SysUser uses string ID in DTO usually, check
    roleId?: number; // Added roleId
}

const BasicInfo: React.FC<{ userInfo: UserInfo | null }> = ({ userInfo }) => {
    // Mock extended info if not present
    const [displayInfo, setDisplayInfo] = useState({
        ...userInfo,
        email: userInfo?.email || 'zhangsan@jilinbank.com.cn',
        phone: userInfo?.phone || '13800138000',
        department: userInfo?.department || '总行/信息科技部/软件开发中心',
    });

    // Auto-fix missing ID
    React.useEffect(() => {
        const fixMissingId = async () => {
            const storedUser = JSON.parse(localStorage.getItem('auth_user') || '{}');
            const currentId = displayInfo.userId || displayInfo.id || storedUser.id || storedUser.userId;

            if (!currentId) {
                console.log('Detected missing User ID, fetching profile...');
                try {
                    const profile = await userService.getProfile();
                    if (profile && profile.id) { // Check for id (string)
                        console.log('Fetched profile with ID:', profile.id);

                        // Update Local State
                        setDisplayInfo(prev => ({
                            ...prev,
                            userId: Number(profile.id),
                            id: profile.id,
                            name: profile.name,
                            empId: profile.empId,
                            roleId: profile.roleId // Added roleId
                        }));

                        // Update Local Storage
                        localStorage.setItem('auth_user', JSON.stringify({
                            ...storedUser,
                            id: profile.id, // Store string id
                            userId: Number(profile.id), // Store number userId for compatibility
                            name: profile.name,
                            empId: profile.empId,
                            roleId: profile.roleId // Added roleId
                        }));
                    } else if (displayInfo.empId) {
                        // Fallback: Try searching by EmpID
                        console.log('Profile ID missing, trying search by EmpID:', displayInfo.empId);
                        // Lazy import or use global if needed, but here we can just fetch directly since we want to avoid circular deps if any
                        // Or just use the existing request utility
                        const searchRes = await userService.searchUsers(displayInfo.empId); // We will add this to userService
                        if (searchRes && searchRes.length > 0) {
                            const userConfig = searchRes.find(u => u.wxId === displayInfo.empId || u.empId === displayInfo.empId || u.name === displayInfo.name);
                            // The searchUsers in IM returns ImUser which has userId (Long)
                            // Let's assume we add a system search or use the IM one.
                            // IM search returns: { userId, wxId, avatarUrl } mapped from sys_user.
                            const found = userConfig || searchRes[0];
                            if (found && found.userId) {
                                console.log('Resolved ID from search:', found.userId);
                                setDisplayInfo(prev => ({
                                    ...prev,
                                    userId: Number(found.userId),
                                    id: String(found.userId)
                                }));
                                localStorage.setItem('auth_user', JSON.stringify({
                                    ...storedUser,
                                    id: String(found.userId),
                                    userId: Number(found.userId)
                                }));
                            }
                        }
                    }
                } catch (e) {
                    console.error("Failed to auto-fetch profile", e);
                }
            }
        };
        fixMissingId();
    }, [displayInfo.empId]);

    const fileInputRef = useRef<HTMLInputElement>(null);

    const handleAvatarClick = () => {
        fileInputRef.current?.click();
    };

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        try {
            // 1. Upload File
            const url = await userService.uploadFile(file);
            console.log('Uploaded Avatar:', url);

            // 2. Update User Profile
            // Try to get ID
            const storedUserStr = localStorage.getItem('auth_user');
            const storedUser = JSON.parse(storedUserStr || '{}');
            console.log('DEBUG: displayInfo', displayInfo);
            console.log('DEBUG: storedUser', storedUser);

            // Check if storedUser has id (string) or userId (number). usually id for sys user.
            const userId = displayInfo.userId || displayInfo.id || storedUser.id || storedUser.userId;
            console.log('DEBUG: Resolved userId', userId);

            if (userId) {
                await userService.updateProfile({
                    avatarUrl: url
                });

                // 3. Update Local State
                setDisplayInfo(prev => ({ ...prev, avatarUrl: url }));

                // 4. Update Local Storage
                localStorage.setItem('auth_user', JSON.stringify({ ...storedUser, avatarUrl: url }));
                // Force update for other components listening to storage
                window.dispatchEvent(new Event('storage'));

                alert('头像更新成功');
            } else {
                alert('无法获取用户ID，更新失败');
            }
        } catch (error) {
            console.error('Update avatar failed', error);
            alert('头像上传失败');
        }
    };

    return (
        <div className="max-w-4xl mx-auto space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
            {/* Header */}
            <div>
                <h1 className="text-2xl font-bold text-slate-800">基本信息</h1>
                <p className="text-slate-500 mt-1">查看和管理您的个人账户信息</p>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                {/* Banner/Background */}
                <div className="h-32 bg-gradient-to-r from-red-500 to-red-600 relative">
                    <div className="absolute inset-0 bg-black/10"></div>
                </div>

                {/* Profile Header */}
                <div className="px-8 pb-8">
                    <div className="relative flex justify-between items-end -mt-12 mb-6">
                        <div className="relative group">
                            <div className="w-24 h-24 rounded-full bg-white p-1 shadow-lg cursor-pointer" onClick={handleAvatarClick}>
                                <div className="w-full h-full rounded-full bg-slate-100 flex items-center justify-center overflow-hidden relative group-hover:opacity-90 transition-opacity">
                                    {displayInfo.avatarUrl ? (
                                        <img src={displayInfo.avatarUrl} alt={displayInfo.name} className="w-full h-full object-cover" />
                                    ) : (
                                        <User size={40} className="text-slate-400" />
                                    )}
                                </div>
                            </div>
                            <button
                                className="absolute bottom-0 right-0 p-2 bg-white rounded-full shadow-md border border-slate-100 text-slate-500 hover:text-red-600 transition-colors"
                                onClick={handleAvatarClick}
                            >
                                <Camera size={16} />
                            </button>
                            <input
                                type="file"
                                ref={fileInputRef}
                                className="hidden"
                                accept="image/*"
                                onChange={handleFileChange}
                            />
                        </div>
                        <div className="flex gap-3 mb-2">
                            <button className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-medium transition-colors shadow-sm shadow-red-600/20">
                                编辑资料
                            </button>
                        </div>
                    </div>

                    {/* Info Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-x-12 gap-y-8">
                        {/* Name Section */}
                        <div className="col-span-1 md:col-span-2 border-b border-slate-100 pb-6 mb-2">
                            <h2 className="text-xl font-bold text-slate-800">{displayInfo.name || '未命名用户'}</h2>
                            <p className="text-slate-500 flex items-center gap-2 mt-1">
                                <span className="bg-red-50 text-red-600 text-xs px-2 py-0.5 rounded-full font-medium border border-red-100">
                                    {displayInfo.roleName || '普通用户'}
                                </span>
                                <span className="text-slate-300">|</span>
                                <span className="text-sm">员工编号: {displayInfo.empId || 'Unknown'}</span>
                            </p>
                        </div>

                        {/* Detail Fields */}
                        <div className="space-y-4">
                            <div>
                                <label className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1 block">所属部门</label>
                                <div className="flex items-center gap-3 text-slate-700 p-3 bg-slate-50 rounded-lg border border-slate-100">
                                    <Building size={18} className="text-slate-400" />
                                    <span>{displayInfo.department}</span>
                                </div>
                            </div>
                            <div>
                                <label className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1 block">职位/角色</label>
                                <div className="flex items-center gap-3 text-slate-700 p-3 bg-slate-50 rounded-lg border border-slate-100">
                                    <Briefcase size={18} className="text-slate-400" />
                                    <span>{displayInfo.roleName || '暂无'}</span>
                                </div>
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div>
                                <label className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1 block">电子邮箱</label>
                                <div className="flex items-center gap-3 text-slate-700 p-3 bg-slate-50 rounded-lg border border-slate-100">
                                    <Mail size={18} className="text-slate-400" />
                                    <span>{displayInfo.email}</span>
                                </div>
                            </div>
                            <div>
                                <label className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1 block">联系电话</label>
                                <div className="flex items-center gap-3 text-slate-700 p-3 bg-slate-50 rounded-lg border border-slate-100">
                                    <Phone size={18} className="text-slate-400" />
                                    <span>{displayInfo.phone}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default BasicInfo;
