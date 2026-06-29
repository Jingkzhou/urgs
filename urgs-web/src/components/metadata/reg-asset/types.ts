export interface Stats {
    tableCount: number;
    onlineCount: number;
    developingCount: number;
    notStartedCount: number;
    elementCount: number;
    fieldCount: number;
    indicatorCount: number;
}

export interface RegTable {
    id?: number | string;
    name: string;
    cnName: string;
    sortOrder?: number;
    systemCode: string;
    subjectCode?: string;
    subjectName?: string;
    theme?: string;
    frequency?: string;
    sourceType?: string;
    autoFetchStatus?: string;
    dispatchNo?: string;

    effectiveDate?: string;
    businessCaliber?: string;
    fillInstruction?: string;
    devNotes?: string;
    owner?: string;
    status?: number;
    reqId?: string;
    plannedDate?: string;
    changeDescription?: string;
    fieldCount?: number;
    indicatorCount?: number;
    physicalTables?: PhysicalTableBinding[];
}

export interface CodeTable {
    id: string;
    tableCode: string;
    tableName: string;
    systemCode?: string;
    autoFetchStatus?: string;
}

export interface CodeDirectoryItem {
    id?: string;
    tableCode: string;
    tableName: string;
    sortOrder?: number;
    code: string;
    name: string;
    parentCode?: string;
    level?: string;
    description?: string;
    startDate?: string;
    endDate?: string;
    standard?: string;
    systemCode?: string;
}

export interface CodeDirectoryChange {
    operation: 'CREATE' | 'UPDATE' | 'DELETE';
    data: CodeDirectoryItem;
}

export interface RegElement {
    id?: number | string;
    tableId: number | string;
    type: 'FIELD' | 'INDICATOR';
    name: string;
    cnName?: string;
    dataType?: string;
    length?: string;
    isDesensitized?: number;
    desensitizeType?: string;
    isPk?: number;
    nullable?: number;
    formula?: string;
    fetchSql?: string;
    codeSnippet?: string;
    codeTableCode?: string;
    valueRange?: string;
    validationRule?: string;
    dispatchNo?: string;

    effectiveDate?: string;
    businessCaliber?: string;
    fillInstruction?: string;
    devNotes?: string;
    autoFetchStatus?: string;
    owner?: string;
    status?: number;
    sortOrder?: number;
    isInit?: number;
    isMergeFormula?: number;
    isFillBusiness?: number;
    reqId?: string;
    plannedDate?: string;
    changeDescription?: string;
    physicalFields?: PhysicalFieldBinding[];
}

export interface PhysicalTableBinding {
    modelTableId: string;
    dataSourceId?: number;
    owner?: string;
    tableName: string;
    tableCnName?: string;
}

export interface PhysicalFieldBinding {
    modelFieldId: string;
    modelTableId: string;
    dataSourceId?: number;
    owner?: string;
    tableName: string;
    tableCnName?: string;
    fieldName: string;
    fieldCnName?: string;
    fieldType?: string;
}
