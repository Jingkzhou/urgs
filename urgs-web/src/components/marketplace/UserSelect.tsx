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
    const selectedValueRef = useRef<string | null>(null);

    const formatUserLabel = (user: UserDTO) => {
        const empId = user.empId || '无工号';
        return `${empId} - ${user.name}`;
    };

    const getUserValue = (user: UserDTO) => {
        return user.id?.toString() || user.empId || '';
    };

    const handleSelectUser = (user: UserDTO) => {
        const nextValue = getUserValue(user);
        if (!nextValue) return;
        setKeyword(formatUserLabel(user));
        selectedValueRef.current = nextValue;
        onChange(nextValue);
        setIsOpen(false);
    };

    useEffect(() => {
        let active = true;
        const resolveSelectedUser = async () => {
            if (!value) {
                setKeyword('');
                selectedValueRef.current = null;
                return;
            }
            if (selectedValueRef.current === value.toString()) {
                return;
            }
            try {
                const results = await searchUsers(value.toString());
                if (!active) return;
                const matchedUser = results.find(user => getUserValue(user) === value.toString());
                setKeyword(matchedUser ? formatUserLabel(matchedUser) : value.toString());
            } catch (error) {
                if (active) {
                    setKeyword(value.toString());
                }
            }
        };
        resolveSelectedUser();
        return () => {
            active = false;
        };
    }, [value]);

    const getSearchKeyword = () => {
        if (keyword.includes(' - ')) {
            return keyword.split(' - ')[1] || keyword.split(' - ')[0];
        }
        return keyword;
    };

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
                const results = await searchUsers(getSearchKeyword());
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
                placeholder="输入工号、姓名或机构名称模糊搜索..."
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
                                    key={getUserValue(user)}
                                    className="px-3 py-2 hover:bg-slate-50 cursor-pointer text-sm flex items-center justify-between"
                                    onMouseDown={(event) => {
                                        event.preventDefault();
                                        handleSelectUser(user);
                                    }}
                                >
                                    <div className="flex flex-col">
                                        <span className="font-bold text-slate-800">{user.empId || '无工号'} - {user.name}</span>
                                        <span className="text-xs text-slate-500">{user.orgName || '暂无机构信息'}</span>
                                    </div>
                                    <span className="text-xs text-slate-400">{user.roleName || '暂无角色'}</span>
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
