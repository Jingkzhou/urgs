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
    queryTableType?: 'SUMMARY' | 'DETAIL';
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

export interface RegElementQueryConfig {
    id?: number | string;
    regElementId?: number | string;
    enabled?: number;
    queryMode?: 'SUMMARY' | 'DETAIL';
    dataSourceId?: number | string;
    modelTableId?: string;
    dateFieldId?: string;
    orgCodeFieldId?: string;
    orgNameFieldId?: string;
    metricCodeFieldId?: string;
    valueFieldId?: string;
    defaultReturnFieldIds?: string[];
    filterFieldIds?: string[];
    sortFieldIds?: string[];
    maskFieldIds?: string[];
    detailMaxRows?: number;
    analysisConfigJson?: string;
}

export interface RegElementQueryConfigValidationResult {
    valid: boolean;
    errors: string[];
    warnings: string[];
}

export interface RegTableQueryConfig {
    id?: number | string;
    regTableId?: number | string;
    enabled?: number;
    dataSourceId?: number | string;
    modelTableId?: string;
    dateFieldId?: string;
    orgCodeFieldId?: string;
    orgNameFieldId?: string;
    defaultReturnFieldIds?: string[];
    filterFieldIds?: string[];
    sortFieldIds?: string[];
    maskFieldIds?: string[];
    detailMaxRows?: number;
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
