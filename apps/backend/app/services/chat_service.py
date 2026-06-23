"""Chat service - calls RAG service and returns streaming or batch responses."""
import httpx
from typing import AsyncGenerator, List
from app.core.config import get_settings
from app.models.schemas import ChatMessage

RAG_SERVICE_URL = "http://rag-service:8001"


async def get_rag_answer(session_id: str, message: str, history: List[ChatMessage],
                          document_filter: List[str] = None) -> dict:
    settings = get_settings()
    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            f"{RAG_SERVICE_URL}/rag/query",
            json={
                "session_id": session_id,
                "query": message,
                "conversation_history": [m.model_dump() for m in history],
                "document_filter": document_filter,
            },
        )
        resp.raise_for_status()
        return resp.json()


async def stream_rag_answer(session_id: str, message: str,
                             history: List[ChatMessage]) -> AsyncGenerator[str, None]:
    async with httpx.AsyncClient(timeout=120) as client:
        async with client.stream(
            "POST",
            f"{RAG_SERVICE_URL}/rag/stream",
            json={"session_id": session_id, "query": message,
                  "conversation_history": [m.model_dump() for m in history]},
        ) as resp:
            async for chunk in resp.aiter_text():
                yield chunk
