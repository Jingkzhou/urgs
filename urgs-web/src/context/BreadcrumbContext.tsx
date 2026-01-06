import React, { createContext, useContext, useState, ReactNode } from 'react';

export interface BreadcrumbItem {
    id: string;
    label: string;
    onClick?: () => void;
}

interface BreadcrumbContextType {
    items: BreadcrumbItem[];
    setBreadcrumbs: (items: BreadcrumbItem[]) => void;
}

const BreadcrumbContext = createContext<BreadcrumbContextType | undefined>(undefined);

export const BreadcrumbProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [items, setItems] = useState<BreadcrumbItem[]>([]);

    return (
        <BreadcrumbContext.Provider value={{ items, setBreadcrumbs: setItems }}>
            {children}
        </BreadcrumbContext.Provider>
    );
};

export const useBreadcrumbs = () => {
    const context = useContext(BreadcrumbContext);
    if (!context) {
        throw new Error('useBreadcrumbs must be used within a BreadcrumbProvider');
    }
    return context;
};
