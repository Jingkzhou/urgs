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
    documentNo?: string;

    effectiveDate?: string;
    businessCaliber?: string;
    devNotes?: string;
    owner?: string;
    status?: number;
    reqId?: string;
    plannedDate?: string;
    changeDescription?: string;
    fieldCount?: number;
    indicatorCount?: number;
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
    length?: number;
    isPk?: number;
    nullable?: number;
    formula?: string;
    fetchSql?: string;
    codeSnippet?: string;
    codeTableCode?: string;
    valueRange?: string;
    validationRule?: string;
    documentNo?: string;

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
}
