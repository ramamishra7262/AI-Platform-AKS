import json, logging
from typing import Any, Dict, List, Optional
from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchIndex, SearchField, SearchFieldDataType, SimpleField, SearchableField,
    VectorSearch, HnswAlgorithmConfiguration, VectorSearchProfile,
    SemanticConfiguration, SemanticPrioritizedFields, SemanticField, SemanticSearch,
)
from azure.search.documents.models import VectorizedQuery
from openai import AzureOpenAI
from app.core.config import get_settings

logger = logging.getLogger(__name__)
INDEX_FIELDS_VERSION = "1536"  # embedding dims


class SearchService:
    def __init__(self):
        s = get_settings()
        cred = AzureKeyCredential(s.azure_search_api_key)
        self._client = SearchClient(s.azure_search_endpoint, s.azure_search_index, cred)
        self._idx_client = SearchIndexClient(s.azure_search_endpoint, cred)
        self._aoai = AzureOpenAI(azure_endpoint=s.azure_openai_endpoint,
                                  api_key=s.azure_openai_api_key, api_version=s.azure_openai_api_version)
        self._settings = s
        self._ensure_index()

    def _ensure_index(self):
        s = self._settings
        existing = [i.name for i in self._idx_client.list_indexes()]
        if s.azure_search_index in existing:
            return
        fields = [
            SimpleField(name="id", type=SearchFieldDataType.String, key=True),
            SimpleField(name="document_id", type=SearchFieldDataType.String, filterable=True),
            SearchableField(name="filename", type=SearchFieldDataType.String),
            SearchableField(name="content", type=SearchFieldDataType.String),
            SimpleField(name="chunk_index", type=SearchFieldDataType.Int32, filterable=True, sortable=True),
            SearchField(name="content_vector", type=SearchFieldDataType.Collection(SearchFieldDataType.Single),
                        searchable=True, vector_search_dimensions=3072, vector_search_profile_name="hnsw-profile"),
        ]
        vector_search = VectorSearch(
            algorithms=[HnswAlgorithmConfiguration(name="hnsw")],
            profiles=[VectorSearchProfile(name="hnsw-profile", algorithm_configuration_name="hnsw")],
        )
        semantic_search = SemanticSearch(configurations=[
            SemanticConfiguration(name="default",
                prioritized_fields=SemanticPrioritizedFields(content_fields=[SemanticField(field_name="content")]))
        ])
        idx = SearchIndex(name=s.azure_search_index, fields=fields, vector_search=vector_search,
                          semantic_search=semantic_search)
        self._idx_client.create_index(idx)
        logger.info("Created index %s", s.azure_search_index)

    def embed(self, text: str) -> List[float]:
        resp = self._aoai.embeddings.create(model=self._settings.azure_openai_embedding_deployment, input=text)
        return resp.data[0].embedding

    def search(self, query: str, document_filter: Optional[List[str]] = None, top: int = 5) -> List[Dict[str, Any]]:
        vector_query = VectorizedQuery(vector=self.embed(query), k_nearest_neighbors=top, fields="content_vector")
        filter_expr = None
        if document_filter:
            ids = " or ".join(f"document_id eq '{d}'" for d in document_filter)
            filter_expr = f"({ids})"
        results = self._client.search(
            search_text=query, vector_queries=[vector_query], filter=filter_expr,
            select=["id", "document_id", "filename", "content", "chunk_index"],
            query_type="semantic", semantic_configuration_name="default", top=top,
        )
        return [{"id": r["id"], "document_id": r["document_id"], "filename": r["filename"],
                 "content": r["content"], "score": r.get("@search.score")} for r in results]

    def upload_chunks(self, chunks: List[Dict[str, Any]]):
        self._client.upload_documents(documents=chunks)
        logger.info("Uploaded %d chunks", len(chunks))


_svc = None
def get_search_service() -> SearchService:
    global _svc
    if _svc is None:
        _svc = SearchService()
    return _svc
