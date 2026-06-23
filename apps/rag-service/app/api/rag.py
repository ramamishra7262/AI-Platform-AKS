from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from app.services.rag_service import get_rag_service

router = APIRouter(prefix="/rag", tags=["rag"])

class RAGRequest(BaseModel):
    session_id: str
    query: str
    conversation_history: List[Dict[str, Any]] = []
    document_filter: Optional[List[str]] = None

@router.post("/query")
def rag_query(req: RAGRequest):
    return get_rag_service().query(req.query, req.conversation_history, req.document_filter)

@router.post("/stream")
async def rag_stream(req: RAGRequest):
    return StreamingResponse(get_rag_service().stream(req.query, req.conversation_history),
                              media_type="text/event-stream")
