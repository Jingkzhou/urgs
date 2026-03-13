import os
from db_deploy.connectors.factory import ConnectorFactory

class BaseHandler:
    def run(self, working_dir: str, targets: list, params: dict, conn_config: dict, log):
        raise NotImplementedError()

class ExecuteSQLHandler(BaseHandler):
    def run(self, working_dir: str, targets: list, params: dict, conn_config: dict, log):
        files = params.get("files", [])
        executed_count = 0
        for target in targets:
            conn = ConnectorFactory.get_connector(target, conn_config)
            for file_rel_path in files:
                full_path = os.path.join(working_dir, file_rel_path)
                with open(full_path, "r", encoding="utf-8") as f:
                    # 简单分割 SQL（生产环境建议使用 sqlparse 增强）
                    sql_content = f.read()
                    statements = [s.strip() for s in sql_content.split(";") if s.strip()]
                    
                    log.info(f"正在执行 SQL 文件: {file_rel_path} (目标: {target}, 语句数: {len(statements)})")
                    for sql in statements:
                        conn.execute(sql)
                        executed_count += 1
        return {"statements_executed": executed_count}

class BackupTableHandler(BaseHandler):
    def run(self, working_dir: str, targets: list, params: dict, conn_config: dict, log):
        tables = params.get("tables", [])
        timestamp = os.path.basename(working_dir).split("_")[-1] # 尝试获取时间戳
        processed = []
        for target in targets:
            conn = ConnectorFactory.get_connector(target, conn_config)
            for table in tables:
                bak_table = f"BAK_{table}_{timestamp}"
                sql = f"CREATE TABLE {bak_table} AS SELECT * FROM {table}"
                log.info(f"备份表: {table} -> {bak_table} (目标: {target})")
                rows = conn.execute(sql)
                processed.append({"src": table, "bak": bak_table, "target": target})
        return {"backed_up_tables": processed}

class PostCheckHandler(BaseHandler):
    def run(self, working_dir: str, targets: list, params: dict, conn_config: dict, log):
        query = params.get("query")
        results = []
        for target in targets:
            conn = ConnectorFactory.get_connector(target, conn_config)
            log.info(f"执行后置校验: {query} (目标: {target})")
            # 这里简化处理，实际可能需要返回查询结果集
            conn.execute(query)
            results.append({"target": target, "status": "executed"})
        return {"check_results": results}

class StepHandlerFactory:
    _handlers = {
        "execute_sql": ExecuteSQLHandler(),
        "backup_table": BackupTableHandler(),
        "post_check": PostCheckHandler()
    }

    @classmethod
    def get_handler(cls, stype: str):
        handler = cls._handlers.get(stype)
        if not handler:
            raise ValueError(f"Unknown step type: {stype}")
        return handler
