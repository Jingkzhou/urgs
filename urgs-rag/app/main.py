from fastapi import FastAPI
from app.config import settings
from app.routers import ingest, query, sql2text, vector_db
import uvicorn

app = FastAPI(title=settings.APP_NAME)

# Include Routers
app.include_router(ingest.router, prefix="/api/rag", tags=["Ingestion"])
app.include_router(query.router, prefix="/api/rag", tags=["Query"])
app.include_router(sql2text.router, prefix="/api/rag", tags=["SQL2Text"])
app.include_router(vector_db.router)

@app.get("/health")
def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8001, reload=True)
