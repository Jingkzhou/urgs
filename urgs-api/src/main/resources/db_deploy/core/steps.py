import os
import re
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
                    sql_content = f.read()
                    statements = [s.strip() for s in sql_content.split(";") if s.strip()]

                    log.info(f"正在执行 SQL 文件: {file_rel_path} (目标: {target}, 语句数: {len(statements)})")
                    for sql in statements:
                        conn.execute(sql)
                        executed_count += 1
        return {"statements_executed": executed_count}

class ExecuteSQLOrderedHandler(BaseHandler):
    """按文件名升序扫描目录并执行 SQL 文件"""
    def run(self, working_dir: str, targets: list, params: dict, conn_config: dict, log):
        source_dir = params.get("source_dir", "sql")
        dir_path = os.path.join(working_dir, source_dir)

        if not os.path.isdir(dir_path):
            log.warn(f"目录不存在，跳过: {source_dir}")
            return {"statements_executed": 0, "files_executed": 0}

        # 扫描并排序 .sql 文件
        sql_files = sorted([f for f in os.listdir(dir_path) if f.endswith(".sql")])

        if not sql_files:
            log.warn(f"目录 {source_dir} 中未找到 .sql 文件")
            return {"statements_executed": 0, "files_executed": 0}

        executed_count = 0
        files_executed = 0

        for target in targets:
            conn = ConnectorFactory.get_connector(target, conn_config)
            for sql_file in sql_files:
                full_path = os.path.join(dir_path, sql_file)
                with open(full_path, "r", encoding="utf-8") as f:
                    sql_content = f.read()
                    statements = [s.strip() for s in sql_content.split(";") if s.strip()]

                    log.info(f"执行 SQL: {source_dir}/{sql_file} (目标: {target}, 语句数: {len(statements)})")
                    for sql in statements:
                        conn.execute(sql)
                        executed_count += 1
                    files_executed += 1
                    log.info(f"完成: {source_dir}/{sql_file}")

        return {"statements_executed": executed_count, "files_executed": files_executed}

class DeployProceduresHandler(BaseHandler):
    """部署存储过程 - 每个文件作为整体执行（不按分号分割）"""
    def run(self, working_dir: str, targets: list, params: dict, conn_config: dict, log):
        source_dir = params.get("source_dir", "procedures")
        dir_path = os.path.join(working_dir, source_dir)

        if not os.path.isdir(dir_path):
            log.warn(f"目录不存在，跳过: {source_dir}")
            return {"procedures_deployed": 0}

        sql_files = sorted([f for f in os.listdir(dir_path) if f.endswith(".sql")])

        if not sql_files:
            log.warn(f"目录 {source_dir} 中未找到 .sql 文件")
            return {"procedures_deployed": 0}

        deployed = 0
        for target in targets:
            conn = ConnectorFactory.get_connector(target, conn_config)
            for sql_file in sql_files:
                full_path = os.path.join(dir_path, sql_file)
                with open(full_path, "r", encoding="utf-8") as f:
                    content = f.read().strip()

                # 移除末尾的 / (Oracle 的语句终止符)
                if content.endswith("/"):
                    content = content[:-1].strip()

                proc_name = sql_file.replace(".sql", "")
                log.info(f"部署存储过程: {proc_name} (目标: {target})")
                conn.execute(content)
                deployed += 1
                log.info(f"完成: {proc_name}")

        return {"procedures_deployed": deployed}

