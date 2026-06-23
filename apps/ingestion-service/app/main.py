from fastapi import FastAPI
from app.api.ingest import router

app = FastAPI(title="Ingestion Service", version="1.0.0")
app.include_router(router)

@app.get("/healthz")
def health():
    return {"status": "ok"}
