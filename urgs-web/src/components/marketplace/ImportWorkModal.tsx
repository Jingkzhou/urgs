import React from 'react';
import * as XLSX from 'xlsx';
import { AlertCircle, CheckCircle2, Download, FileSpreadsheet, Upload, X } from 'lucide-react';
import { message } from 'antd';
import { importWorks, WorkImportDTO } from '../../api/marketplace';

const TEMPLATE_HEADERS = [
    '工作名称',
    '详细描述',
    '优先级',
    '截止日期',
    '需求编号',
    '申请部门',
    '申请人',
    '归属系统',
    '是否主系统',
    '主系统名称',
    '项目类型',
] as const;

const REQUIRED_HEADERS = [
    '工作名称',
    '详细描述',
    '优先级',
    '申请部门',
    '申请人',
    '归属系统',
    '是否主系统',
    '项目类型',
];

const TEMPLATE_COLUMN_WIDTHS = [24, 42, 12, 20, 18, 18, 14, 22, 14, 22, 14];
const PRIORITIES = ['P0', 'P1', 'P2', 'P3'] as const;
const PROJECT_TYPES = ['变更类', '仅配合'] as const;

interface ImportWorkModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
}

interface ParsedWorkRow {
    rowNumber: number;
    data?: WorkImportDTO;
    errors: string[];
}

type TemplateRow = Record<string, unknown>;

const toText = (value: unknown) => {
    if (value === null || value === undefined) return '';
    return String(value).trim();
};

const pad = (value: number) => String(value).padStart(2, '0');

const formatLocalDateTime = (
    year: number,
    month: number,
    day: number,
    hour = 0,
    minute = 0,
    second = 0
) => {
    const date = new Date(year, month - 1, day, hour, minute, second);
    if (
        date.getFullYear() !== year
        || date.getMonth() !== month - 1
        || date.getDate() !== day
        || date.getHours() !== hour
        || date.getMinutes() !== minute
        || date.getSeconds() !== second
    ) {
        return null;
    }
    return `${year}-${pad(month)}-${pad(day)}T${pad(hour)}:${pad(minute)}:${pad(second)}`;
};

const parseDeadline = (value: unknown) => {
    if (value === null || value === undefined || value === '') return undefined;

    if (value instanceof Date && !Number.isNaN(value.getTime())) {
        return formatLocalDateTime(
            value.getFullYear(),
            value.getMonth() + 1,
            value.getDate(),
            value.getHours(),
            value.getMinutes(),
            value.getSeconds()
        );
    }

    if (typeof value === 'number') {
        const parsed = XLSX.SSF.parse_date_code(value);
        if (!parsed) return null;
        return formatLocalDateTime(parsed.y, parsed.m, parsed.d, parsed.H, parsed.M, Math.floor(parsed.S));
    }

    const text = toText(value);
    const match = text.match(
        /^(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:[ T](\d{1,2})(?::(\d{1,2}))?(?::(\d{1,2}))?)?$/
    );
    if (!match) return null;
    return formatLocalDateTime(
        Number(match[1]),
        Number(match[2]),
        Number(match[3]),
        Number(match[4] || 0),
        Number(match[5] || 0),
        Number(match[6] || 0)
    );
};

const parsePrimarySystem = (value: unknown) => {
    if (typeof value === 'boolean') return value;
    if (value === 1) return true;
    if (value === 0) return false;

    const text = toText(value).toLowerCase();
    if (['是', 'true', '1'].includes(text)) return true;
    if (['否', 'false', '0'].includes(text)) return false;
    return null;
};

