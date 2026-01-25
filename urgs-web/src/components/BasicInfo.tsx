import React, { useRef, useState } from 'react';
import { User, Mail, Phone, Building, Briefcase, Camera, Shield, RefreshCw } from 'lucide-react';
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
            const userId = displayInfo.userId || displayInfo.id;
            if (userId) {
                await userService.updateProfile({
                    avatarUrl: url
                });

                // 3. Update Local State
                setDisplayInfo(prev => ({ ...prev, avatarUrl: url }));
                alert('头像更新成功');
            }
        } catch (error) {
            console.error('Update avatar failed', error);
            alert('头像上传失败');
        }
    };




    return (
        <div className="max-w-4xl mx-auto space-y-10 animate-in fade-in slide-in-from-bottom-6 duration-700">
            {/* Header Section */}
            <div className="flex justify-between items-end px-2">
                <div>
                    <h1 className="text-3xl font-black text-slate-800 tracking-tighter italic uppercase">基本信息</h1>
                    <p className="text-[11px] text-slate-400 font-black uppercase tracking-[0.2em] mt-2 opacity-70">Personal Profile & Identity v2.0</p>
                </div>
                <div className="flex gap-3">
                    <button className="px-6 py-2.5 bg-slate-900 text-white rounded-xl text-[11px] font-black uppercase tracking-widest hover:bg-black transition-all active:scale-95 shadow-xl shadow-slate-900/10">
                        更新账户
                    </button>
                </div>
            </div>

            <div className="bg-white/65 backdrop-blur-3xl rounded-[3rem] shadow-[0_30px_70px_-15px_rgba(0,0,0,0.12)] border border-white/60 overflow-hidden relative group/profile">
                {/* Banner Background with Tech Pattern */}
                <div className="h-44 bg-gradient-to-br from-red-600 via-red-500 to-rose-700 relative overflow-hidden">
                    <div className="absolute inset-0 opacity-20 bg-[radial-gradient(#fff_1px,transparent_1px)] [background-size:20px_20px] [mask-image:linear-gradient(to_bottom,white,transparent)]"></div>
                    <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent"></div>
                    <div className="absolute top-0 right-0 p-8">
                        <Shield className="text-white/20 w-32 h-32 -rotate-12 translate-x-8 -translate-y-8" strokeWidth={1} />
                    </div>
                </div>

                {/* Profile Body */}
                <div className="px-10 pb-12 relative">
                    <div className="flex flex-col md:flex-row justify-between items-start md:items-end -mt-16 mb-10 gap-6">
                        <div className="relative group/avatar">
                            <div
                                className="w-32 h-32 rounded-[2.5rem] bg-white p-1.5 shadow-2xl cursor-pointer relative z-10 overflow-hidden group-hover/avatar:scale-105 transition-transform duration-500"
                                onClick={handleAvatarClick}
                            >
                                <div className="w-full h-full rounded-[2rem] bg-slate-100 flex items-center justify-center overflow-hidden relative shadow-inner">
                                    {displayInfo.avatarUrl ? (
                                        <img src={displayInfo.avatarUrl} alt={displayInfo.name} className="w-full h-full object-cover group-hover/avatar:scale-110 transition-transform duration-700" />
                                    ) : (
                                        <User size={48} className="text-slate-300" />
                                    )}
                                    <div className="absolute inset-0 bg-black/40 opacity-0 group-hover/avatar:opacity-100 transition-opacity flex items-center justify-center">
                                        <Camera className="text-white w-8 h-8 scale-75 group-hover/avatar:scale-100 transition-transform duration-500" />
                                    </div>
                                </div>
                            </div>
                            {/* Ambient Glow behind avatar */}
                            <div className="absolute -inset-4 bg-red-500/20 rounded-full blur-2xl opacity-0 group-hover/avatar:opacity-100 transition-opacity duration-700"></div>

                            <input
                                type="file"
                                ref={fileInputRef}
                                className="hidden"
                                accept="image/*"
                                onChange={handleFileChange}
                            />
                        </div>

                        <div className="flex-1 md:mb-2">
                            <h2 className="text-4xl font-black text-slate-900 tracking-tighter italic uppercase mb-2">
                                {displayInfo.name || '未命名用户'}
                            </h2>
                            <div className="flex flex-wrap items-center gap-3">
                                <span className="bg-red-500 text-white text-[10px] px-3 py-1 rounded-full font-black uppercase tracking-widest shadow-lg shadow-red-500/20 border border-red-400">
                                    {displayInfo.roleName || '普通用户'}
                                </span>
                                <span className="w-1.5 h-1.5 rounded-full bg-slate-300"></span>
                                <span className="text-[11px] font-black text-slate-400 uppercase tracking-widest">
                                    ID: <span className="font-mono text-slate-600">{displayInfo.empId || 'UNKNOWN'}</span>
                                </span>
                            </div>
                        </div>

                        <div className="flex gap-3 md:mb-2 w-full md:w-auto">
                            <button className="flex-1 md:flex-none px-8 py-3 bg-white hover:bg-slate-50 text-slate-700 rounded-2xl text-[11px] font-black uppercase tracking-widest border border-slate-200 shadow-xl shadow-black/[0.03] transition-all hover:-translate-y-1 active:scale-95">
                                编辑公开资料
                            </button>
                        </div>
                    </div>

                    {/* Information Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        {/* Section Left */}
                        <div className="space-y-4">
                            <div className="group/field">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.25em] mb-2 px-1 block">所属部门 / Organization</label>
                                <div className="flex items-center gap-4 p-5 bg-slate-50/50 hover:bg-white rounded-[1.5rem] border border-slate-100 group-hover/field:border-red-500/30 group-hover/field:shadow-xl group-hover/field:shadow-black/[0.03] transition-all duration-500">
                                    <div className="p-3 bg-white rounded-xl shadow-sm text-slate-400 group-hover/field:text-red-500 transition-colors">
                                        <Building size={20} strokeWidth={2.5} />
                                    </div>
                                    <div className="flex flex-col">
                                        <span className="text-[11px] text-slate-400 font-bold uppercase tracking-wider mb-0.5">Department</span>
                                        <span className="text-sm font-black text-slate-700 truncate">{displayInfo.department}</span>
                                    </div>
                                </div>
                            </div>

                            <div className="group/field">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.25em] mb-2 px-1 block">职位描述 / Designation</label>
                                <div className="flex items-center gap-4 p-5 bg-slate-50/50 hover:bg-white rounded-[1.5rem] border border-slate-100 group-hover/field:border-red-500/30 group-hover/field:shadow-xl group-hover/field:shadow-black/[0.03] transition-all duration-500">
                                    <div className="p-3 bg-white rounded-xl shadow-sm text-slate-400 group-hover/field:text-red-500 transition-colors">
                                        <Briefcase size={20} strokeWidth={2.5} />
                                    </div>
                                    <div className="flex flex-col">
                                        <span className="text-[11px] text-slate-400 font-bold uppercase tracking-wider mb-0.5">Job Title</span>
                                        <span className="text-sm font-black text-slate-700 uppercase">{displayInfo.roleName || '暂无'}</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Section Right */}
                        <div className="space-y-4">
                            <div className="group/field">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.25em] mb-2 px-1 block">电子邮箱 / Email Address</label>
                                <div className="flex items-center gap-4 p-5 bg-slate-50/50 hover:bg-white rounded-[1.5rem] border border-slate-100 group-hover/field:border-red-500/30 group-hover/field:shadow-xl group-hover/field:shadow-black/[0.03] transition-all duration-500">
                                    <div className="p-3 bg-white rounded-xl shadow-sm text-slate-400 group-hover/field:text-red-500 transition-colors">
                                        <Mail size={20} strokeWidth={2.5} />
                                    </div>
                                    <div className="flex flex-col">
                                        <span className="text-[11px] text-slate-400 font-bold uppercase tracking-wider mb-0.5">Work Email</span>
                                        <span className="text-sm font-black text-slate-700">{displayInfo.email}</span>
                                    </div>
                                    <button className="ml-auto p-2 opacity-0 group-hover/field:opacity-100 bg-slate-50 rounded-lg text-slate-400 hover:text-red-500 transition-all">
                                        <RefreshCw size={14} />
                                    </button>
                                </div>
                            </div>

                            <div className="group/field">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.25em] mb-2 px-1 block">联系电话 / Contact Number</label>
                                <div className="flex items-center gap-4 p-5 bg-slate-50/50 hover:bg-white rounded-[1.5rem] border border-slate-100 group-hover/field:border-red-500/30 group-hover/field:shadow-xl group-hover/field:shadow-black/[0.03] transition-all duration-500">
                                    <div className="p-3 bg-white rounded-xl shadow-sm text-slate-400 group-hover/field:text-red-500 transition-colors">
                                        <Phone size={20} strokeWidth={2.5} />
                                    </div>
                                    <div className="flex flex-col">
                                        <span className="text-[11px] text-slate-400 font-bold uppercase tracking-wider mb-0.5">Mobile Phone</span>
                                        <span className="text-sm font-black text-slate-700">{displayInfo.phone}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Footer Decor */}
                <div className="bg-slate-50/80 px-10 py-5 border-t border-slate-100/50 flex justify-between items-center relative z-10">
                    <div className="flex items-center gap-2">
                        <Shield size={14} className="text-emerald-500" />
                        <span className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em]">Verified Employee Account</span>
                    </div>
                    <span className="text-[9px] font-mono text-slate-300">Last seen: {new Date().toLocaleDateString()}</span>
                </div>
            </div>
        </div>
    );
};

export default BasicInfo;
