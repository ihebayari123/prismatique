from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    data_dir: Path
    index_dir: Path
    embeddings_provider: str
    openai_embedding_model: str

    openai_api_key: str | None
    openai_model: str

    openrouter_api_key: str | None
    openrouter_base_url: str
    openrouter_model: str

    ollama_base_url: str
    ollama_model: str
    ollama_embedding_model: str


def get_settings() -> Settings:
    base_dir = Path(__file__).resolve().parent.parent
    data_dir = Path(os.getenv("RAG_DATA_DIR", str(base_dir / "data")))
    index_dir = Path(os.getenv("RAG_INDEX_DIR", str(base_dir / "index")))

    return Settings(
        data_dir=data_dir,
        index_dir=index_dir,
        embeddings_provider=os.getenv("EMBEDDINGS_PROVIDER", "auto"),
        openai_embedding_model=os.getenv(
            "OPENAI_EMBEDDING_MODEL", "text-embedding-3-small"
        ),
        openai_api_key=os.getenv("OPENAI_API_KEY"),
        openai_model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
        openrouter_api_key=os.getenv("OPENROUTER_API_KEY"),
        openrouter_base_url=os.getenv(
            "OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1"
        ),
        openrouter_model=os.getenv(
            "OPENROUTER_MODEL", "qwen/qwen3-next-80b-a3b-instruct"
        ),
        ollama_base_url=os.getenv("OLLAMA_BASE_URL", "http://localhost:11434"),
        ollama_model=os.getenv("OLLAMA_MODEL", "llama3.1:8b"),
        ollama_embedding_model=os.getenv("OLLAMA_EMBEDDING_MODEL", "nomic-embed-text"),
    )
