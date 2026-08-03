import type { ArkDesktopDiffHunk, ArkDesktopFileChange } from './types';

const MAX_PREVIEW_CHARACTERS = 160_000;
const MAX_PREVIEW_LINES = 2_000;

const lineCount = (value: string) => value ? value.split('\n').length : 0;

const splitLines = (value: string) => value ? value.split('\n') : [];

const boundedLines = (value: string) => {
    const truncated = value.length > MAX_PREVIEW_CHARACTERS;
    return {
        lines: splitLines(value.slice(0, MAX_PREVIEW_CHARACTERS)).slice(0, MAX_PREVIEW_LINES),
        truncated,
    };
};

const fallbackHunk = (oldText: string, newText: string): ArkDesktopDiffHunk => {
    const oldLines = splitLines(oldText);
    const newLines = splitLines(newText);
    let prefix = 0;
    while (prefix < oldLines.length && prefix < newLines.length && oldLines[prefix] === newLines[prefix]) prefix += 1;
    let suffix = 0;
    while (
        suffix < oldLines.length - prefix
        && suffix < newLines.length - prefix
        && oldLines[oldLines.length - suffix - 1] === newLines[newLines.length - suffix - 1]
    ) suffix += 1;
    return {
        oldLine: prefix + 1,
        newLine: prefix + 1,
        oldLines: oldLines.slice(prefix, oldLines.length - suffix),
        newLines: newLines.slice(prefix, newLines.length - suffix),
    };
};

const parseHunks = (meta: unknown, oldText: string, newText: string): ArkDesktopDiffHunk[] => {
    const details = meta && typeof meta === 'object' && Array.isArray((meta as any).details)
        ? (meta as any).details
        : [];
    const parsed = details.map((detail: any) => ({
        oldLine: Number(detail?.oldLine ?? detail?.old_line ?? 1) || 1,
        newLine: Number(detail?.newLine ?? detail?.new_line ?? 1) || 1,
        oldLines: boundedLines(String(detail?.oldString ?? detail?.old_string ?? '')).lines,
        newLines: boundedLines(String(detail?.newString ?? detail?.new_string ?? '')).lines,
    })).filter((hunk: ArkDesktopDiffHunk) => hunk.oldLines.length > 0 || hunk.newLines.length > 0);
    return parsed.length > 0 ? parsed : [fallbackHunk(oldText, newText)];
};

export const extractFileChanges = (content: unknown): ArkDesktopFileChange[] => {
    if (!Array.isArray(content)) return [];
    return content.flatMap((item: any) => {
        if (item?.type !== 'diff' || typeof item.path !== 'string' || typeof item.newText !== 'string') return [];
        const oldText = typeof item.oldText === 'string' ? item.oldText : '';
        const newText = item.newText;
        const hunks = parseHunks(item._meta, oldText, newText);
        const additions = hunks.reduce((total, hunk) => total + hunk.newLines.length, 0);
        const deletions = hunks.reduce((total, hunk) => total + hunk.oldLines.length, 0);
        return [{
            path: item.path,
            additions: additions || Math.max(0, lineCount(newText) - lineCount(oldText)),
            deletions: deletions || Math.max(0, lineCount(oldText) - lineCount(newText)),
            hunks,
            previewTruncated: oldText.length > MAX_PREVIEW_CHARACTERS || newText.length > MAX_PREVIEW_CHARACTERS,
        }];
    });
};

export const mergeFileChanges = (changes: ArkDesktopFileChange[]) => {
    const merged = new Map<string, ArkDesktopFileChange>();
    changes.forEach((change) => {
        const additions = change.hunks.reduce(
            (total, hunk) => total + (hunk.newLines.length === 1 && hunk.newLines[0] === '' ? 0 : hunk.newLines.length),
            0,
        );
        const deletions = change.hunks.reduce(
            (total, hunk) => total + (hunk.oldLines.length === 1 && hunk.oldLines[0] === '' ? 0 : hunk.oldLines.length),
            0,
        );
        merged.set(change.path, { ...change, additions, deletions });
    });
    return Array.from(merged.values());
};
