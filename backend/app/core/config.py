from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "PDF Brain API"
    DEBUG: bool = False

    # Gemini AI Configuration (Server-Side Only)
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.5-flash"
    EMBEDDING_MODEL: str = "gemini-embedding-001"

    # Supabase Auth Configuration
    SUPABASE_URL: str = "https://ffbairirlkjchobvbply.supabase.co"
    SUPABASE_ANON_KEY: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZmYmFpcmlybGtqY2hvYnZicGx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIzMjQ1NzEsImV4cCI6MjEwNzkwMDU3MX0.f_0tMjG7nv9TwIu4dFidqCmNlfDOYrmslfi353VtgbM"
    SUPABASE_JWT_SECRET: str = "I9vHe0ht3uwjgr+F67qOhyt5ffT1Kboy/AVGobK0LHsquEV2OzrxuYVevoMNViKLN3cRKtuXjUq80jxVe2DSXw=="

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

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    def ensure_dirs(self) -> None:
        Path(self.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
        Path(self.CHROMA_PERSIST_DIR).mkdir(parents=True, exist_ok=True)


settings = Settings()
settings.ensure_dirs()