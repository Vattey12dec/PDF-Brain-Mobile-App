from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import Base, engine
from app.routers import documents, chat, conversations

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="Full-Stack Retrieval-Augmented Generation (RAG) API for PDF Question Answering",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(documents.router)
app.include_router(chat.router)
app.include_router(conversations.router)


@app.get("/api/health", tags=["Health"])
def health_check():
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "generation_model": settings.GEMINI_MODEL,
        "embedding_model": settings.EMBEDDING_MODEL,
    }