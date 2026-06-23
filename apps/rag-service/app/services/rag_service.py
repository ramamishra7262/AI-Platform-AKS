import json, logging
from typing import AsyncGenerator, List, Dict, Any
from openai import AzureOpenAI
from app.core.config import get_settings
from app.services.search_service import get_search_service

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """You are an enterprise knowledge assistant. Answer questions based ONLY on the provided document context.
If the context doesn't contain enough information, say so clearly.
Always cite the source document name when referencing specific information.
Be concise, accurate, and professional."""


class RAGService:
    def __init__(self):
        s = get_settings()
        self._client = AzureOpenAI(azure_endpoint=s.azure_openai_endpoint,
                                    api_key=s.azure_openai_api_key, api_version=s.azure_openai_api_version)
        self._settings = s

    def _build_messages(self, query: str, context_docs: List[Dict], history: List[Dict]) -> List[Dict]:
        context_text = "\n\n---\n\n".join(
            f"Source: {d['filename']}\n{d['content']}" for d in context_docs
        )
        messages = [{"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": f"DOCUMENT CONTEXT:\n{context_text}"}]
        for h in history[-10:]:  # last 10 turns
            messages.append({"role": h["role"], "content": h["content"]})
        messages.append({"role": "user", "content": query})
        return messages

    def query(self, query: str, history: List[Dict], document_filter: List[str] = None) -> Dict[str, Any]:
        search = get_search_service()
        docs = search.search(query, document_filter, top=self._settings.top_k_results)
        messages = self._build_messages(query, docs, history)
        resp = self._client.chat.completions.create(
            model=self._settings.azure_openai_chat_deployment, messages=messages,
            temperature=0.1, max_tokens=2048,
        )
        answer = resp.choices[0].message.content
        sources = [{"filename": d["filename"], "chunk_id": d["id"], "score": d["score"]} for d in docs]
        return {"answer": answer, "sources": sources, "tokens_used": resp.usage.total_tokens}

    async def stream(self, query: str, history: List[Dict]) -> AsyncGenerator[str, None]:
        search = get_search_service()
        docs = search.search(query, top=self._settings.top_k_results)
        messages = self._build_messages(query, docs, history)
        stream = self._client.chat.completions.create(
            model=self._settings.azure_openai_chat_deployment, messages=messages,
            temperature=0.1, max_tokens=2048, stream=True,
        )
        for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content:
                yield f"data: {json.dumps({'content': chunk.choices[0].delta.content})}\n\n"
        yield "data: [DONE]\n\n"


_svc = None
def get_rag_service() -> RAGService:
    global _svc
    if _svc is None:
        _svc = RAGService()
    return _svc
