from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    azure_openai_endpoint: str = ""
    azure_openai_api_key: str = ""
    azure_openai_api_version: str = "2024-05-01-preview"
    azure_openai_chat_deployment: str = "gpt-4o"
    azure_openai_embedding_deployment: str = "text-embedding-3-large"
    azure_search_endpoint: str = ""
    azure_search_api_key: str = ""
    azure_search_index: str = "documents-index"
    max_context_tokens: int = 8000
    top_k_results: int = 5

@lru_cache
def get_settings() -> Settings:
    return Settings()
