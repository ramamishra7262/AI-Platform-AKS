from typing import List
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from app.models.schemas import ChatRequest, ChatResponse, ChatMessage
from app.services.chat_service import get_rag_answer, stream_rag_answer
from app.api.deps import get_current_user

router = APIRouter(prefix="/chat", tags=["chat"])
# In-memory chat history (use Redis/CosmosDB in production)
_sessions: dict = {}


@router.post("/", response_model=ChatResponse)
async def chat(request: ChatRequest, user=Depends(get_current_user)):
    history: List[ChatMessage] = _sessions.get(request.session_id, [])
    result = await get_rag_answer(request.session_id, request.message, history, request.document_filter)
    _sessions.setdefault(request.session_id, []).extend([
        ChatMessage(role="user", content=request.message),
        ChatMessage(role="assistant", content=result.get("answer", "")),
    ])
    return ChatResponse(
        session_id=request.session_id,
        answer=result.get("answer", ""),
        sources=result.get("sources", []),
        tokens_used=result.get("tokens_used", 0),
    )


@router.post("/stream")
async def chat_stream(request: ChatRequest, user=Depends(get_current_user)):
    history = _sessions.get(request.session_id, [])
    return StreamingResponse(
        stream_rag_answer(request.session_id, request.message, history),
        media_type="text/event-stream",
    )


@router.get("/history/{session_id}", response_model=List[ChatMessage])
async def get_history(session_id: str, user=Depends(get_current_user)):
    return _sessions.get(session_id, [])


@router.delete("/history/{session_id}")
async def clear_history(session_id: str, user=Depends(get_current_user)):
    _sessions.pop(session_id, None)
    return {"status": "cleared"}