class RestoreProcedureBackupsHandler(BaseHandler):
    """恢复生产执行前备份的存储过程"""
    def run(self, working_dir: str, targets: list, params: dict, conn_config: dict, log):
        backup_dir = params.get("backup_dir", "production_procedure_backup")
        restored = 0
        restored_files = []

        for target in targets:
            safe_target = re.sub(r"[^A-Za-z0-9_.-]+", "_", target)
            target_dir = os.path.join(working_dir, backup_dir, safe_target)
            if not os.path.isdir(target_dir):
                raise RuntimeError(f"生产执行前存储过程备份目录不存在: {backup_dir}/{safe_target}")

            sql_files = []
            for root, _, files in os.walk(target_dir):
                for file_name in files:
                    if file_name.endswith(".sql"):
                        sql_files.append(os.path.join(root, file_name))
            sql_files.sort()

            if not sql_files:
                raise RuntimeError(f"生产执行前存储过程备份目录为空: {backup_dir}/{safe_target}")

            conn = ConnectorFactory.get_connector(target, conn_config)
            for full_path in sql_files:
                with open(full_path, "r", encoding="utf-8") as f:
                    content = f.read().strip()
                if content.endswith("/"):
                    content = content[:-1].strip()
                if not content:
                    raise RuntimeError(f"生产执行前存储过程备份为空: {full_path}")

                rel_path = os.path.relpath(full_path, working_dir)
                log.info(f"恢复生产执行前存储过程: {rel_path} (目标: {target})")
                conn.execute(content)
                restored += 1
                restored_files.append(rel_path)

        return {"procedures_restored": restored, "files": restored_files}

