# regulatory-data-query-agent 评测

本评测复用 Flyway V90/V106 写入的 `regulatory_test_summary` 与 `regulatory_test_detail` 测试数据，验证 Agent 的工具选择、参数、回答内容和安全边界。

先启动 `urgs-api`（8080）和 `urgs-deepagents`（8003），再执行：

```bash
cd urgs-deepagents
uv run python evals/regulatory_data_query/run_eval.py
```

常用参数：

```bash
uv run python evals/regulatory_data_query/run_eval.py --ids RDQ-004,RDQ-009
uv run python evals/regulatory_data_query/run_eval.py --result evals/regulatory_data_query/results/local.jsonl
uv run python evals/regulatory_data_query/run_eval.py --result evals/regulatory_data_query/results/local.jsonl --regrade-only
```

结果为 JSONL，每题保留最终回答、工具名、工具参数、工具结果摘要和逐项评分，便于比较优化前后差异。
