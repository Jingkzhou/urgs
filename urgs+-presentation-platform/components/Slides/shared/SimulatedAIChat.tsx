import React, { useState, useEffect } from 'react';
import { Bot, Zap, UserCircle2, Terminal, Search } from 'lucide-react';

export const SimulatedAIChat = ({ scenario }: { scenario: { role: 'user' | 'ai'; content: string; extra?: React.ReactNode }[] }) => {
    const [messages, setMessages] = useState<{ role: 'user' | 'ai'; content: string; displayContent?: string; extra?: React.ReactNode }[]>([]);
    const [isThinking, setIsThinking] = useState(false);
    const [step, setStep] = useState(0);

    useEffect(() => {
        if (step < scenario.length) {
            const currentMsg = scenario[step];

            if (currentMsg.role === 'user') {
                const timer = setTimeout(() => {
                    setMessages(prev => {
                        if (prev.find(m => m.role === 'user' && m.content === currentMsg.content)) return prev;
                        return [...prev, { ...currentMsg, displayContent: currentMsg.content }];
                    });
                    setStep(prev => prev + 1);
                }, 1000);
                return () => clearTimeout(timer);
            }

            if (currentMsg.role === 'ai') {
                const thinkingTimer = setTimeout(() => {
                    setIsThinking(true);

                    const responseTimer = setTimeout(() => {
                        setIsThinking(false);

                        setMessages(prev => [...prev, { ...currentMsg, displayContent: '' }]);

                        let charIndex = 0;
                        const fullText = currentMsg.content;

                        const typingInterval = setInterval(() => {
                            charIndex++;
                            if (charIndex <= fullText.length) {
                                setMessages(prev => {
                                    const newMsgs = [...prev];
                                    const lastIdx = newMsgs.length - 1;
                                    if (newMsgs[lastIdx] && newMsgs[lastIdx].role === 'ai') {
                                        newMsgs[lastIdx] = {
                                            ...newMsgs[lastIdx],
                                            displayContent: fullText.slice(0, charIndex)
                                        };
                                    }
                                    return newMsgs;
                                });
                            } else {
                                clearInterval(typingInterval);
                                setStep(prev => prev + 1);
                            }
                        }, 30);
                    }, 1500);

                    return () => clearTimeout(responseTimer);
                }, 1000);
                return () => clearTimeout(thinkingTimer);
            }
        }
    }, [step, scenario]);


    return (
        <div className="w-full max-w-2xl bg-white rounded-3xl shadow-2xl border border-slate-100 overflow-hidden flex flex-col h-[500px]">
            <div className="bg-slate-50 px-6 py-4 border-b border-slate-100 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-indigo-600 rounded-full flex items-center justify-center text-white shadow-lg">
                        <Bot className="w-6 h-6" />
                    </div>
                    <div>
                        <div className="text-sm font-bold text-slate-800">URGS+ Ark Assistant</div>
                        <div className="flex items-center gap-1.5">
                            <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></span>
                            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Active Now</span>
                        </div>
                    </div>
                </div>
                <Zap className="w-5 h-5 text-amber-400" />
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-6 bg-gradient-to-b from-white to-slate-50/30">
                {messages.map((msg, i) => (
                    <div key={i} className={`flex items-start gap-3 ${msg.role === 'user' ? 'justify-end' : ''} anim-fade-up`}>
                        {msg.role === 'ai' && (
                            <div className="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center shrink-0 border border-amber-200">
                                <Bot className="w-4 h-4 text-amber-600" />
                            </div>
                        )}
                        <div className={`p-4 rounded-2xl max-w-[85%] text-sm ${msg.role === 'user'
                            ? 'bg-indigo-600 text-white rounded-tr-none shadow-indigo-100'
                            : 'bg-white border border-slate-200 text-slate-700 rounded-tl-none shadow-sm'
                            }`}>
                            <div className="relative">
                                {msg.displayContent}
                                {msg.extra && msg.displayContent === msg.content && (
                                    <div className="mt-4 animate-in fade-in slide-in-from-bottom-2 duration-500">
                                        {msg.extra}
                                    </div>
                                )}
                                {msg.role === 'ai' && i === messages.length - 1 && msg.displayContent !== msg.content && (
                                    <span className="inline-block w-1.5 h-4 bg-indigo-400 ml-1 animate-pulse align-middle"></span>
                                )}
                            </div>
                        </div>
                        {msg.role === 'user' && (
                            <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center shrink-0">
                                <UserCircle2 className="w-5 h-5 text-slate-400" />
                            </div>
                        )}
                    </div>
                ))}
                {isThinking && (
                    <div className="flex items-start gap-3 anim-fade-up">
                        <div className="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center shrink-0 border border-amber-200">
                            <Bot className="w-4 h-4 text-amber-600 animate-bounce" />
                        </div>
                        <div className="bg-white border border-slate-200 p-4 rounded-2xl rounded-tl-none shadow-sm space-x-1 flex">
                            <div className="w-1.5 h-1.5 bg-slate-300 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
                            <div className="w-1.5 h-1.5 bg-slate-400 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
                            <div className="w-1.5 h-1.5 bg-slate-300 rounded-full animate-bounce"></div>
                        </div>
                    </div>
                )}
            </div>

            <div className="px-6 py-4 bg-white border-t border-slate-100">
                <div className="bg-slate-50 rounded-full px-5 py-2.5 flex items-center justify-between border border-slate-200">
                    <span className="text-slate-400 text-sm">Ask URGS+ a question...</span>
                    <div className="flex gap-2">
                        <Terminal className="w-4 h-4 text-slate-300" />
                        <Search className="w-4 h-4 text-slate-300" />
                    </div>
                </div>
            </div>
        </div>
    );
};
