import React, { useRef, useState } from 'react';
import { User, Phone, Building, Briefcase, Camera, Shield, KeyRound } from 'lucide-react';
import { userService } from '../services/userService';

const DEFAULT_AVATARS = ['avatar', 'animal-avatar'].flatMap(prefix =>
    Array.from(
        { length: 10 },
        (_, index) => `/avatars/default/${prefix}-${String(index + 1).padStart(2, '0')}.png`
    )
);

interface UserInfo {
    name?: string;
    empId?: string;
    roleName?: string;
    phone?: string;
    department?: string;
    orgName?: string;
    avatarUrl?: string; // Should come from SysUser now
    userId?: number;
    id?: string; // SysUser uses string ID in DTO usually, check
    roleId?: number; // Added roleId
}

const BasicInfo: React.FC<{ userInfo: UserInfo | null }> = ({ userInfo }) => {
    // Mock extended info if not present
    const [displayInfo, setDisplayInfo] = useState({
        ...userInfo,
        phone: userInfo?.phone || '暂无联系电话',
        department: userInfo?.orgName || userInfo?.department || '暂无机构信息',
    });
    const [isSavingAvatar, setIsSavingAvatar] = useState(false);
    const [gitTokenPlatform, setGitTokenPlatform] = useState<'gitee' | 'gitlab' | 'github'>('gitlab');
    const [gitAccessToken, setGitAccessToken] = useState('');
    const [gitTokenStatus, setGitTokenStatus] = useState<Partial<Record<'gitee' | 'gitlab' | 'github', boolean>>>({});
    const [gitIdentity, setGitIdentity] = useState({ gitUsername: '', gitEmail: '', gitUserId: '' });
    const [isSavingGitConfig, setIsSavingGitConfig] = useState(false);

    const loadGitTokenStatus = async () => {
        try {
            setGitTokenStatus(await userService.getGitTokenStatus());
        } catch (error) {
            console.error('Load Git token status failed', error);
        }
    };

    React.useEffect(() => {
        loadGitTokenStatus();
        userService.getMyGitIdentity()
            .then(identity => {
                if (identity) {
                    setGitIdentity({
                        gitUsername: identity.gitUsername || '',
                        gitEmail: identity.gitEmail || '',
                        gitUserId: identity.gitUserId || '',
                    });
                }
            })
            .catch(error => console.error('Load Git identity failed', error));
    }, []);

    // Auto-fix missing ID
    React.useEffect(() => {
        const fixMissingId = async () => {
            const storedUser = JSON.parse(localStorage.getItem('auth_user') || '{}');
            const currentId = displayInfo.userId || displayInfo.id || storedUser.id || storedUser.userId;

            if (!currentId || !userInfo?.orgName || !userInfo?.phone || !userInfo?.avatarUrl) {
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
                            roleId: profile.roleId,
                            department: profile.orgName || '暂无机构信息',
                            phone: profile.phone || '暂无联系电话',
                            avatarUrl: profile.avatarUrl
                        }));

                        // Update Local Storage
                        localStorage.setItem('auth_user', JSON.stringify({
                            ...storedUser,
                            id: profile.id, // Store string id
                            userId: Number(profile.id), // Store number userId for compatibility
                            name: profile.name,
                            empId: profile.empId,
                            roleId: profile.roleId,
                            orgName: profile.orgName,
                            phone: profile.phone,
                            avatarUrl: profile.avatarUrl
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
        if (isSavingAvatar) return;
        fileInputRef.current?.click();
    };

    const saveAvatar = async (avatarUrl: string, successMessage: string) => {
        setIsSavingAvatar(true);
        try {
            await userService.updateProfile({ avatarUrl });
            setDisplayInfo(prev => ({ ...prev, avatarUrl }));

            const storedUser = JSON.parse(localStorage.getItem('auth_user') || '{}');
            localStorage.setItem('auth_user', JSON.stringify({ ...storedUser, avatarUrl }));
            alert(successMessage);
        } catch (error) {
            console.error('Update avatar failed', error);
            alert('头像设置失败');
        } finally {
            setIsSavingAvatar(false);
        }
    };

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        setIsSavingAvatar(true);
        try {
            const url = await userService.uploadFile(file);
            await userService.updateProfile({ avatarUrl: url });
            setDisplayInfo(prev => ({ ...prev, avatarUrl: url }));

            const storedUser = JSON.parse(localStorage.getItem('auth_user') || '{}');
            localStorage.setItem('auth_user', JSON.stringify({ ...storedUser, avatarUrl: url }));
            alert('头像上传成功');
        } catch (error) {
            console.error('Update avatar failed', error);
            alert('头像上传失败');
        } finally {
            setIsSavingAvatar(false);
            e.target.value = '';
        }
    };

    const saveGitConfig = async () => {
        const hasIdentity = Object.values(gitIdentity).some(value => value.trim());
        const hasToken = Boolean(gitAccessToken.trim());
        if (!hasIdentity && !hasToken) {
            alert('请至少填写 Git 身份或访问令牌');
            return;
        }
        setIsSavingGitConfig(true);
        try {
            if (gitTokenPlatform === 'gitlab') {
                await userService.saveMyGitIdentity(gitIdentity);
            }
            if (hasToken) {
                await userService.saveGitToken(gitTokenPlatform, gitAccessToken.trim());
            }
            setGitAccessToken('');
            await loadGitTokenStatus();
            alert('Git 配置已保存');
        } catch (error) {
            console.error('Save Git config failed', error);
            alert('Git 配置保存失败');
        } finally {
            setIsSavingGitConfig(false);
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
                                className={`w-32 h-32 rounded-[2.5rem] bg-white p-1.5 shadow-2xl relative z-10 overflow-hidden transition-transform duration-500 ${isSavingAvatar ? 'cursor-wait opacity-70' : 'cursor-pointer group-hover/avatar:scale-105'}`}
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
                    </div>

                    <div className="mb-10 rounded-[1.75rem] border border-slate-100 bg-slate-50/70 p-5">
                        <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
                            <div>
                                <h3 className="text-sm font-black text-slate-700">选择默认头像</h3>
                                <p className="mt-1 text-[10px] font-bold uppercase tracking-widest text-slate-400">点击头像即可保存</p>
                            </div>
                            <button
                                type="button"
                                disabled={isSavingAvatar}
                                onClick={handleAvatarClick}
                                className="flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2 text-xs font-black text-slate-600 shadow-sm transition-all hover:border-red-200 hover:text-red-500 disabled:cursor-wait disabled:opacity-50"
                            >
                                <Camera size={15} />
                                上传本地图片
                            </button>
                        </div>
                        <div className="grid grid-cols-5 gap-3 md:grid-cols-10">
                            {DEFAULT_AVATARS.map((avatarUrl, index) => {
                                const isSelected = displayInfo.avatarUrl === avatarUrl;
                                return (
                                    <button
                                        key={avatarUrl}
                                        type="button"
                                        disabled={isSavingAvatar}
                                        onClick={() => saveAvatar(avatarUrl, '默认头像设置成功')}
                                        aria-label={`选择默认头像 ${index + 1}`}
                                        className={`aspect-square overflow-hidden rounded-xl border-2 bg-white p-0.5 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md disabled:cursor-wait disabled:opacity-50 ${
                                            isSelected
                                                ? 'border-red-500 ring-2 ring-red-500/15'
                                                : 'border-white hover:border-red-200'
                                        }`}
                                    >
                                        <img
                                            src={avatarUrl}
                                            alt={`默认头像 ${index + 1}`}
                                            className="h-full w-full rounded-[0.55rem] object-cover"
                                        />
                                    </button>
                                );
                            })}
                        </div>
                    </div>

                    <div className="mt-6 rounded-[1.75rem] border border-slate-100 bg-slate-50/70 p-5">
                        <div className="mb-4 flex items-center gap-3">
                            <div className="rounded-xl bg-white p-3 text-red-500 shadow-sm">
                                <KeyRound size={20} />
                            </div>
                            <div>
                                <h3 className="text-sm font-black text-slate-700">Git 身份与仓库访问令牌</h3>
                                <p className="mt-1 text-xs text-slate-400">身份仅由本人维护；访问令牌按平台保存，用于访问共享仓库。</p>
                            </div>
                        </div>
                        <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                            <select
                                value={gitTokenPlatform}
                                onChange={(event) => setGitTokenPlatform(event.target.value as 'gitee' | 'gitlab' | 'github')}
                                className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none focus:border-red-300"
                            >
                                <option value="gitee">Gitee</option>
                                <option value="gitlab">GitLab</option>
                                <option value="github">GitHub</option>
                            </select>
                            {gitTokenPlatform === 'gitlab' && (
                                <>
                                    <input
                                        value={gitIdentity.gitUsername}
                                        onChange={(event) => setGitIdentity(prev => ({ ...prev, gitUsername: event.target.value }))}
                                        placeholder="GitLab 用户名，如 liudan"
                                        className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-red-300"
                                    />
                                    <input
                                        type="email"
                                        value={gitIdentity.gitEmail}
                                        onChange={(event) => setGitIdentity(prev => ({ ...prev, gitEmail: event.target.value }))}
                                        placeholder="提交邮箱，如 liudan@example.com"
                                        className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-red-300"
                                    />
                                    <input
                                        value={gitIdentity.gitUserId}
                                        onChange={(event) => setGitIdentity(prev => ({ ...prev, gitUserId: event.target.value }))}
                                        placeholder="Git 用户ID（可选）"
                                        className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-red-300"
                                    />
                                </>
                            )}
                            <input
                                type="password"
                                value={gitAccessToken}
                                onChange={(event) => setGitAccessToken(event.target.value)}
                                placeholder={gitTokenStatus[gitTokenPlatform] ? '已配置，输入新令牌可覆盖' : '请输入 Access Token'}
                                className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-red-300"
                            />
                            <button
                                type="button"
                                onClick={saveGitConfig}
                                disabled={isSavingGitConfig}
                                className="rounded-xl bg-red-500 px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-red-600 disabled:cursor-wait disabled:opacity-60 md:col-span-2"
                            >
                                {isSavingGitConfig ? '保存中...' : '保存 Git 配置'}
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
