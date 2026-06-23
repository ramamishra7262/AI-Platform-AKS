import logging
from fastapi import APIRouter, UploadFile, File, HTTPException, BackgroundTasks
from app.services.ingestion_service import ingest_document
from app.core.config import get_settings

router = APIRouter(prefix="/ingest", tags=["ingestion"])
logger = logging.getLogger(__name__)
_jobs: dict = {}


@router.post("/upload")
async def upload_document(background_tasks: BackgroundTasks, file: UploadFile = File(...)):
    settings = get_settings()
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(400, "Only PDF files are supported")
    content = await file.read()
    job_id = file.filename

    def run_ingestion():
        try:
            result = ingest_document(
                filename=file.filename, file_bytes=content,
                storage_account=settings.azure_storage_account_name,
                container=settings.azure_storage_container,
                openai_endpoint=settings.azure_openai_endpoint,
                openai_key=settings.azure_openai_api_key,
                openai_version=settings.azure_openai_api_version,
                embedding_deployment=settings.azure_openai_embedding_deployment,
            )
            _jobs[job_id] = {"status": "completed", **result}
        except Exception as exc:
            logger.exception("Ingestion failed for %s", file.filename)
            _jobs[job_id] = {"status": "failed", "error": str(exc)}

    _jobs[job_id] = {"status": "processing", "filename": file.filename}
    background_tasks.add_task(run_ingestion)
    return {"job_id": job_id, "status": "processing"}


@router.get("/status/{job_id}")
def get_status(job_id: str):
    return _jobs.get(job_id, {"status": "not_found"})
