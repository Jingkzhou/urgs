export type PreviewType =
    | { kind: 'image' }
    | { kind: 'pdf' }
    | { kind: 'spreadsheet' }
    | { kind: 'word' }
    | { kind: 'presentation' }
    | { kind: 'video' }
    | { kind: 'audio' }
    | { kind: 'code'; language: string }
    | { kind: 'markdown' }
    | { kind: 'text' }
    | { kind: 'unsupported' };

const IMAGE_EXTS = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'];
const SPREADSHEET_EXTS = ['xls', 'xlsx', 'csv'];
const WORD_EXTS = ['doc', 'docx'];
const PRESENTATION_EXTS = ['ppt', 'pptx'];
const VIDEO_EXTS = ['mp4', 'webm', 'mov'];
const AUDIO_EXTS = ['mp3', 'wav', 'ogg', 'flac'];
const CODE_EXT_MAP: Record<string, string> = {
    js: 'javascript',
    jsx: 'jsx',
    ts: 'typescript',
    tsx: 'tsx',
    java: 'java',
    py: 'python',
    c: 'c',
    cpp: 'cpp',
    html: 'html',
    css: 'css',
    json: 'json',
    xml: 'xml',
    yaml: 'yaml',
    yml: 'yaml',
    sql: 'sql',
    sh: 'bash',
    bash: 'bash',
    go: 'go',
    rs: 'rust',
    rb: 'ruby',
    php: 'php',
    swift: 'swift',
    kt: 'kotlin',
    vue: 'javascript',
};

export function getPreviewType(fileName: string): PreviewType {
    const ext = fileName.split('.').pop()?.toLowerCase() || '';

    if (IMAGE_EXTS.includes(ext)) return { kind: 'image' };
    if (ext === 'pdf') return { kind: 'pdf' };
    if (SPREADSHEET_EXTS.includes(ext)) return { kind: 'spreadsheet' };
    if (WORD_EXTS.includes(ext)) return { kind: 'word' };
    if (PRESENTATION_EXTS.includes(ext)) return { kind: 'presentation' };
    if (VIDEO_EXTS.includes(ext)) return { kind: 'video' };
    if (AUDIO_EXTS.includes(ext)) return { kind: 'audio' };
    if (['md', 'markdown'].includes(ext)) return { kind: 'markdown' };
    if (CODE_EXT_MAP[ext]) return { kind: 'code', language: CODE_EXT_MAP[ext] };
    if (['txt', 'log', 'csv', 'rtf'].includes(ext)) return { kind: 'text' };

    return { kind: 'unsupported' };
}
