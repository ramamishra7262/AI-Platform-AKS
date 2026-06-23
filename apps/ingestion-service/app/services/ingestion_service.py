"""
Document ingestion pipeline:
  1. Upload PDF to Azure Blob Storage
  2. Extract text from PDF
  3. Chunk text using recursive splitting
  4. Generate embeddings via Azure OpenAI
  5. Index chunks into Azure AI Search via RAG service
"""
import io, uuid, logging
from typing import List, Tuple
from pypdf import PdfReader
from azure.storage.blob import BlobServiceClient
from openai import AzureOpenAI
import httpx

logger = logging.getLogger(__name__)

RAG_SERVICE_URL = "http://rag-service:8001"
CHUNK_SIZE = 1000
CHUNK_OVERLAP = 200


def _chunk_text(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> List[str]:
    """Recursive character-based chunking with overlap."""
    if len(text) <= size:
        return [text]
    chunks, start = [], 0
    while start < len(text):
        end = start + size
        chunk = text[start:end]
        if end < len(text):
            # Find last sentence/paragraph boundary
            for sep in ["\n\n", "\n", ". ", " "]:
                idx = chunk.rfind(sep)
                if idx > size // 2:
                    chunk = chunk[: idx + len(sep)]
                    break
        chunks.append(chunk.strip())
        start += len(chunk) - overlap
    return [c for c in chunks if c]


def _extract_pdf_text(file_bytes: bytes) -> str:
    reader = PdfReader(io.BytesIO(file_bytes))
    return "\n\n".join(page.extract_text() or "" for page in reader.pages)


def ingest_document(filename: str, file_bytes: bytes,
                    storage_account: str, container: str,
                    openai_endpoint: str, openai_key: str, openai_version: str,
                    embedding_deployment: str) -> dict:
    document_id = str(uuid.uuid4())

    # 1. Upload raw file to Blob
    blob_svc = BlobServiceClient(f"https://{storage_account}.blob.core.windows.net",
                                  credential=_get_credential())
    blob_client = blob_svc.get_blob_client(container=container, blob=f"{document_id}/{filename}")
    blob_client.upload_blob(file_bytes, overwrite=True)
    logger.info("Uploaded %s to blob storage", filename)

    # 2. Extract text
    text = _extract_pdf_text(file_bytes)
    logger.info("Extracted %d chars from %s", len(text), filename)

    # 3. Chunk
    chunks = _chunk_text(text)
    logger.info("Split into %d chunks", len(chunks))

    # 4. Embed + 5. Index via RAG service
    aoai = AzureOpenAI(azure_endpoint=openai_endpoint, api_key=openai_key, api_version=openai_version)
    indexed_chunks = []
    for i, chunk in enumerate(chunks):
        embedding = aoai.embeddings.create(model=embedding_deployment, input=chunk).data[0].embedding
        indexed_chunks.append({
            "id": f"{document_id}-{i}",
            "document_id": document_id,
            "filename": filename,
            "content": chunk,
            "chunk_index": i,
            "content_vector": embedding,
        })

    resp = httpx.post(f"{RAG_SERVICE_URL}/rag/index", json={"chunks": indexed_chunks}, timeout=120)
    resp.raise_for_status()

    return {"document_id": document_id, "filename": filename,
            "chunk_count": len(chunks), "status": "indexed"}


def _get_credential():
    from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
    try:
        return ManagedIdentityCredential()
    except Exception:
        return DefaultAzureCredential()