const validateRow = (row: TemplateRow, rowNumber: number): ParsedWorkRow => {
    const errors: string[] = [];
    const title = toText(row['工作名称']);
    const description = toText(row['详细描述']);
    const priority = toText(row['优先级']);
    const deadline = parseDeadline(row['截止日期']);
    const requirementNumber = toText(row['需求编号']);
    const applicationDepartment = toText(row['申请部门']);
    const applicantName = toText(row['申请人']);
    const owningSystem = toText(row['归属系统']);
    const primarySystem = parsePrimarySystem(row['是否主系统']);
    const primarySystemName = toText(row['主系统名称']);
    const projectType = toText(row['项目类型']);

    if (title.length < 2 || title.length > 200) errors.push('工作名称需为2到200个字符');
    if (description.length < 10) errors.push('详细描述至少10个字符');
    if (!PRIORITIES.includes(priority as typeof PRIORITIES[number])) errors.push('优先级只能是P0、P1、P2、P3');
    if (deadline === null) errors.push('截止日期格式应为yyyy-MM-dd HH:mm');
    if (deadline && new Date(deadline).getTime() <= Date.now()) errors.push('截止日期必须晚于当前时间');
    if (requirementNumber.length > 100) errors.push('需求编号不能超过100个字符');
    if (!applicationDepartment || applicationDepartment.length > 100) errors.push('申请部门必填且不能超过100个字符');
    if (!applicantName || applicantName.length > 100) errors.push('申请人必填且不能超过100个字符');
    if (!owningSystem || owningSystem.length > 100) errors.push('归属系统必填且不能超过100个字符');
    if (primarySystem === null) errors.push('是否主系统只能填写是或否');
    if (primarySystem === false && !primarySystemName) errors.push('非主系统必须填写主系统名称');
    if (primarySystemName.length > 100) errors.push('主系统名称不能超过100个字符');
    if (!PROJECT_TYPES.includes(projectType as typeof PROJECT_TYPES[number])) errors.push('项目类型只能是变更类或仅配合');

    if (errors.length > 0 || primarySystem === null || deadline === null) {
        return { rowNumber, errors };
    }

    return {
        rowNumber,
        errors,
        data: {
            title,
            description,
            priority: priority as WorkImportDTO['priority'],
            deadline,
            requirementNumber: requirementNumber || undefined,
            applicationDepartment,
            applicantName,
            owningSystem,
            primarySystem,
            primarySystemName: primarySystem ? undefined : primarySystemName,
            projectType: projectType as WorkImportDTO['projectType'],
        },
    };
};

const downloadTemplate = () => {
    const templateSheet = XLSX.utils.aoa_to_sheet([[...TEMPLATE_HEADERS]]);
    templateSheet['!cols'] = TEMPLATE_COLUMN_WIDTHS.map(wch => ({ wch }));
    templateSheet['!rows'] = [{ hpt: 24 }];
    templateSheet['!autofilter'] = { ref: `A1:${XLSX.utils.encode_col(TEMPLATE_HEADERS.length - 1)}1` };

    const instructions = [
        ['字段', '是否必填', '填写说明', '示例'],
        ['工作名称', '是', '2到200个字符', '监管报送需求优化'],
        ['详细描述', '是', '至少10个字符', '完成监管报送需求的分析、开发与上线'],
        ['优先级', '是', '仅支持P0、P1、P2、P3', 'P2'],
        ['截止日期', '否', '必须晚于当前时间，格式：yyyy-MM-dd HH:mm', '2099-12-31 18:00'],
        ['需求编号', '否', '不超过100个字符', 'REQ-2099-001'],
        ['申请部门', '是', '不超过100个字符', '科技开发部'],
        ['申请人', '是', '不超过100个字符', '张三'],
        ['归属系统', '是', '不超过100个字符', '统一监管报送系统'],
        ['是否主系统', '是', '仅填写是或否', '是'],
        ['主系统名称', '条件必填', '是否主系统为否时必填', '核心业务系统'],
        ['项目类型', '是', '仅支持变更类或仅配合', '变更类'],
    ];
    const instructionSheet = XLSX.utils.aoa_to_sheet(instructions);
    instructionSheet['!cols'] = [{ wch: 18 }, { wch: 14 }, { wch: 46 }, { wch: 30 }];
    instructionSheet['!rows'] = [{ hpt: 24 }];

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, templateSheet, '工作导入模板');
    XLSX.utils.book_append_sheet(workbook, instructionSheet, '填写说明');
    XLSX.writeFile(workbook, '工作导入模板.xlsx');
};

