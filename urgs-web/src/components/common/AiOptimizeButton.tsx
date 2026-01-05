import React, { useState, useRef } from 'react';
import { Sparkles, Loader2, StopCircle } from 'lucide-react';
import { streamChatResponse } from '../../api/chat';

interface AiOptimizeButtonProps {
    /** The current value of the input field to be optimized */
    value: string;
    /** Callback to update the input field value */
    onApply: (value: string) => void;
    /** Function to generate the prompt based on the current value */
    promptGenerator: (value: string) => string;
    /** Optional className for styling */
    className?: string;
    /** Optional tooltip text */
    title?: string;
}

/**
 * A reusable button that uses AI to optimize text input.
 * Streams the response directly into the input field via onApply.
 */
export const AiOptimizeButton: React.FC<AiOptimizeButtonProps> = ({
    value,
    onApply,
    promptGenerator,
    className = '',
    title = "AI 话术优化"
}) => {
    const [isOptimizing, setIsOptimizing] = useState(false);
    const abortControllerRef = useRef<AbortController | null>(null);

    const handleOptimize = async () => {
        if (isOptimizing) {
            // If already optimizing, stop it
            abortControllerRef.current?.abort();
            setIsOptimizing(false);
            return;
        }

        if (!value || !value.trim()) {
            // Don't optimize empty content, maybe show a toast?
            return;
        }

        setIsOptimizing(true);
        abortControllerRef.current = new AbortController();

        let currentText = ""; // Start from scratch or append? Usually replace.
        // For optimization, we typically want to replace the current text or stream into it.
        // Assuming we replace the whole text with the optimized version.

        const prompt = promptGenerator(value);

        try {
            await streamChatResponse(
                prompt,
                (chunk) => {
                    currentText += chunk;
                    onApply(currentText);
                },
                () => {
                    setIsOptimizing(false);
                    abortControllerRef.current = null;
                },
                abortControllerRef.current.signal
            );
        } catch (error) {
            console.error("Optimization failed", error);
            setIsOptimizing(false);
            abortControllerRef.current = null;
        }
    };

    return (
        <button
            type="button"
            onClick={handleOptimize}
            className={`p-1.5 rounded-lg transition-all border shadow-sm ${isOptimizing
                ? 'bg-rose-50 text-rose-600 border-rose-200 hover:bg-rose-100 animate-pulse'
                : 'bg-indigo-50 text-indigo-600 border-indigo-200 hover:bg-indigo-100 hover:scale-110'
                } ${className}`}
            title={isOptimizing ? '点击停止' : title}
            disabled={!value && !isOptimizing}
        >
            {isOptimizing ? (
                <StopCircle size={14} />
            ) : (
                <Sparkles size={14} />
            )}
        </button>
    );
};
