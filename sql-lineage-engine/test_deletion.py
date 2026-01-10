#!/usr/bin/env python3
"""
测试血缘删除逻辑的脚本
验证智能删除是否正确工作
"""

import sys
sys.path.insert(0, '/Users/work/Documents/JLbankGit/urgs/sql-lineage-engine')

from exporters.neo4j import Neo4jClient

def test_smart_deletion():
    """测试智能删除逻辑"""
    
    print("=" * 60)
    print("测试血缘删除逻辑")
    print("=" * 60)
    
    # 初始化 Neo4j 客户端
    client = Neo4jClient()
    
    try:
        # 1. 创建测试数据
        print("\n步骤 1: 创建测试数据...")
        test_repo_id = "test_repo_deletion"
        test_files = ["fileA.sql", "fileB.sql"]
        
        with client.driver.session() as session:
            # 创建测试表和字段
            session.run("""
                MERGE (t1:Table {name: 'TEST_TABLE_A'})
                MERGE (t2:Table {name: 'TEST_TABLE_B'})
                MERGE (c1:Column {name: 'COL1', table: 'TEST_TABLE_A'})
                MERGE (c2:Column {name: 'COL2', table: 'TEST_TABLE_B'})
                MERGE (c1)-[:BELONGS_TO]->(t1)
                MERGE (c2)-[:BELONGS_TO]->(t2)
            """)
            
            # 创建血缘关系，包含两个源文件
            session.run("""
                MATCH (c1:Column {name: 'COL1', table: 'TEST_TABLE_A'})
                MATCH (c2:Column {name: 'COL2', table: 'TEST_TABLE_B'})
                MERGE (c1)-[r:DERIVES_TO]->(c2)
                SET r.repoId = $repoId,
                    r.sourceFiles = $sourceFiles,
                    r.snippet = 'SELECT COL1 FROM TEST_TABLE_A'
            """, repoId=test_repo_id, sourceFiles=test_files)
            
            print(f"  ✓ 创建了测试关系，sourceFiles = {test_files}")
        
        # 2. 验证关系存在
        print("\n步骤 2: 验证关系存在...")
        with client.driver.session() as session:
            result = session.run("""
                MATCH (c1:Column {name: 'COL1', table: 'TEST_TABLE_A'})-[r:DERIVES_TO]->(c2:Column)
                WHERE r.repoId = $repoId
                RETURN r.sourceFiles as sourceFiles
            """, repoId=test_repo_id)
            
            record = result.single()
            if record:
                source_files = record["sourceFiles"]
                print(f"  ✓ 关系存在，sourceFiles = {source_files}")
                assert set(source_files) == set(test_files), "sourceFiles 不匹配"
            else:
                raise Exception("测试关系不存在！")
        
        # 3. 删除第一个文件
        print("\n步骤 3: 删除 fileA.sql...")
        client.clear_lineage_by_repo_files(test_repo_id, ["fileA.sql"])
        
        # 4. 验证关系仍然存在，但只有 fileB.sql
        print("\n步骤 4: 验证关系保留，只剩 fileB.sql...")
        with client.driver.session() as session:
            result = session.run("""
                MATCH (c1:Column {name: 'COL1', table: 'TEST_TABLE_A'})-[r:DERIVES_TO]->(c2:Column)
                WHERE r.repoId = $repoId
                RETURN r.sourceFiles as sourceFiles
            """, repoId=test_repo_id)
            
            record = result.single()
            if record:
                source_files = record["sourceFiles"]
                print(f"  ✓ 关系仍然存在，sourceFiles = {source_files}")
                assert source_files == ["fileB.sql"], f"sourceFiles 应该只有 fileB.sql，但实际是 {source_files}"
                print("  ✓ 验证通过：fileA.sql 已被移除，关系保留")
            else:
                raise Exception("关系被错误删除！应该保留 fileB.sql")
        
        # 5. 删除第二个文件
        print("\n步骤 5: 删除 fileB.sql...")
        client.clear_lineage_by_repo_files(test_repo_id, ["fileB.sql"])
        
        # 6. 验证关系已被删除
        print("\n步骤 6: 验证关系已被完全删除...")
        with client.driver.session() as session:
            result = session.run("""
                MATCH (c1:Column {name: 'COL1', table: 'TEST_TABLE_A'})-[r:DERIVES_TO]->(c2:Column)
                WHERE r.repoId = $repoId
                RETURN r
            """, repoId=test_repo_id)
            
            record = result.single()
            if record:
                raise Exception("关系应该被删除，但仍然存在！")
            else:
                print("  ✓ 关系已被完全删除")
                print("  ✓ 验证通过：所有 sourceFiles 被移除后，关系被删除")
        
        print("\n" + "=" * 60)
        print("✓ 所有测试通过！智能删除逻辑工作正常")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n✗ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    finally:
        # 清理测试数据
        print("\n清理测试数据...")
        with client.driver.session() as session:
            session.run("""
                MATCH (c1:Column {name: 'COL1', table: 'TEST_TABLE_A'})
                MATCH (c2:Column {name: 'COL2', table: 'TEST_TABLE_B'})
                MATCH (t1:Table {name: 'TEST_TABLE_A'})
                MATCH (t2:Table {name: 'TEST_TABLE_B'})
                DETACH DELETE c1, c2, t1, t2
            """)
        print("  ✓ 测试数据已清理")
        
        client.close()
    
    return True

if __name__ == "__main__":
    success = test_smart_deletion()
    sys.exit(0 if success else 1)
