import React, { useRef, useEffect } from 'react';
import { X, ArrowUp, Wrench } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import type { AgentAppSkill } from '../../api/chat';

interface ChatInputProps {
    value: string;
    onChange: (val: string) => void;
    onSubmit: () => void;
    isGenerating: boolean;
    onStop: () => void;
    isWide?: boolean;
    agentAppSkills?: AgentAppSkill[];
    selectedAgentAppSkill?: AgentAppSkill | null;
    onAgentAppSkillSelect?: (skill: AgentAppSkill) => void;
    onAgentAppSkillClear?: () => void;
}

const ChatInput: React.FC<ChatInputProps> = ({
    value,
    onChange,
    onSubmit,
    isGenerating,
    onStop,
    isWide = false,
    agentAppSkills = [],
    selectedAgentAppSkill,
    onAgentAppSkillSelect,
    onAgentAppSkillClear
}) => {
    const textareaRef = useRef<HTMLTextAreaElement>(null);
    const slashMatch = value.match(/^\/([^\s/]*)$/);
    const skillKeyword = slashMatch?.[1]?.toLowerCase() || '';
    const matchedSkills = agentAppSkills
        .filter(skill => skill.status === 1)
        .filter(skill => {
            if (!skillKeyword) return true;
            return skill.name.toLowerCase().includes(skillKeyword) || skill.code.toLowerCase().includes(skillKeyword);
        })
        .slice(0, 8);
    const showSkillMenu = !!slashMatch && matchedSkills.length > 0 && !isGenerating;

    // Auto-resize textarea
    useEffect(() => {
        if (textareaRef.current) {
            textareaRef.current.style.height = 'auto'; // Reset height
            textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 200)}px`;
        }
    }, [value]);

    const handleKeyDown = (e: React.KeyboardEvent) => {
        if (e.key === 'Escape' && slashMatch) {
            e.preventDefault();
            onChange('');
            return;
        }
        if (e.key === 'Enter' && showSkillMenu) {
            e.preventDefault();
            handleSkillSelect(matchedSkills[0]);
            return;
        }
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            if (value.trim() && !isGenerating) {
                onSubmit();
            }
        }
    };

    const handleSkillSelect = (skill: AgentAppSkill) => {
        onAgentAppSkillSelect?.(skill);
        onChange('');
        requestAnimationFrame(() => textareaRef.current?.focus());
    };

    return (
        <div className={`w-full relative group mx-auto ${isWide ? 'max-w-7xl' : 'max-w-6xl'}`}>
            <AnimatePresence>
                {showSkillMenu && (
                    <motion.div
                        initial={{ opacity: 0, y: 8, scale: 0.98 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: 8, scale: 0.98 }}
                        className="absolute left-0 right-0 bottom-full mb-3 z-30 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xl"
                    >
                        <div className="max-h-72 overflow-y-auto py-2">
                            {matchedSkills.map(skill => (
                                <button
                                    key={skill.id}
                                    type="button"
                                    onClick={() => handleSkillSelect(skill)}
                                    className="w-full px-4 py-3 text-left hover:bg-slate-50 transition-colors flex items-start gap-3"
                                >
                                    <span className="mt-0.5 flex h-8 w-8 items-center justify-center rounded-lg bg-purple-50 text-purple-600">
                                        <Wrench size={16} />
                                    </span>
                                    <span className="min-w-0 flex-1">
                                        <span className="flex items-center gap-2">
                                            <span className="font-bold text-sm text-slate-800 truncate">{skill.name}</span>
                                            <span className="text-xs text-slate-400">/{skill.code}</span>
                                        </span>
                                        <span className="mt-1 block text-xs text-slate-500 line-clamp-1">
                                            {skill.description || skill.instruction || 'Agent App 技能'}
                                        </span>
                                    </span>
                                </button>
                            ))}
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
            <motion.div
                animate={{ backgroundColor: "#f4f4f4" }}
                className="relative flex flex-col overflow-hidden rounded-[28px] border border-slate-200 transition-colors duration-200 focus-within:border-slate-300"
            >
                {selectedAgentAppSkill && (
                    <div className="flex items-center gap-2 px-5 pt-3">
                        <span className="inline-flex items-center gap-2 rounded-full bg-purple-50 px-3 py-1 text-xs font-bold text-purple-700 border border-purple-100">
                            <Wrench size={13} />
                            {selectedAgentAppSkill.name}
                            <button
                                type="button"
                                onClick={onAgentAppSkillClear}
                                className="ml-1 rounded-full p-0.5 hover:bg-purple-100 transition-colors"
                                title="清除技能"
                            >
                                <X size={12} />
                            </button>
                        </span>
                    </div>
                )}
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
                                        backgroundColor: value.trim() ? "#0d0d0d" : "rgba(0, 0, 0, 0)"
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
