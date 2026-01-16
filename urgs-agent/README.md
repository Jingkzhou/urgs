# urgs-agent

URGS 的智能编排服务，负责对话管理、LangGraph 状态机编排、工具调用循环、审批与审计输出。模块目标：把用户意图转成受控的工具调用序列，并产出可审计、可回放、可确认的执行结果。

## 快速开始

```bash
cd urgs-agent
pip install -e ".[dev]"
uvicorn app.main:app --reload
```

环境变量主要通过 `core/config.py` 定义，至少需要配置模型与工具端点，例如：

```bash
export OPENAI_BASE_URL=http://localhost:11434/v1
export OPENAI_API_KEY=dummy
export MODEL_NAME=qwen3
```

## 目录结构

- `app/`：FastAPI 入口与路由（chat、sessions、approvals、health），中间件封装 trace_id、鉴权等。
- `core/`：配置、日志、错误定义。
- `llm/`：模型客户端封装与系统提示词。
- `agent/`：LangGraph 定义、状态结构、策略（工具白名单、审批、注入防护）、运行时（执行器、工具注册）。
- `storage/`：会话与审计存储适配层（内存/Redis/MySQL）。
- `schemas/`：API 与 SSE 事件的 Pydantic 模型。
- `tests/`：策略、图状态与接口的最小单测占位。

## 功能概览

- /chat 与 /chat/stream（SSE）对接模型与工具调用循环，支持 NEED_APPROVAL 中断与回放。
- /approvals/* 确认写操作后恢复状态机继续执行。
- /sessions/* 提供会话摘要与事件回放。
- trace_id 全链路：日志、SSE、审计事件保持一致。
- 工具层通过 MCP 适配，带白名单、写操作判定、参数约束，写操作强制审批。

## 状态机要点

- 节点：ingest → classify_intent → draft_plan → select_tool → precheck_policy → maybe_require_approval → execute_tool → reflect → finalize（纯问答可直接 finalize）。
- AgentState 记录 messages、context、plan、tool_budget、pending_approval、audit_trace_id、final_answer。
- 审计事件覆盖 plan_created、tool_called/returned、approval_created/approved/rejected、final_answer、error。
