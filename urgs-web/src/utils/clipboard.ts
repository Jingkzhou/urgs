import { message } from 'antd';

/**
 * 复制文本到剪贴板，兼容非安全上下文
 * @param text 要复制的内容
 * @returns Promise<boolean> 是否复制成功
 */
export const copyToClipboard = async (text: string): Promise<boolean> => {
    if (!text) return false;

    try {
        // 首先尝试使用现代 API
        if (navigator.clipboard && window.isSecureContext) {
            await navigator.clipboard.writeText(text);
            return true;
        } else {
            throw new Error('Clipboard API unavailable');
        }
    } catch (err) {
        // 为非安全上下文或旧版浏览器提供降级方案
        try {
            const textArea = document.createElement("textarea");
            textArea.value = text;

            // 确保元素不可见但位于 DOM 中
            textArea.style.position = "fixed";
            textArea.style.left = "-9999px";
            textArea.style.top = "0";
            document.body.appendChild(textArea);

            textArea.focus();
            textArea.select();

            const successful = document.execCommand('copy');
            document.body.removeChild(textArea);

            if (successful) {
                return true;
            }
            return false;
        } catch (fallbackErr) {
            console.error('Copy failed:', fallbackErr);
            return false;
        }
    }
};
