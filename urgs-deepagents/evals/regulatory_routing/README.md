# 监管 Agent 多轮路由评测

本评测验证 `regulatory-data-query-agent`、`regulatory-knowledge-agent` 和 `general-agent` 在首轮问题、多轮续问和任务切换中的选择结果。

启动 `urgs-deepagents` 后执行：

```bash
cd urgs-deepagents
uv run --frozen python evals/regulatory_routing/run_eval.py
```

重复运行每个问题可观察模型路由稳定性：

```bash
uv run --frozen python evals/regulatory_routing/run_eval.py --repeat 3
```

结果以 JSONL 保存，包含路由响应、耗时和逐项评分。
