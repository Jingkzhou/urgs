import React, { useMemo, useState } from 'react';
import {
    Bot, BriefcaseBusiness, CheckSquare, ChevronDown, Code2, FileText,
    Folder, Lightbulb, Paperclip, Search, Send, Sparkles, WandSparkles,
    Wrench, X
} from 'lucide-react';

interface ArkAgentsPageProps {
    agents: any[];
    onClose: () => void;
    onStartTask: (agentId?: number | string, prompt?: string) => void;
}

const taskTags = [
    { label: '文档处理', icon: FileText, prompt: '请帮我整理并提炼这份文档的关键信息。' },
    { label: '监管数据查询', icon: Search, prompt: '请帮我查询并分析相关监管数据。' },
    { label: '数据分析及可视化', icon: BriefcaseBusiness, prompt: '请帮我分析这组数据并给出可视化建议。' },
    { label: '代码开发', icon: Code2, prompt: '请协助我完成这项开发任务。' },
    { label: '深度研究', icon: Lightbulb, prompt: '请围绕这个主题开展深度研究。' },
    { label: '技能编排', icon: Wrench, prompt: '请帮我规划这项工作需要的执行步骤。' },
];

const ArkAgentsPage: React.FC<ArkAgentsPageProps> = ({ agents, onClose, onStartTask }) => {
    const [mode, setMode] = useState<'work' | 'life'>('work');
    const [selectedAgentId, setSelectedAgentId] = useState<number | string | undefined>();
    const [draft, setDraft] = useState('');
    const [isAgentMenuOpen, setIsAgentMenuOpen] = useState(false);
    const [searchValue, setSearchValue] = useState('');

    const filteredAgents = useMemo(() => agents.filter(agent => {
        const query = searchValue.trim().toLowerCase();
        return !query || agent.name?.toLowerCase().includes(query) || agent.description?.toLowerCase().includes(query);
    }), [agents, searchValue]);
    const selectedAgent = agents.find(agent => String(agent.id) === String(selectedAgentId));

    const startTask = () => onStartTask(selectedAgentId, draft.trim());

    return (
        <div className="flex h-full min-h-0 bg-white text-[#2f3034]">
            <aside className="hidden w-[286px] shrink-0 flex-col border-r border-[#e5e6e9] bg-[#fbfbfc] p-4 lg:flex">
                <div className="mb-8 flex items-center gap-2.5 px-1 pt-1">
                    <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#111827] text-white shadow-sm">
                        <Sparkles size={19} strokeWidth={2.2} />
                    </div>
                    <div>
                        <div className="text-[17px] font-bold tracking-[-0.03em] text-[#17181c]">ARK DESKTOP</div>
                        <div className="mt-0.5 text-[11px] font-medium text-slate-400">智能任务中心</div>
                    </div>
                </div>

                <label className="mb-4 flex h-11 items-center gap-2 rounded-xl border border-[#dedfe3] bg-[#f2f2f3] px-3 text-slate-400 transition-colors focus-within:border-slate-400 focus-within:bg-white">
                    <Search size={18} />
                    <input
                        value={searchValue}
                        onChange={(event) => setSearchValue(event.target.value)}
                        placeholder="搜索 Agents"
                        className="min-w-0 flex-1 bg-transparent text-sm text-slate-700 outline-none placeholder:text-slate-400"
                    />
                </label>

                <button
                    type="button"
                    onClick={() => onStartTask()}
                    className="mb-2 flex h-12 items-center gap-3 rounded-xl bg-[#eeeeef] px-4 text-left text-[16px] font-semibold text-[#303137] transition-colors hover:bg-[#e4e4e6]"
                >
                    <CheckSquare size={21} />
                    新建任务
                </button>

                <div className="mt-1 space-y-1">
                    <button type="button" className="flex h-11 w-full items-center gap-3 rounded-xl px-4 text-left text-sm font-medium text-slate-600 transition-colors hover:bg-[#f0f0f1]">
                        <Bot size={19} />
                        Agents
                    </button>
                    <button type="button" className="flex h-11 w-full items-center gap-3 rounded-xl px-4 text-left text-sm font-medium text-slate-600 transition-colors hover:bg-[#f0f0f1]">
                        <WandSparkles size={19} />
                        技能
                    </button>
                    <button type="button" className="flex h-11 w-full items-center gap-3 rounded-xl px-4 text-left text-sm font-medium text-slate-600 transition-colors hover:bg-[#f0f0f1]">
                        <BriefcaseBusiness size={19} />
                        自动化
                    </button>
                </div>

                <div className="mt-8 min-h-0 flex-1 overflow-y-auto">
                    <div className="mb-3 px-1 text-xs font-semibold tracking-[0.08em] text-slate-400">可用 AGENTS</div>
                    <div className="space-y-1">
                        {filteredAgents.length > 0 ? filteredAgents.map(agent => (
                            <button
                                key={agent.id}
                                type="button"
                                onClick={() => setSelectedAgentId(agent.id)}
                                className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition-colors ${String(selectedAgentId) === String(agent.id) ? 'bg-white shadow-sm ring-1 ring-slate-200' : 'hover:bg-[#f0f0f1]'}`}
                            >
                                <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-slate-100 text-slate-600">
                                    <Bot size={16} />
                                </span>
                                <span className="min-w-0">
                                    <span className="block truncate text-sm font-medium text-slate-700">{agent.name}</span>
                                    <span className="mt-0.5 block truncate text-xs text-slate-400">{agent.description || '智能协作助手'}</span>
                                </span>
                            </button>
                        )) : (
                            <div className="rounded-xl px-3 py-5 text-center text-xs text-slate-400">没有匹配的 Agent</div>
                        )}
                    </div>
                </div>

                <button type="button" className="mt-4 flex items-center gap-3 rounded-xl px-2 py-2 text-left transition-colors hover:bg-[#f0f0f1]">
                    <span className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-emerald-300 to-cyan-600 text-sm font-bold text-slate-900">U</span>
                    <span className="min-w-0 flex-1 truncate text-sm font-semibold text-slate-600">当前用户</span>
                    <ChevronDown size={16} className="text-slate-400" />
                </button>
            </aside>

            <section className="relative flex min-w-0 flex-1 flex-col overflow-hidden">
                <div className="flex h-14 shrink-0 items-center border-b border-[#eff0f2] px-4 lg:px-6">
                    <button
                        type="button"
                        onClick={onClose}
                        className="flex h-9 items-center gap-2 rounded-lg px-2 text-sm font-medium text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-800"
                    >
                        <X size={18} />
                        返回对话
                    </button>
                </div>

                <div className="custom-scrollbar flex min-h-0 flex-1 flex-col overflow-y-auto px-5 pb-3 pt-4 md:px-10 lg:px-16">
                    <div className="mx-auto flex w-full max-w-5xl flex-1 flex-col items-center justify-center py-1">
                        <img src="/ark/ark-agents-robot-cropped.png" alt="Ark 机器人" className="mb-3 h-24 w-24 object-contain mix-blend-multiply sm:h-28 sm:w-28" />
                        <h1 className="text-center text-3xl font-semibold tracking-[-0.04em] text-[#303136] sm:text-[34px]">让智能体把想法变成现实</h1>
                        <p className="mt-2 text-center text-base text-slate-500">随时发起任务，在本地安全完成协作</p>

                        <div className="mt-5 flex items-center gap-3 text-lg font-semibold sm:text-xl">
                            <span className="text-slate-400">开始</span>
                            <div className="flex rounded-full bg-[#e9e9eb] p-1.5 text-sm shadow-inner">
                                <button
                                    type="button"
                                    onClick={() => setMode('work')}
                                    className={`flex items-center gap-2 rounded-full px-4 py-2.5 font-medium transition-all ${mode === 'work' ? 'bg-[#17171a] text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
                                >
                                    <Code2 size={17} />
                                    智能协作
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setMode('life')}
                                    className={`flex items-center gap-2 rounded-full px-4 py-2.5 font-medium transition-all ${mode === 'life' ? 'bg-[#17171a] text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
                                >
                                    <BriefcaseBusiness size={17} />
                                    日常办公
                                </button>
                            </div>
                            <span className="hidden text-slate-400 sm:inline">任务</span>
                        </div>

                        <div className="mt-4 flex w-full max-w-5xl flex-wrap justify-center gap-2.5">
                            {taskTags.map(tag => {
                                const Icon = tag.icon;
                                return (
                                    <button
                                        key={tag.label}
                                        type="button"
                                        onClick={() => setDraft(tag.prompt)}
                                        className="flex items-center gap-2 rounded-full bg-[#e9e9eb] px-4 py-2.5 text-sm font-medium text-[#494a4f] transition-all hover:-translate-y-0.5 hover:bg-[#dedee1] hover:shadow-sm"
                                    >
                                        <Icon size={17} strokeWidth={2} />
                                        {tag.label}
                                    </button>
                                );
                            })}
                        </div>
                    </div>

                    <div className="mx-auto mt-3 w-full max-w-5xl">
                        <div className="rounded-[28px] border border-[#ebebed] bg-[#f4f4f5] p-3 shadow-[0_8px_24px_rgba(15,23,42,0.04)] transition-colors focus-within:border-slate-300 focus-within:bg-[#f1f1f2]">
                            <div className="flex items-center gap-2 px-2 pb-1.5 text-slate-500">
                                <span className="rounded-md p-1.5 transition-colors hover:bg-white"><Bot size={18} /></span>
                                <span className="rounded-md p-1.5 transition-colors hover:bg-white"><Paperclip size={18} /></span>
                            </div>
                            <textarea
                                value={draft}
                                onChange={(event) => setDraft(event.target.value)}
                                onKeyDown={(event) => {
                                    if (event.key === 'Enter' && !event.shiftKey) {
                                        event.preventDefault();
                                        startTask();
                                    }
                                }}
                                placeholder={mode === 'work' ? '描述你希望 Agent 完成的任务...' : '输入日常办公需求...'}
                                rows={2}
                                className="w-full resize-none bg-transparent px-3 py-2 text-base leading-7 text-slate-700 outline-none placeholder:text-slate-400"
                            />
                            <div className="flex flex-wrap items-center justify-between gap-2 px-1 pt-1">
                                <div className="relative">
                                    <button
                                        type="button"
                                        onClick={() => setIsAgentMenuOpen(open => !open)}
                                        className="flex items-center gap-2 rounded-lg bg-[#e3e3e5] px-3 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-[#d8d8db]"
                                    >
                                        <Bot size={16} />
                                        <span className="max-w-40 truncate">{selectedAgent?.name || '自动选择 Agent'}</span>
                                        <ChevronDown size={15} />
                                    </button>
                                    {isAgentMenuOpen && (
                                        <div className="absolute bottom-11 left-0 z-20 max-h-56 w-64 overflow-y-auto rounded-xl border border-slate-200 bg-white p-1.5 shadow-xl">
                                            <button type="button" onClick={() => { setSelectedAgentId(undefined); setIsAgentMenuOpen(false); }} className="w-full rounded-lg px-3 py-2 text-left text-sm text-slate-600 hover:bg-slate-100">自动选择 Agent</button>
                                            {agents.map(agent => (
                                                <button key={agent.id} type="button" onClick={() => { setSelectedAgentId(agent.id); setIsAgentMenuOpen(false); }} className="w-full truncate rounded-lg px-3 py-2 text-left text-sm text-slate-700 hover:bg-slate-100">{agent.name}</button>
                                            ))}
                                        </div>
                                    )}
                                </div>
                                <div className="flex items-center gap-3">
                                    <button type="button" className="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-slate-500 transition-colors hover:bg-[#e3e3e5]">
                                        <Folder size={17} />
                                        工作区
                                    </button>
                                    <button
                                        type="button"
                                        onClick={startTask}
                                        className="flex h-10 w-10 items-center justify-center rounded-full bg-[#202126] text-white shadow-sm transition-transform hover:scale-105 hover:bg-black active:scale-95"
                                        title="开始任务"
                                    >
                                        <Send size={17} />
                                    </button>
                                </div>
                            </div>
                        </div>
                        <p className="mt-3 text-center text-xs text-slate-400">内容由 AI 生成，请核实重要信息。</p>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default ArkAgentsPage;
