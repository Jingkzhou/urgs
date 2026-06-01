import React, { useRef, useEffect, useState } from 'react';
import { Plus, Mic, ArrowUp, Image } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface ChatInputProps {
    value: string;
    onChange: (val: string) => void;
    onSubmit: () => void;
    isGenerating: boolean;
    onStop: () => void;
    isWide?: boolean;
}

const ChatInput: React.FC<ChatInputProps> = ({ value, onChange, onSubmit, isGenerating, onStop, isWide = false }) => {
    const textareaRef = useRef<HTMLTextAreaElement>(null);
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
        <div className={`w-full relative group mx-auto ${isWide ? 'max-w-7xl' : 'max-w-6xl'}`}>
            <motion.div
                animate={{ backgroundColor: "#f4f4f4" }}
                className="relative flex flex-col overflow-hidden rounded-[28px] border border-slate-200 transition-colors duration-200 focus-within:border-slate-300"
            >
                <div className="flex items-end px-4 py-3">
                    {/* Attachment Button */}
                    {/* <button className="p-2 mb-0.5 text-slate-500 hover:text-slate-800 hover:bg-slate-200/50 rounded-full transition-colors mr-2 flex-shrink-0">
                        <Plus size={22} strokeWidth={2.5} />
                    </button> */}

                    {/* Auto-growing Textarea */}
                    <textarea
                        ref={textareaRef}
                        value={value}
                        onChange={(e) => onChange(e.target.value)}
                        onKeyDown={handleKeyDown}
                        placeholder="输入消息"
                        rows={1}
                        className="flex-1 bg-transparent border-none outline-none text-[#0d0d0d] placeholder:text-slate-500 text-[16px] px-2 font-normal resize-none py-3 max-h-[200px] overflow-y-auto custom-scrollbar leading-[1.6]"
                        style={{ minHeight: '52px' }}
                    />

                    <div className="flex items-end gap-2 mb-1 flex-shrink-0 ml-2">
                        {/* Voice Input (Mock) */}
                        {/* {!value.trim() && (
                            <button className="p-2 text-slate-500 hover:text-slate-800 hover:bg-slate-200/50 rounded-full transition-colors" title="语音输入">
                                <Mic size={22} />
                            </button>
                        )}
                        {!value.trim() && (
                            <button className="p-2 text-slate-500 hover:text-slate-800 hover:bg-slate-200/50 rounded-full transition-colors" title="上传图片">
                                <Image size={22} />
                            </button>
                        )} */}

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
                                        backgroundColor: value.trim() ? "#0d0d0d" : "transparent"
                                    }}
                                    onClick={onSubmit}
                                    className={`w-10 h-10 flex items-center justify-center rounded-full transition-all duration-200 ${value.trim()
                                        ? 'text-white hover:bg-black'
                                        : 'text-slate-400 cursor-not-allowed'
                                        }`}
                                    disabled={!value.trim()}
                                >
                                    <ArrowUp size={20} strokeWidth={2.5} />
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
