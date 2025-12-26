#!/usr/bin/env python3
import subprocess
import datetime
import os
import sys

def get_git_diff():
    try:
        # Get list of changed files
        files = subprocess.check_output(['git', 'diff', '--name-status', 'HEAD']).decode('utf-8')
        return files
    except Exception as e:
        return f"Error getting diff: {e}"

def generate_record():
    date_str = datetime.date.today().strftime("%Y-%m-%d")
    diff_output = get_git_diff()
    
    record_template = f"""# 变更记录 - {date_str}

## 1. 变更摘要
[请在此填写变更的核心内容]

## 2. 影响范围
### 修改文件列表:
```text
{diff_output}
```

### 业务影响:
[说明对业务逻辑或现有功能的影响]

## 3. 验证情况
- [ ] 本地自测已通过
- [ ] 关键路径回归已完成

## 4. 回滚方案
- 回滚命令: `git revert HEAD`
"""
    
    # Define file path
    filename = f"docs/release-notes/{date_str}.md"
    
    # Write to file
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(record_template)
    
    print(f"✅ 记录模板已生成: {filename}")
    print("请手动或由 AI 补全摘要及影响说明内容。")

if __name__ == "__main__":
    if not os.path.exists('docs/release-notes'):
        os.makedirs('docs/release-notes')
    generate_record()
