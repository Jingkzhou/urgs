# 评测集与指标说明

## 评测集
- `eval_set.json`：基础评测集，包含问题、标准答案与证据来源。
- 字段说明：
  - `id`：问题编号
  - `question`：用户问题
  - `answer`：标准答案或标准描述
  - `source`：证据来源（文件名或标识）
  - `type`：问题类型（definition/naming/generic）

## 指标定义
- **Hit@K**：检索 Top-K 是否命中来源证据。
- **MRR**：首个命中排名的倒数。
- **Coverage**：有返回结果的问题占比。
- **Answerability**：低置信问题比例。

## 使用建议
- 可先跑检索评测（Hit@K/MRR），再结合人工评测判断回答质量。
- 评测集需持续补充高质量问题与标准答案。
