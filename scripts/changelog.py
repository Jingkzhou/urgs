#!/usr/bin/env python3
import subprocess
import datetime
import os
import sys

def get_git_diff_staged():
    try:
        # Get list of staged files and their status
        files = subprocess.check_output(['git', 'diff', '--cached', '--name-status']).decode('utf-8')
        return files
    except Exception as e:
        return f"Error getting staged diff: {e}"

def infer_summary(diff_status):
    lines = diff_status.strip().split('\n')
    if not lines or (len(lines) == 1 and not lines[0]):
        return "代码清理或微调"
    
    components = set()
    features = []
    
    for line in lines:
        parts = line.split('\t')
        if len(parts) < 2: continue
        status, path = parts[0], parts[1]
        
        if 'urgs-api' in path: components.add('后端接口')
        elif 'urgs-web' in path: components.add('前端页面')
        elif 'sql-lineage' in path: components.add('血缘引擎')
        elif 'scripts' in path: components.add('工具脚本')
        
        # Infer feature from filename
        basename = os.path.basename(path)
        if 'Controller' in basename: features.append(f"更新 {basename} 接口逻辑")
        elif 'Service' in basename: features.append(f"优化 {basename} 业务处理")
        elif '.tsx' in path: features.append(f"调整 {basename} 界面交互")
        elif 'Dockerfile' in basename or 'docker-compose' in path: features.append("优化容器化部署配置")

    summary = "、".join(components) if components else "通用组件"
    detail = "；".join(features[:3]) # Limit to 3 items
    if len(features) > 3: detail += " 等"
    
    return f"{summary}: {detail}" if detail else f"{summary}: [AUTO_GEN] 进行了一系列代码变更"

def generate_record():
    date_str = datetime.date.today().strftime("%Y-%m-%d")
    diff_output = get_git_diff_staged()
    
    smart_summary = infer_summary(diff_output)
    
    record_template = f"""# 变更记录 - {date_str}

## 1. 变更摘要
{smart_summary}

## 2. 影响范围
### 修改文件列表:
```text
{diff_output}
```

### 业务影响:
基于代码变更分析 [AUTO_GEN]：本次主要涉及 {smart_summary.split(':')[0]}。
建议关注：相关功能的稳定性和接口调用是否正常。

## 3. 验证情况
- [x] 代码变更已同步
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
    
    print(f"✅ 变更记录已自动更新: {filename}")
    if "进行了一系列代码变更" in smart_summary:
        print("💡 建议: 可以根据实际业务逻辑进一步手动微调摘要内容。")

if __name__ == "__main__":
    if not os.path.exists('docs/release-notes'):
        os.makedirs('docs/release-notes')
    generate_record()
