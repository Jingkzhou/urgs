---
type: 主题
keywords: [Agent Harness, Agent, 工具调用, 记忆管理, 上下文管理]
---

# Agent Harness

## 定义

Agent Harness 是包裹在 AI 模型外层的软件基础设施，用来管理模型的运行方式、上下文、工具调用、安全边界和执行流程。

它本身不是模型能力，而是把模型组织成一个可以稳定完成长任务的系统外壳。

## 当前结论

- Harness 的核心价值在于把“会回答”的模型，变成“能持续执行任务”的代理系统。
- 在多步骤、长上下文、高风险操作场景下，Harness 往往比单纯换更强模型更关键。
- Agent 系统至少要考虑六类能力：提示注入、记忆管理、工具调度、迭代控制、安全确认、日志追踪。
- Claude Code 这类产品可以视为通用 Agent Harness 的典型实现思路。

## 关键问题

- Harness 与 framework、runtime 的边界应该如何区分？
- 什么场景只需要简单工具调用，什么场景必须引入完整 Harness？
- 记忆裁剪、循环检测和人工确认的策略该怎么设计？
- 如果要自己搭一个 Harness，最小可用版本包含哪些模块？

## 争议与待确认

- 不同团队对 “Harness / Runtime / Agent Framework” 的命名边界并不统一。
- 某些产品会把其中几层打包成一个概念，需要在具体上下文中区分。
- 当前资料是解释性页面，后续最好补充更原始的一手来源和实现案例。

## 关联实体

- [[03-实体/Obsidian|Obsidian]]

## 关联资料

- [[01-资料库/2026-04-06-Agent Harness 讲解页|Agent Harness 讲解页]]

## 下一步

- 补一页 “Harness vs Framework vs Runtime” 的对比页。
- 收集 Claude Code、Stripe Minions 等具体案例。
- 结合你自己的学习，整理一份“最小可用 Agent Harness 设计清单”。
