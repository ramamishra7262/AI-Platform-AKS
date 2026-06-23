from fastapi import FastAPI
from app.api.rag import router as rag_router

app = FastAPI(title="RAG Service", version="1.0.0")
app.include_router(rag_router)

@app.get("/healthz")
def health():
    return {"status": "ok"}
