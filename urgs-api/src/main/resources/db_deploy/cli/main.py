import argparse
import sys
import os
from db_deploy.core.engine import DeployEngine

def main():
    parser = argparse.ArgumentParser(description="db_deploy - 数据库版本一键部署引擎")
    
    parser.add_argument("command", choices=["check", "deploy", "rollback", "status"], 
                        help="执行命令: check(校验), deploy(部署), rollback(回退), status(状态)")
    
    parser.add_argument("--pkg", required=True, help="部署包路径 (ZIP 文件或解压后的目录)")
    parser.add_argument("--operator", default="system", help="操作人名称")
    parser.add_argument("--conn-config", help="非默认连接配置文件路径")
    parser.add_argument("--resume", action="store_true", help="从上次失败位置继续执行")

    args = parser.parse_args()

    # 简单校验目录环境
    if not os.path.exists(args.pkg):
        print(f"错误: 部署包路径不存在: {args.pkg}")
        sys.exit(1)

    engine = DeployEngine(
        pkg_path=args.pkg,
        operator=args.operator,
        conn_config_path=args.conn_config
    )

    try:
        if args.command == "check":
            success = engine.check()
        elif args.command == "deploy":
            success = engine.deploy(resume=args.resume)
        elif args.command == "rollback":
            success = engine.rollback()
        elif args.command == "status":
            engine.show_status()
            success = True
        else:
            success = False
            
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print(f"执行异常: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
