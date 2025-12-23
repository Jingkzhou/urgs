import React, { useRef, useEffect, useState } from 'react';
import { Plus, Mic, ArrowUp, Image, Paperclip, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface ChatInputProps {
    value: string;
    onChange: (val: string) => void;
    onSubmit: () => void;
    isGenerating: boolean;
    onStop: () => void;
}

const ChatInput: React.FC<ChatInputProps> = ({ value, onChange, onSubmit, isGenerating, onStop }) => {
    const textareaRef = useRef<HTMLTextAreaElement>(null);
    const [isFocused, setIsFocused] = useState(false);

    // Auto-resize textarea
    useEffect(() => {
        if (textareaRef.current) {
            textareaRef.current.style.height = 'auto'; // Reset height
            textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 200)}px`;
        }
    }, [value]);

    const handleKeyDown = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            if (value.trim() && !isGenerating) {
                onSubmit();
            }
        }
    };

    return (
        <div className="w-full relative group max-w-4xl mx-auto">
            <motion.div
                animate={{
                    boxShadow: isFocused ? "0 4px 12px rgba(0,0,0,0.1)" : "0 2px 6px rgba(0,0,0,0.05)",
                    backgroundColor: isFocused ? "#ffffff" : "#f0f4f9"
                }}
                className="relative flex flex-col rounded-[28px] overflow-hidden transition-colors duration-300"
            >
                <div className="flex items-end px-4 py-3">
                    {/* Attachment Button */}
                    <button className="p-2 mb-0.5 text-slate-500 hover:text-slate-800 hover:bg-slate-200/50 rounded-full transition-colors mr-2 flex-shrink-0">
                        <Plus size={22} strokeWidth={2.5} />
                    </button>

                    {/* Auto-growing Textarea */}
                    <textarea
                        ref={textareaRef}
                        value={value}
                        onChange={(e) => onChange(e.target.value)}
                        onKeyDown={handleKeyDown}
                        onFocus={() => setIsFocused(true)}
                        onBlur={() => setIsFocused(false)}
                        placeholder="输入消息..."
                        rows={1}
                        className="flex-1 bg-transparent border-none outline-none text-[#1f1f1f] placeholder:text-slate-500 text-[16px] px-2 font-normal resize-none py-2.5 max-h-[200px] overflow-y-auto custom-scrollbar leading-[1.6]"
                        style={{ minHeight: '48px' }}
                    />

                    <div className="flex items-end gap-2 mb-1 flex-shrink-0 ml-2">
                        {/* Voice Input (Mock) */}
                        {!value.trim() && (
                            <button className="p-2 text-slate-500 hover:text-slate-800 hover:bg-slate-200/50 rounded-full transition-colors" title="语音输入">
                                <Mic size={22} />
                            </button>
                        )}
                        {!value.trim() && (
                            <button className="p-2 text-slate-500 hover:text-slate-800 hover:bg-slate-200/50 rounded-full transition-colors" title="上传图片">
                                <Image size={22} />
                            </button>
                        )}

                        {/* Submit / Stop Button */}
                        <AnimatePresence mode="wait">
                            {isGenerating ? (
                                <motion.button
                                    key="stop"
                                    initial={{ scale: 0, opacity: 0 }}
                                    animate={{ scale: 1, opacity: 1 }}
                                    exit={{ scale: 0, opacity: 0 }}
                                    onClick={onStop}
                                    className="p-2 rounded-full bg-slate-900 text-white hover:bg-slate-700 transition-all duration-200 group-active:scale-95 flex items-center justify-center w-10 h-10"
                                    title="停止生成"
                                >
                                    <div className="w-3 h-3 bg-white rounded-sm"></div>
                                </motion.button>
                            ) : (
                                <motion.button
                                    key="submit"
                                    initial={{ scale: 0.8, opacity: 0.5 }}
                                    animate={{
                                        scale: value.trim() ? 1 : 0.9,
                                        opacity: value.trim() ? 1 : 0.5,
                                        backgroundColor: value.trim() ? "#0b57d0" : "transparent"
                                    }}
                                    onClick={onSubmit}
                                    className={`w-10 h-10 flex items-center justify-center rounded-full transition-all duration-200 ${value.trim()
                                        ? 'text-white hover:bg-blue-700 shadow-md'
                                        : 'text-slate-400 cursor-not-allowed hover:bg-transparent'
                                        }`}
                                    disabled={!value.trim()}
                                >
                                    <ArrowUp size={20} strokeWidth={3} />
                                </motion.button>
                            )}
                        </AnimatePresence>
                    </div>
                </div>
            </motion.div>
        </div>
    );
};

export default ChatInput;
