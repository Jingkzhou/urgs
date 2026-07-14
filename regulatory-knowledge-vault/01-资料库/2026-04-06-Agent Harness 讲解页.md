# Agent Harness 讲解页

## 元信息

- 来源：`/Users/work/Documents/GitHub/microharness-main/1-agent_harness_explainer.html`
- 作者：待补充
- 发布时间：页面标注为 2026.03
- 获取日期：2026-04-06
- 类型：概念讲解 / Agent 基础设施 / 学习资料

## 核心观点

- Agent Harness 是包裹在 AI 模型外层的软件基础设施，负责运行控制、记忆管理、工具使用和安全边界。
- 模型像“大脑”，Harness 更像让大脑能够稳定工作的“身体 + 环境”。
- 没有 Harness，AI 在长任务中容易遗忘目标、陷入循环、错误累积并越过安全边界。
- 一个完整 Harness 的关键模块通常包括：系统提示注入、上下文管理、工具管理、迭代控制、风险拦截与日志追踪。
- 同一个模型在有良好 Harness 的情况下，实际长任务表现往往显著优于“裸模型”。

## 关键摘录

- 模型决定“做什么”和“为什么”，Harness 决定“怎么做”和“在哪里做”。
- 在 Agent 系统里，Framework、Runtime、Harness 不是一回事，而是不同层级。
- 更强的模型配更弱的 Harness，不一定优于稍弱模型配精心设计的 Harness。

## 可更新页面

- [[02-主题/Agent Harness|Agent Harness]]
- [[02-主题/LLM Wiki|LLM Wiki]]
- [[04-综合/LLM Wiki-搭建路线图|LLM Wiki-搭建路线图]]
- [[06-项目/我的 LLM Wiki 搭建|我的 LLM Wiki 搭建]]

## 关联页面

- [[00-首页/index|首页]]

## 备注

- 本页基于本地 HTML 讲解页整理，不是论文原文。
- 其中提到的案例包括 Stripe、Anthropic Claude Code 和相关研究结论，后续可继续补原始出处。
