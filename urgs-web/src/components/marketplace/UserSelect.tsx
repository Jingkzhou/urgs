import React, { useState, useEffect, useRef } from 'react';
import { searchUsers, UserDTO } from '../../api/user';

interface UserSelectProps {
    value?: string;
    onChange: (value: string) => void;
}

const UserSelect: React.FC<UserSelectProps> = ({ value, onChange }) => {
    const [keyword, setKeyword] = useState('');
    const [users, setUsers] = useState<UserDTO[]>([]);
    const [isOpen, setIsOpen] = useState(false);
    const [loading, setLoading] = useState(false);
    const wrapperRef = useRef<HTMLDivElement>(null);

    // If an initial value exists from parent Form, and we only know the ID
    // ideally we'd look it up. But mostly this is for new creation so it's empty.
    useEffect(() => {
        if (value && !keyword) {
            setKeyword(value.toString());
        }
    }, []);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    useEffect(() => {
        let active = true;
        const fetchUsers = async () => {
            setLoading(true);
            try {
                // If keyword matches the `Name (Org)` format, we likely just clicked it,
                // so don't search that whole string as the keyword.
                const searchStr = keyword.includes('(') ? keyword.split(' (')[0] : keyword;
                const results = await searchUsers(searchStr);
                if (active) {
                    setUsers(results);
                }
            } catch (error) {
                console.error('Failed to search users', error);
            } finally {
                if (active) setLoading(false);
            }
        };

        if (isOpen) {
            const timer = setTimeout(fetchUsers, 300); // 300ms debounce
            return () => {
                active = false;
                clearTimeout(timer);
            };
        }
    }, [keyword, isOpen]);

    return (
        <div ref={wrapperRef} className="relative w-full">
            <input
                type="text"
                className="w-full px-3 py-1.5 border border-slate-200 bg-blue-50/50 rounded-lg text-sm focus:ring-1 focus:ring-red-500 focus:border-red-500 outline-none"
                placeholder="输入人名或机构名称模糊搜索..."
                value={keyword}
                onClick={() => setIsOpen(true)}
                onChange={(e) => {
                    setKeyword(e.target.value);
                    setIsOpen(true);
                    if (!e.target.value) {
                        onChange('');
                    }
                }}
            />
            {isOpen && (
                <div className="absolute z-10 w-full mt-1 bg-white rounded-md shadow-lg border border-slate-200 max-h-60 overflow-auto">
                    {loading ? (
                        <div className="p-3 text-sm text-slate-500 text-center">搜索中...</div>
                    ) : users.length === 0 ? (
                        <div className="p-3 text-sm text-slate-500 text-center">无匹配结果</div>
                    ) : (
                        <ul className="py-1">
                            {users.map((user) => (
                                <li
                                    key={user.id}
                                    className="px-3 py-2 hover:bg-slate-50 cursor-pointer text-sm flex items-center justify-between"
                                    onClick={() => {
                                        setKeyword(`${user.name} (${user.orgName || '无机构'})`);
                                        onChange(user.id.toString());
                                        setIsOpen(false);
                                    }}
                                >
                                    <div className="flex flex-col">
                                        <span className="font-bold text-slate-800">{user.name}</span>
                                        <span className="text-xs text-slate-500">{user.orgName || '暂无机构信息'}</span>
                                    </div>
                                    <span className="text-xs text-slate-400 font-mono">ID: {user.id}</span>
                                </li>
                            ))}
                        </ul>
                    )}
                </div>
            )}
        </div>
    );
};

export default UserSelect;
