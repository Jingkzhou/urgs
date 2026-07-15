# 监管集市智能助手真实场景评测

该评测使用当前配置的真实模型、`regulatory-market-assistant` 运行时 Skill 和本地监管集市 API，不使用模拟回答或模拟工具结果。

## 覆盖范围

- 30 个场景：表咨询、字段码值、多表关系、指标开发、SQL 校验、多轮衔接、权限范围、能力边界、只读安全、抗注入和抗幻觉。
- 同时记录最终回答、耗时、工具调用、工具参数、工具结果和确定性断言。
- `source_truth` 用于人工复核；确定性断言用于稳定回归，不代替业务专家验收。

## 运行方式

先启动包含监管集市内部接口的 `urgs-api`，然后在仓库根目录执行：

```bash
urgs-deepagents/.venv/bin/python \
  urgs-deepagents/evals/regulatory_market_assistant/run_eval.py
```

指定临时 API、题目和结果文件：

```bash
urgs-deepagents/.venv/bin/python \
  urgs-deepagents/evals/regulatory_market_assistant/run_eval.py \
  --api-url http://127.0.0.1:18080 \
  --ids RMA-001,RMA-016,RMA-029 \
  --result urgs-deepagents/evals/regulatory_market_assistant/results/baseline.jsonl
```

中断后续跑：

```bash
urgs-deepagents/.venv/bin/python \
  urgs-deepagents/evals/regulatory_market_assistant/run_eval.py \
  --api-url http://127.0.0.1:18080 \
  --result urgs-deepagents/evals/regulatory_market_assistant/results/baseline.jsonl \
  --resume
```

只按最新断言重算已有结果：

```bash
urgs-deepagents/.venv/bin/python \
  urgs-deepagents/evals/regulatory_market_assistant/run_eval.py \
  --result urgs-deepagents/evals/regulatory_market_assistant/results/baseline.jsonl \
  --regrade-only
```

结果默认写入 `results/run-<时间>.jsonl`。退出码 0 表示本次全部确定性门禁通过。
