#!/usr/bin/env python3
import sys
import datetime
import os
import re

def sync_msg_to_note(msg_file):
    date_str = datetime.date.today().strftime("%Y-%m-%d")
    note_path = f"docs/release-notes/{date_str}.md"
    
    if not os.path.exists(note_path):
        # If note doesn't exist, we don't sync, pre-commit should have handled it
        return

    with open(msg_file, 'r', encoding='utf-8') as f:
        full_msg = f.read().strip()
    
    # Extract the first line as the main summary, and the rest as details
    lines = full_msg.split('\n')
    summary = lines[0].strip()
    # Filter out template comments if any
    summary = re.sub(r'^#.*', '', summary).strip()
    if not summary:
        # Try to find the first non-comment line
        for l in lines:
            if not l.startswith('#') and l.strip():
                summary = l.strip()
                break

    if not summary:
        return

    # Read the current note
    with open(note_path, 'r', encoding='utf-8') as f:
        note_content = f.read()

    # Define the replacement logic for "变更摘要" section
    # If the current summary contains [AUTO_GEN], we definitely replace it.
    summary_pattern = r"(## 1\. 变更摘要\n).*?(\n## 2\. 影响范围)"
    
    def summary_replacer(match):
        header = match.group(1)
        old_summary = match.group(0)
        footer = match.group(2)
        if "[AUTO_GEN]" in old_summary or "进行了一系列代码变更" in old_summary:
            return f"{header}{summary}{footer}"
        return old_summary

    new_content = re.sub(summary_pattern, summary_replacer, note_content, flags=re.DOTALL)

    # Also update "业务影响" if it contains [AUTO_GEN]
    if len(lines) > 1:
        details = "\n".join([l for l in lines[1:] if not l.startswith('#') and l.strip()])
        if not details:
            details = "已完成相关功能开发与部署逻辑调整。"
            
        impact_pattern = r"(### 业务影响:\n).*?(\n## 3\. 验证情况)"
        
        def impact_replacer(match):
            header = match.group(1)
            old_impact = match.group(0)
            footer = match.group(2)
            if "[AUTO_GEN]" in old_impact:
                return f"{header}基于提交说明：{details}{footer}"
            return old_impact

        new_content = re.sub(impact_pattern, impact_replacer, new_content, flags=re.DOTALL)
    else:
        # Fallback if no details but has [AUTO_GEN]
        impact_pattern = r"(### 业务影响:\n).*?(\n## 3\. 验证情况)"
        new_content = re.sub(impact_pattern, r"\1已同步更新开发日志。\2", new_content, flags=re.DOTALL)

    with open(note_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        sync_msg_to_note(sys.argv[1])
