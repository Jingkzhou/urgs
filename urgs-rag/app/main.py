"""
FastAPI 应用主入口

该模块负责初始化 FastAPI 应用，挂载各个功能模块的路由，并配置启动参数。
"""

from fastapi import FastAPI
from app.config import settings
from app.routers import ingest, query, sql2text, vector_db, metrics
import uvicorn

# 初始化 FastAPI 应用
app = FastAPI(title=settings.APP_NAME)

# 注册各个功能模块的路由
# 数据摄入模块
app.include_router(ingest.router, prefix="/api/rag", tags=["Ingestion"])
# 问答查询模块
app.include_router(query.router, prefix="/api/rag", tags=["Query"])
# SQL 转文本/生成模块
app.include_router(sql2text.router, prefix="/api/rag", tags=["SQL2Text"])
# 向量数据库管理模块
app.include_router(vector_db.router)
# 系统指标/监控模块
app.include_router(metrics.router)

@app.get("/health")
def health_check():
    """
    健康检查接口
    用于容器编排或负载均衡器确认服务状态
    """
    return {"status": "ok"}

if __name__ == "__main__":
    # 使用 uvicorn 启动服务
    # host: 0.0.0.0 允许外部访问
    # port: 8001 应用监听端口
    # reload: True 开发环境下的热重载
    uvicorn.run("app.main:app", host="0.0.0.0", port=8001, reload=True)
