import React, { useState, useEffect } from 'react';
import DataXForm from './forms/DataXForm';
import HttpForm from './forms/HttpForm';
import SqlForm from './forms/SqlForm';
import ScriptForm from './forms/ScriptForm';
import ProcedureForm from './forms/ProcedureForm';
import DependentForm from './forms/DependentForm';

interface TaskConfigFormProps {
    data: any;
    type: string;
    onChange: (data: any) => void;
    availableTasks?: { label: string; value: string }[]; // List of other tasks
}

const TaskConfigForm: React.FC<TaskConfigFormProps> = ({ data, type, onChange, availableTasks = [] }) => {
    const [formData, setFormData] = useState<any>(data || {});
    const [isMaximized, setIsMaximized] = useState(false);

    useEffect(() => {
        setFormData(data || {});
    }, [data]);

    const handleChange = (field: string | Record<string, any>, value?: any) => {
        let newData;
        if (typeof field === 'string') {
            newData = { ...formData, [field]: value };
        } else {
            newData = { ...formData, ...field };
        }
        setFormData(newData);
        onChange(newData);
    };

    const handleParamChange = (index: number, key: string, value: string) => {
        const newParams = [...(formData.localParams || [])];
        newParams[index] = { ...newParams[index], [key]: value };
        handleChange('localParams', newParams);
    };

    const addParam = () => {
        handleChange('localParams', [...(formData.localParams || []), { prop: '', value: '' }]);
    };

    const removeParam = (index: number) => {
        const newParams = [...(formData.localParams || [])];
        newParams.splice(index, 1);
        handleChange('localParams', newParams);
    };

    const toggleMaximize = () => {
        setIsMaximized(!isMaximized);
    };

    const commonProps = {
        formData,
        handleChange,
        isMaximized,
        toggleMaximize,
        availableTasks // Pass down to child forms
    };

    // Render Form based on Type
    if (type === 'DataX' || type === 'DATAX') {
        return <DataXForm {...commonProps} />;
    }

    if (type === 'HTTP') {
        return <HttpForm {...commonProps} />;
    }

    if (type === 'SQL') {
        return (
            <SqlForm
                {...commonProps}
                handleParamChange={handleParamChange}
                addParam={addParam}
                removeParam={removeParam}
            />
        );
    }

    if (type === 'PROCEDURE') {
        return (
            <ProcedureForm
                {...commonProps}
                handleParamChange={handleParamChange}
                addParam={addParam}
                removeParam={removeParam}
            />
        );
    }

    if (type === 'DEPENDENT') {
        return <DependentForm {...commonProps} />;
    }

    // Default to ScriptForm (SHELL, PYTHON, etc.)
    return (
        <ScriptForm
            {...commonProps}
            type={type || 'SHELL'}
            handleParamChange={handleParamChange}
            addParam={addParam}
            removeParam={removeParam}
        />
    );
};

export default TaskConfigForm;
