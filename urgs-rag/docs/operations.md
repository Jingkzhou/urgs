# URGS-RAG 运维指南

## 上线检查清单
- 确认 `.env` 与 `app/config.py` 配置一致（LLM、ChromaDB、Neo4j）。
- 确认向量库目录与 DocStore 有读写权限。
- 确认评测脚本可运行且基线指标已记录。

## 启动与健康检查
- 启动服务：`uvicorn app.main:app --host 0.0.0.0 --port 8001`
- 健康检查：`GET /health`

## 数据入库流程
1. 将文件放入 `doc_store/<collection_name>/`。
2. 触发入库：`POST /api/rag/ingest?collection_name=xxx&enable_qa_generation=true`
3. 使用 `GET /api/rag/vector-db/collections` 检查库状态。

## 回滚流程
- 回滚代码：切换到稳定版本并重新部署。
- 回滚向量库：`POST /api/rag/reset?collection_name=xxx`。
- 回滚后复验：运行评测脚本与抽样查询。

## 监控与反馈
- 查询统计：`data/metrics/queries.jsonl`
- 用户反馈：`data/metrics/feedback.jsonl`
