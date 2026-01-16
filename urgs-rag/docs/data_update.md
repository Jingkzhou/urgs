# 数据更新与索引重建流程

## 数据更新
- 新增数据：将新文件放入 `doc_store/<collection_name>/`。
- 删除数据：移除对应文件，并使用 `POST /api/rag/ingest?collection_name=xxx&filenames=...` 重新入库。

## 索引重建
- 全量重建：
  1. `POST /api/rag/reset?collection_name=xxx`
  2. `POST /api/rag/ingest?collection_name=xxx&enable_qa_generation=true`

## 验证
- 使用 `eval/eval_runner.py` 进行基线回归。
- 抽样问题验证 Top-k 命中与回答结构化输出。