class ExportAndCompareProceduresHandler(BaseHandler):
    """
    导出并备份生产数据库中的存储过程源码，与包内的上一版本（prev_procedures/）对比。
    如果不一致，说明生产与 Git 不同步，停止部署。
    """
    def run(self, working_dir: str, targets: list, params: dict, conn_config: dict, log):
        procedure_names = params.get("procedure_names", [])
        expected_source_dir = params.get("expected_source_dir", "prev_procedures")
        production_backup_dir = params.get("production_backup_dir", "production_procedure_backup")
        on_mismatch = params.get("on_mismatch", "abort")

        if not procedure_names:
            log.info("无需校验的存储过程，跳过")
            return {"checked": 0, "matched": 0}

        checked = 0
        matched = 0
        mismatches = []

        for target in targets:
            conn = ConnectorFactory.get_connector(target, conn_config)
            db_type = conn_config.get(target, {}).get("type", "oracle").lower()

            for proc_name in procedure_names:
                checked += 1
                log.info(f"校验存储过程: {proc_name} (目标: {target})")

                # 从数据库导出存储过程源码
                prod_source = self._export_procedure(conn, db_type, proc_name, log)
                production_backup_path = self._write_production_backup(
                    working_dir, production_backup_dir, target, proc_name, prod_source
                )

                # 读取包内的基线版本
                expected_path = os.path.join(working_dir, expected_source_dir, f"{proc_name}.sql")
                if not os.path.exists(expected_path):
                    mismatches.append(proc_name)
                    log.error(
                        f"基线文件不存在: {expected_source_dir}/{proc_name}.sql。"
                        "生产中的版本与GitLab中的投产前版本不一致，停止投产"
                    )
                    continue

                with open(expected_path, "r", encoding="utf-8") as f:
                    expected_source = f.read()

                if not prod_source:
                    mismatches.append(proc_name)
                    log.error(
                        f"生产库未导出存储过程 '{proc_name}'，生产备份文件: {production_backup_path}。"
                        "生产中的版本与GitLab中的投产前版本不一致，停止投产"
                    )
                    continue

                with open(production_backup_path, "r", encoding="utf-8") as f:
                    production_backup_source = f.read()

                # 规范化后对比：生产运行时备份 vs 上一 Tag 基线
                norm_prod = self._normalize(production_backup_source)
                norm_expected = self._normalize(expected_source)

                if norm_prod == norm_expected:
                    matched += 1
                    log.info(f"校验通过: {proc_name}，生产备份文件: {production_backup_path}")
                else:
                    mismatches.append(proc_name)
                    log.error(
                        f"不一致: 生产存储过程 '{proc_name}' 与 GitLab 投产前版本不匹配。"
                        f"生产备份文件: {production_backup_path}。"
                        "生产中的版本与GitLab中的投产前版本不一致，停止投产"
                    )

        if mismatches:
            msg = (
                f"生产中的版本与GitLab中的投产前版本不一致: {', '.join(mismatches)}。"
                "停止投产，未执行备份和正式部署。"
            )
            if on_mismatch == "abort":
                raise RuntimeError(msg)
            else:
                log.warn(msg)

        return {"checked": checked, "matched": matched, "mismatches": mismatches}

    def _write_production_backup(self, working_dir: str, backup_dir: str, target: str, proc_name: str, source: str) -> str:
        safe_target = re.sub(r"[^A-Za-z0-9_.-]+", "_", target)
        safe_proc_parts = [
            re.sub(r"[^A-Za-z0-9_.-]+", "_", part)
            for part in proc_name.split("/")
            if part not in ("", ".", "..")
        ]
        safe_proc_path = os.path.join(*safe_proc_parts) if safe_proc_parts else "unknown"
        backup_path = os.path.join(working_dir, backup_dir, safe_target, f"{safe_proc_path}.sql")
        os.makedirs(os.path.dirname(backup_path), exist_ok=True)
        with open(backup_path, "w", encoding="utf-8") as f:
            f.write(source or "")
        return backup_path

    def _export_procedure(self, conn, db_type: str, proc_name: str, log) -> str:
        """从数据库导出存储过程源码"""
        try:
            if db_type == "oracle":
                # Oracle: 从 ALL_SOURCE 表获取源码
                rows = conn.fetch(
                    "SELECT TEXT FROM ALL_SOURCE WHERE NAME = :1 "
                    "AND TYPE IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION') "
                    "ORDER BY TYPE, LINE",
                    [proc_name.upper()]
                )
                return "".join(row[0] for row in rows) if rows else ""

            elif db_type in ("mysql", "gbase"):
                # MySQL/GBase: 先尝试 PROCEDURE，再尝试 FUNCTION
                try:
                    rows = conn.fetch(f"SHOW CREATE PROCEDURE `{proc_name}`")
                    if rows:
                        return rows[0][2] if len(rows[0]) > 2 else str(rows[0][1])
                except Exception:
                    pass
                try:
                    rows = conn.fetch(f"SHOW CREATE FUNCTION `{proc_name}`")
                    if rows:
                        return rows[0][2] if len(rows[0]) > 2 else str(rows[0][1])
                except Exception:
                    pass
                return ""

            else:
                log.warn(f"不支持的数据库类型 {db_type}，跳过导出")
                return ""
        except Exception as e:
            log.error(f"导出存储过程 {proc_name} 失败: {str(e)}")
            return ""

    def _normalize(self, source: str) -> str:
        """规范化源码用于对比：去除首尾空白、统一换行、移除空行和行内多余空白"""
        if not source:
            return ""
        # 统一换行符
        text = source.replace("\r\n", "\n").replace("\r", "\n")
        # 每行去除首尾空白，去除空行
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        # 合并多余空白
        return "\n".join(lines).lower()

class PostCheckHandler(BaseHandler):
    def run(self, working_dir: str, targets: list, params: dict, conn_config: dict, log):
        query = params.get("query")
        results = []
        for target in targets:
            conn = ConnectorFactory.get_connector(target, conn_config)
            log.info(f"执行后置校验: {query} (目标: {target})")
            conn.execute(query)
            results.append({"target": target, "status": "executed"})
        return {"check_results": results}

class StepHandlerFactory:
    _handlers = {
        "execute_sql": ExecuteSQLHandler(),
        "execute_sql_ordered": ExecuteSQLOrderedHandler(),
        "deploy_procedures": DeployProceduresHandler(),
        "restore_procedure_backups": RestoreProcedureBackupsHandler(),
        "export_and_compare_procedures": ExportAndCompareProceduresHandler(),
        "post_check": PostCheckHandler()
    }

    @classmethod
    def get_handler(cls, stype: str):
        handler = cls._handlers.get(stype)
        if not handler:
            raise ValueError(f"Unknown step type: {stype}")
        return handler
