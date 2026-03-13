import logging
import json
import os
from datetime import datetime
from typing import Any, Dict

class DeployLogger:
    """
    双轨日志系统：
    1. 彩色控制台输出（人类可读）
    2. JSONL 结构化事件流（前台解析）
    """
    
    def __init__(self, pkg_path: str):
        self.pkg_path = pkg_path
        self.meta_dir = os.path.join(pkg_path, ".meta")
        if not os.path.exists(self.meta_dir):
            os.makedirs(self.meta_dir, exist_ok=True)
            
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = os.path.join(self.meta_dir, f"deploy_{timestamp}.log")
        self.jsonl_file = os.path.join(self.meta_dir, "runtime_log.jsonl")
        
        # 配置系统 Logger 用于文本日志
        self.logger = logging.getLogger("db_deploy")
        self.logger.setLevel(logging.INFO)
        
        # 文本处理器 (文件 + 终端)
        fmt = logging.Formatter('%(asctime)s [%(levelname)s] %(message)s', datefmt='%H:%M:%S')
        
        fh = logging.FileHandler(self.log_file, encoding='utf-8')
        fh.setFormatter(fmt)
        self.logger.addHandler(fh)
        
        ch = logging.StreamHandler()
        ch.setFormatter(fmt)
        self.logger.addHandler(ch)

    def info(self, msg: str):
        self.logger.info(msg)
        self._write_jsonl({"event": "log", "level": "INFO", "msg": msg})

    def error(self, msg: str):
        self.logger.error(f"❌ {msg}")
        self._write_jsonl({"event": "log", "level": "ERROR", "msg": msg})

    def ok(self, msg: str):
        self.logger.info(f"✓ {msg}")
        self._write_jsonl({"event": "log", "level": "OK", "msg": msg})

    def warn(self, msg: str):
        self.logger.warning(f"⚠ {msg}")
        self._write_jsonl({"event": "log", "level": "WARN", "msg": msg})

    def section(self, title: str):
        border = "-" * 60
        self.logger.info(f"\n{border}\n  {title}\n{border}")
        self._write_jsonl({"event": "section", "title": title})

    def step_start(self, step: int, name: str, type: str):
        self.info(f"▶ Step {step:02d} [{type}] {name}")
        self._write_jsonl({
            "event": "step_start", 
            "step": step, 
            "name": name, 
            "type": type
        })

    def step_success(self, step: int, name: str, elapsed: float, result: Any = None):
        self.ok(f"Step {step:02d} 完成  耗时 {elapsed:.1f}s")
        self._write_jsonl({
            "event": "step_success", 
            "step": step, 
            "name": name, 
            "elapsed_s": elapsed,
            "result": result
        })

    def step_fail(self, step: int, name: str, elapsed: float, error: str):
        self.error(f"Step {step:02d} 失败  耗时 {elapsed:.1f}s  error={error}")
        self._write_jsonl({
            "event": "step_fail", 
            "step": step, 
            "name": name, 
            "elapsed_s": elapsed,
            "error": error
        })

    def deploy_end(self, status: str, summary_file: str = ""):
        self.logger.info("=" * 72)
        self.logger.info(f"  FINAL STATUS: {status.upper()}")
        if summary_file:
            self.logger.info(f"  摘要文件: {summary_file}")
        self.logger.info("=" * 72)
        
        self._write_jsonl({
            "event": "deploy_end", 
            "status": status, 
            "summary": summary_file
        })

    def _write_jsonl(self, data: Dict):
        data["ts"] = datetime.now().isoformat(timespec='seconds')
        with open(self.jsonl_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(data, ensure_ascii=False) + "\n")
