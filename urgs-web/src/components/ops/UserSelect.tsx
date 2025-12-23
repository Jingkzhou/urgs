import React, { useState, useEffect, useRef } from 'react';
import { Search, User as UserIcon, X } from 'lucide-react';

interface User {
    id: number;
    empId: string;
    name: string;
    orgName: string;
}

interface UserSelectProps {
    value?: string;
    onChange: (value: string) => void;
    placeholder?: string;
    className?: string;
}

const UserSelect: React.FC<UserSelectProps> = ({ value, onChange, placeholder, className }) => {
    const [query, setQuery] = useState(value || '');
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(false);
    const [showDropdown, setShowDropdown] = useState(false);
    const dropdownRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        setQuery(value || '');
    }, [value]);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
                setShowDropdown(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const fetchUsers = async (keyword: string) => {
        if (!keyword) {
            setUsers([]);
            return;
        }
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/users?keyword=${encodeURIComponent(keyword)}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setUsers(data);
                setShowDropdown(true);
            }
        } catch (error) {
            console.error('Failed to fetch users:', error);
        } finally {
            setLoading(false);
        }
    };

    // Debounce search
    useEffect(() => {
        const timer = setTimeout(() => {
            if (query && showDropdown) { // Only search if we want to show dropdown
                // Actually we want to search when user types. 
                // But if query matches value, we might not want to search if it's already selected.
                // Simple logic: input change -> search.
                // But we need to distinguish typing vs selecting.
            }
        }, 300);
        return () => clearTimeout(timer);
    }, [query]);

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const val = e.target.value;
        setQuery(val);
        onChange(val); // Update parent immediately as text
        if (val.trim()) {
            // Simple debounce here or use effect? 
            // Let's call fetch directly with small valid check, but debouncing is better.
            // For simplicity in this tool interaction, I'll use a timeout ref or just let it fire (if traffic low).
            // Let's implementation proper debounce manually.
        } else {
            setUsers([]);
            setShowDropdown(false);
        }
    };

    // Debounce implementation for input
    const timeoutRef = useRef<any>(null);
    const onInput = (e: React.ChangeEvent<HTMLInputElement>) => {
        const val = e.target.value;
        setQuery(val);
        onChange(val);

        if (timeoutRef.current) clearTimeout(timeoutRef.current);

        if (val.trim()) {
            timeoutRef.current = setTimeout(() => {
                fetchUsers(val);
            }, 300);
        } else {
            setUsers([]);
            setShowDropdown(false);
        }
    };

    const handleSelect = (user: User) => {
        const newValue = `${user.name} (${user.empId})`;
        setQuery(newValue);
        onChange(newValue);
        setShowDropdown(false);
    };

    const handleFocus = () => {
        if (query) {
            fetchUsers(query);
        }
    };

    return (
        <div className={`relative ${className}`} ref={dropdownRef}>
            <div className="relative">
                <input
                    type="text"
                    className="w-full border border-slate-300 rounded-md pl-3 pr-8 py-2 text-sm focus:ring-2 focus:ring-red-500 outline-none"
                    value={query}
                    onChange={onInput}
                    onFocus={handleFocus}
                    placeholder={placeholder}
                />
                <Search className="absolute right-2 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            </div>

            {showDropdown && users.length > 0 && (
                <div className="absolute z-50 w-full mt-1 bg-white border border-slate-200 rounded-md shadow-lg max-h-60 overflow-y-auto">
                    {users.map(user => (
                        <div
                            key={user.id}
                            className="px-3 py-2 text-sm hover:bg-slate-50 cursor-pointer flex items-center justify-between"
                            onClick={() => handleSelect(user)}
                        >
                            <div className="flex items-center gap-2">
                                <div className="w-6 h-6 bg-slate-100 rounded-full flex items-center justify-center text-xs text-slate-500">
                                    {user.name.charAt(0)}
                                </div>
                                <div>
                                    <div className="font-medium text-slate-800">{user.name}</div>
                                    <div className="text-xs text-slate-400">{user.empId}</div>
                                </div>
                            </div>
                            <div className="text-xs text-slate-400">{user.orgName}</div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default UserSelect;
