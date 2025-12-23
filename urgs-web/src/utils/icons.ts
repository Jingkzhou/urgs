import {
    Shield,
    Database,
    Activity,
    FileText,
    Globe,
    Users,
    BarChart2,
    Lock,
    Server,
    Cloud,
    Code,
    Terminal,
    Settings,
    Box,
    Layers,
    Link,
    Cpu,
    Zap,
    Key,
    Briefcase
} from 'lucide-react';

export const IconRegistry: Record<string, any> = {
    'Shield': Shield,
    'Database': Database,
    'Activity': Activity,
    'FileText': FileText,
    'Globe': Globe,
    'Users': Users,
    'BarChart2': BarChart2,
    'Lock': Lock,
    'Server': Server,
    'Cloud': Cloud,
    'Code': Code,
    'Terminal': Terminal,
    'Settings': Settings,
    'Box': Box,
    'Layers': Layers,
    'Link': Link,
    'Cpu': Cpu,
    'Zap': Zap,
    'Key': Key,
    'Briefcase': Briefcase
};

export const getIcon = (name?: string) => {
    if (!name || !IconRegistry[name]) {
        return Globe; // Default fallback
    }
    return IconRegistry[name];
};
