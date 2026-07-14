# 监管助手真实问题评测

该评测直接使用本地 `urgs-deepagents` 运行时、当前配置的真实模型和 `regulatory-knowledge-vault`，不使用模拟回答。

## 覆盖范围

- 30 个真实问题：单表事实、字段口径、跨表关系、业务影响评估、证据不足、只读安全和抗幻觉。
- 每题保存完整答案、耗时、工具调用次数、错误和确定性断言结果。
- 断言只作为稳定回归门禁；复杂场景仍需结合 `source_truth` 做人工复核。

## 运行方式

在仓库根目录执行：

```bash
urgs-deepagents/.venv/bin/python urgs-deepagents/evals/regulatory_knowledge/run_eval.py
```

使用指定 Agent 配置迁移脚本运行：

```bash
urgs-deepagents/.venv/bin/python urgs-deepagents/evals/regulatory_knowledge/run_eval.py \
  --prompt-sql urgs-api/src/main/resources/db/migration/V104__Optimize_Regulatory_Knowledge_Agent.sql
```

长时间全量评测建议指定结果文件并启用续跑：

```bash
urgs-deepagents/.venv/bin/python urgs-deepagents/evals/regulatory_knowledge/run_eval.py \
  --prompt-sql urgs-api/src/main/resources/db/migration/V105__Refine_Regulatory_Knowledge_Agent_Retrieval.sql \
  --result urgs-deepagents/evals/regulatory_knowledge/results/final-v105.jsonl \
  --resume
```

快速运行单题或一组题：

```bash
urgs-deepagents/.venv/bin/python urgs-deepagents/evals/regulatory_knowledge/run_eval.py \
  --ids RK-001,RK-021,RK-027
```

结果默认写入 `results/run-<时间>.jsonl`。退出码为 0 表示本次所有确定性门禁通过，否则为 1。
考虑本地模型推理速度，默认不限制单题时长；如需为异常排查设置保护时限，可通过
`--question-timeout-seconds` 指定秒数。