const ImportWorkModal: React.FC<ImportWorkModalProps> = ({ isOpen, onClose, onSuccess }) => {
    const fileInputRef = React.useRef<HTMLInputElement>(null);
    const [fileName, setFileName] = React.useState('');
    const [parsedRows, setParsedRows] = React.useState<ParsedWorkRow[]>([]);
    const [fileError, setFileError] = React.useState('');
    const [importing, setImporting] = React.useState(false);

    const reset = () => {
        setFileName('');
        setParsedRows([]);
        setFileError('');
        if (fileInputRef.current) fileInputRef.current.value = '';
    };

    const handleClose = () => {
        if (importing) return;
        reset();
        onClose();
    };

    const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) return;

        setFileName(file.name);
        setParsedRows([]);
        setFileError('');

        try {
            if (!/\.(xlsx|xls)$/i.test(file.name)) {
                throw new Error('仅支持 .xlsx 或 .xls 文件');
            }
            if (file.size > 10 * 1024 * 1024) {
                throw new Error('文件不能超过10MB');
            }

            const workbook = XLSX.read(await file.arrayBuffer(), { type: 'array', cellDates: true });
            const sheet = workbook.Sheets['工作导入模板'] || workbook.Sheets[workbook.SheetNames[0]];
            if (!sheet) throw new Error('文件中没有可读取的工作表');

            const matrix = XLSX.utils.sheet_to_json<unknown[]>(sheet, { header: 1, defval: '' });
            const headers = (matrix[0] || []).map(toText);
            const missingHeaders = REQUIRED_HEADERS.filter(header => !headers.includes(header));
            if (missingHeaders.length > 0) {
                throw new Error(`缺少必填列：${missingHeaders.join('、')}`);
            }

            const rows = XLSX.utils.sheet_to_json<TemplateRow>(sheet, { defval: '', raw: true })
                .filter(row => Object.values(row).some(value => toText(value) !== ''));
            if (rows.length === 0) throw new Error('模板中没有可导入的数据');
            if (rows.length > 500) throw new Error('单次最多导入500条工作');

            setParsedRows(rows.map((row, index) => validateRow(row, index + 2)));
        } catch (error) {
            setFileError(error instanceof Error ? error.message : 'Excel文件解析失败');
        }
    };

    const invalidRows = parsedRows.filter(row => row.errors.length > 0);
    const validRows = parsedRows.filter((row): row is ParsedWorkRow & { data: WorkImportDTO } => !!row.data);

    const handleImport = async () => {
        if (validRows.length === 0 || invalidRows.length > 0) return;

        setImporting(true);
        try {
            const result = await importWorks(validRows.map(row => row.data));
            message.success(`成功导入${result.importedCount}条工作`);
            reset();
            onSuccess();
            onClose();
        } catch (error) {
            console.error('Import works failed', error);
            message.error(error instanceof Error ? error.message : '工作导入失败');
        } finally {
            setImporting(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
            <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={handleClose} />
            <div className="relative w-full max-w-3xl overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl">
                <div className="flex items-center justify-between border-b border-slate-100 px-6 py-4">
                    <div>
                        <h2 className="text-lg font-bold text-slate-800">导入工作</h2>
                        <p className="mt-1 text-sm text-slate-500">仅导入工作信息，主任务由系统自动创建</p>
                    </div>
                    <button
                        type="button"
                        onClick={handleClose}
                        disabled={importing}
                        className="rounded-full p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 disabled:opacity-50"
                    >
                        <X size={20} />
                    </button>
                </div>

                <div className="max-h-[70vh] space-y-5 overflow-y-auto bg-slate-50/60 p-6">
                    <div className="flex items-center justify-between rounded-xl border border-blue-100 bg-blue-50 px-4 py-3">
                        <div className="flex items-center gap-3">
                            <FileSpreadsheet size={20} className="text-blue-600" />
                            <div>
                                <div className="text-sm font-bold text-blue-900">先下载标准模板</div>
                                <div className="text-xs text-blue-700">不要增加任务字段；每条工作会生成同名、0积分的主任务</div>
                            </div>
                        </div>
                        <button
                            type="button"
                            onClick={downloadTemplate}
                            className="inline-flex items-center gap-2 rounded-lg border border-blue-200 bg-white px-3 py-2 text-sm font-bold text-blue-700 transition-colors hover:bg-blue-100"
                        >
                            <Download size={16} />下载模板
                        </button>
                    </div>

                    <div className="rounded-xl border border-dashed border-slate-300 bg-white p-5">
                        <input
                            ref={fileInputRef}
                            type="file"
                            accept=".xlsx,.xls"
                            onChange={handleFileChange}
                            className="hidden"
                        />
                        <div className="flex items-center justify-between gap-4">
                            <div className="min-w-0">
                                <div className="text-sm font-bold text-slate-700">选择已填写的工作模板</div>
                                <div className="mt-1 truncate text-xs text-slate-400">{fileName || '支持 .xlsx、.xls，单次最多500条，文件不超过10MB'}</div>
                            </div>
                            <button
                                type="button"
                                onClick={() => fileInputRef.current?.click()}
                                disabled={importing}
                                className="inline-flex shrink-0 items-center gap-2 rounded-lg bg-slate-800 px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-slate-700 disabled:opacity-50"
                            >
                                <Upload size={16} />选择文件
                            </button>
                        </div>
                    </div>

                    {fileError && (
                        <div className="flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                            <AlertCircle size={18} className="mt-0.5 shrink-0" />
                            <span>{fileError}</span>
                        </div>
                    )}

                    {parsedRows.length > 0 && (
                        <div className="space-y-4">
                            <div className="grid grid-cols-3 gap-3">
                                <div className="rounded-xl border border-slate-200 bg-white px-4 py-3">
                                    <div className="text-xs text-slate-400">读取行数</div>
                                    <div className="mt-1 text-xl font-bold text-slate-800">{parsedRows.length}</div>
                                </div>
                                <div className="rounded-xl border border-green-200 bg-green-50 px-4 py-3">
                                    <div className="text-xs text-green-600">校验通过</div>
                                    <div className="mt-1 text-xl font-bold text-green-700">{validRows.length}</div>
                                </div>
                                <div className={`rounded-xl border px-4 py-3 ${invalidRows.length > 0 ? 'border-red-200 bg-red-50' : 'border-slate-200 bg-white'}`}>
                                    <div className={invalidRows.length > 0 ? 'text-xs text-red-600' : 'text-xs text-slate-400'}>校验失败</div>
                                    <div className={`mt-1 text-xl font-bold ${invalidRows.length > 0 ? 'text-red-700' : 'text-slate-800'}`}>{invalidRows.length}</div>
                                </div>
                            </div>

                            {invalidRows.length > 0 ? (
                                <div className="rounded-xl border border-red-200 bg-white">
                                    <div className="border-b border-red-100 px-4 py-3 text-sm font-bold text-red-700">请修正以下数据后重新选择文件</div>
                                    <div className="max-h-48 divide-y divide-slate-100 overflow-y-auto">
                                        {invalidRows.slice(0, 20).map(row => (
                                            <div key={row.rowNumber} className="px-4 py-2 text-xs text-slate-600">
                                                <span className="mr-2 font-bold text-red-600">第{row.rowNumber}行</span>
                                                {row.errors.join('；')}
                                            </div>
                                        ))}
                                        {invalidRows.length > 20 && (
                                            <div className="px-4 py-2 text-xs text-slate-400">另有{invalidRows.length - 20}行错误未展示</div>
                                        )}
                                    </div>
                                </div>
                            ) : (
                                <div className="flex items-center gap-2 rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700">
                                    <CheckCircle2 size={18} />
                                    全部数据校验通过，可以开始导入
                                </div>
                            )}
                        </div>
                    )}
                </div>

                <div className="flex items-center justify-end gap-3 border-t border-slate-100 bg-white px-6 py-4">
                    <button
                        type="button"
                        onClick={handleClose}
                        disabled={importing}
                        className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-bold text-slate-600 transition-colors hover:bg-slate-50 disabled:opacity-50"
                    >
                        取消
                    </button>
                    <button
                        type="button"
                        onClick={handleImport}
                        disabled={importing || validRows.length === 0 || invalidRows.length > 0}
                        className="rounded-lg bg-red-600 px-5 py-2 text-sm font-bold text-white transition-colors hover:bg-red-500 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {importing ? '导入中...' : `确认导入${validRows.length > 0 ? `（${validRows.length}条）` : ''}`}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default ImportWorkModal;
