from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "PDF Brain API"
    DEBUG: bool = False

    # Gemini AI Configuration (Server-Side Only)
    GEMINI_API_KEY: str  # required, set in .env
    GEMINI_MODEL: str = "gemini-3.8-flash"
    GEMINI_FALLBACK_MODELS: str = (
        "gemini-3.7-flash,gemini-3.5-flash,gemini-3.5-flash-lite,gemini-2.5-flash"
    )
    EMBEDDING_MODEL: str = "gemini-embedding-001"
    GEMINI_MAX_ATTEMPTS: int = 3
    GEMINI_RETRY_BASE_DELAY: float = 1.0

    # Supabase Auth Configuration
    SUPABASE_URL: str  # set in .env
    SUPABASE_ANON_KEY: str  # set in .env
    SUPABASE_JWT_SECRET: str  # required, set in .env

    # Persistence Configuration
    DATABASE_URL: str = "sqlite:///./pdf_brain.db"
    UPLOAD_DIR: str = "./storage/pdfs"
    CHROMA_PERSIST_DIR: str = "./chroma_data"
    MAX_FILE_SIZE_MB: int = 25

    # RAG & Chunking Configuration
    CHUNK_SIZE: int = 800
    CHUNK_OVERLAP: int = 150
    TOP_K: int = 5
    MAX_DISTANCE_THRESHOLD: float = 0.78

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    @property
    def gemini_model_chain(self) -> list[str]:
        chain = [self.GEMINI_MODEL]
        for m in self.GEMINI_FALLBACK_MODELS.split(","):
            m = m.strip()
            if m and m not in chain:
                chain.append(m)
        return chain

    def ensure_dirs(self) -> None:
        Path(self.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
        Path(self.CHROMA_PERSIST_DIR).mkdir(parents=True, exist_ok=True)


settings = Settings()
settings.ensure_dirs()