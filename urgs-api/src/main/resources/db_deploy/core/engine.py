import os
import json
import zipfile
import hashlib
import shutil
from datetime import datetime
from db_deploy.logger.deploy_logger import DeployLogger
from db_deploy.connectors.factory import ConnectorFactory
from db_deploy.core.steps import StepHandlerFactory

class DeployEngine:
    def __init__(self, pkg_path: str, operator: str, conn_config_path: str = None):
        self.pkg_path = pkg_path
        self.operator = operator
        self.is_zip = pkg_path.endswith(".zip")
        self.working_dir = pkg_path

        # 确定解压目录
        if self.is_zip:
            self.working_dir = pkg_path.replace(".zip", "_extracted")

        self.log = DeployLogger(self.working_dir)
        self.conn_config_path = conn_config_path
        self.conn_config = None  # 延迟加载，check() 之后才能读 manifest
        self.state_file = os.path.join(self.working_dir, ".meta", "deploy_state.json")

    def _load_conn_config(self):
        """
        加载数据库连接配置
        优先级: manifest.json 内嵌 connections > 外部配置文件 > 默认路径
        """
        # 先尝试从 manifest 中读取内嵌的 connections
        manifest = self._load_manifest()
        if manifest and "connections" in manifest and manifest["connections"]:
            self.log.info("使用 manifest 内嵌的数据库连接配置")
            return manifest["connections"]

        # fallback 到外部配置文件
        path = self.conn_config_path
        if not path:
            path = os.path.expanduser("~/.db_deploy/connections.json")
        if not os.path.exists(path):
            raise FileNotFoundError(f"Connection config not found: {path}")
        self.log.info(f"使用外部数据库连接配置: {path}")
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)

    def check(self) -> bool:
        self.log.section("PRE-FLIGHT CHECK")
        try:
            # 1. 解压 (如果需要)
            if self.is_zip:
                self.log.info(f"正在解压: {self.pkg_path} -> {self.working_dir}")
                with zipfile.ZipFile(self.pkg_path, 'r') as zip_ref:
                    zip_ref.extractall(self.working_dir)

            # 2. 校验 Checksum
            checksum_file = os.path.join(self.working_dir, "checksum.sha256")
            if not os.path.exists(checksum_file):
                self.log.error("缺失 checksum.sha256 文件")
                return False

            with open(checksum_file, "r") as f:
                for line in f:
                    if not line.strip(): continue
                    expected_hash, file_rel_path = line.strip().split(None, 1)
                    full_path = os.path.join(self.working_dir, file_rel_path)
                    if not self._verify_file(full_path, expected_hash):
                        self.log.error(f"校验失败: {file_rel_path}")
                        return False
            self.log.ok("包完整性校验通过")

            # 3. 验证 manifest.json
            manifest_path = os.path.join(self.working_dir, "manifest.json")
            if not os.path.exists(manifest_path):
                self.log.error("缺失 manifest.json 文件")
                return False

            self.log.ok("Pre-flight check 通过")
            return True
        except Exception as e:
            self.log.error(f"Check 失败: {str(e)}")
            return False

    def deploy(self, resume: bool = False) -> bool:
        if not self.check(): return False

        # check 之后才加载连接配置（需要 manifest 已解压）
        self.conn_config = self._load_conn_config()

        self.log.section("DEPLOY START")
        manifest = self._load_manifest()
        plan = manifest.get("execution_plan", [])

        last_step = -1
        if resume and os.path.exists(self.state_file):
            with open(self.state_file, "r") as f:
                state = json.load(f)
                last_step = state.get("last_completed_step", -1)
                self.log.warn(f"从断点继续执行，跳过前 {last_step + 1} 个步骤")

        try:
            for step_data in plan:
                step_idx = step_data.get("step")
                if step_idx <= last_step: continue

                self._run_step(step_data)
                self._save_state(step_idx, "success")

            self.log.deploy_end("success")
            return True
        except Exception as e:
            self.log.error(f"部署中断: {str(e)}")
            self.log.deploy_end("failed")
            return False
        finally:
            ConnectorFactory.close_all()

    def rollback(self) -> bool:
        """执行回滚计划"""
        if not self.check(): return False

        self.conn_config = self._load_conn_config()

        self.log.section("ROLLBACK START")
        manifest = self._load_manifest()
        plan = manifest.get("rollback_plan", [])

        if not plan:
            self.log.error("manifest 中未定义 rollback_plan")
            return False

        try:
            for step_data in plan:
                self._run_step(step_data)
                self._save_state(step_data.get("step"), "rollback")

            self.log.deploy_end("rollback_success")
            return True
        except Exception as e:
            self.log.error(f"回滚中断: {str(e)}")
            self.log.deploy_end("rollback_failed")
            return False
        finally:
            ConnectorFactory.close_all()

    def _run_step(self, step_data: dict):
        step_idx = step_data.get("step")
        name = step_data.get("name")
        stype = step_data.get("type")
        targets = step_data.get("targets", [])
        params = step_data.get("params", {})

        start_ts = datetime.now()
        self.log.step_start(step_idx, name, stype)

        try:
            handler = StepHandlerFactory.get_handler(stype)
            result = handler.run(self.working_dir, targets, params, self.conn_config, self.log)

            elapsed = (datetime.now() - start_ts).total_seconds()
            self.log.step_success(step_idx, name, elapsed, result)
        except Exception as e:
            elapsed = (datetime.now() - start_ts).total_seconds()
            self.log.step_fail(step_idx, name, elapsed, str(e))
            self._save_state(step_idx - 1, "failed", failed_step=step_idx)
            raise e

    def _verify_file(self, path: str, expected_hash: str) -> bool:
        if not os.path.exists(path): return False
        sha256 = hashlib.sha256()
        with open(path, "rb") as f:
            while chunk := f.read(8192):
                sha256.update(chunk)
        return sha256.hexdigest() == expected_hash

    def _load_manifest(self):
        manifest_path = os.path.join(self.working_dir, "manifest.json")
        if not os.path.exists(manifest_path):
            return None
        with open(manifest_path, "r") as f:
            return json.load(f)

    def _save_state(self, last_idx: int, status: str, failed_step: int = None):
        os.makedirs(os.path.dirname(self.state_file), exist_ok=True)
        state = {
            "last_completed_step": last_idx,
            "status": status,
            "failed_step": failed_step
        }
        with open(self.state_file, "w") as f:
            json.dump(state, f)
