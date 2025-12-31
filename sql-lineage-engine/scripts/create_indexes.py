#!/usr/bin/env python3
"""
Neo4j 索引创建脚本
用于手动创建血缘查询所需的索引，优化查询性能。

使用方法:
    python scripts/create_indexes.py

环境变量:
    NEO4J_URI: Neo4j 连接地址 (默认: bolt://localhost:7687)
    NEO4J_USERNAME: 用户名 (默认: neo4j)
    NEO4J_PASSWORD: 密码
"""

import sys
import os

# 添加项目根目录到 Python 路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from exporters.neo4j import Neo4jClient

def main():
    print("=" * 50)
    print("Neo4j 索引创建工具")
    print("=" * 50)
    
    try:
        client = Neo4jClient()
        print(f"已连接到 Neo4j: {client.uri}")
        print()
        
        # 创建索引
        client.ensure_indexes()
        
        # 显示当前索引状态
        print()
        print("当前索引列表:")
        print("-" * 50)
        with client.driver.session() as session:
            result = session.run("SHOW INDEXES")
            for record in result:
                name = record.get("name", "N/A")
                state = record.get("state", "N/A")
                labels = record.get("labelsOrTypes", [])
                props = record.get("properties", [])
                print(f"  {name}: {labels} -> {props} [{state}]")
        
        print()
        print("✓ 索引创建完成!")
        
        client.close()
        
    except Exception as e:
        print(f"✗ 错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
