from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    azure_openai_endpoint: str = ""
    azure_openai_api_key: str = ""
    azure_openai_api_version: str = "2024-05-01-preview"
    azure_openai_embedding_deployment: str = "text-embedding-3-large"
    azure_storage_account_name: str = ""
    azure_storage_container: str = "documents"

@lru_cache
def get_settings():
    return Settings()
