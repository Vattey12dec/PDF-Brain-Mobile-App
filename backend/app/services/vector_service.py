import logging
from dataclasses import dataclass
from typing import List, Optional, Protocol
import chromadb
from chromadb.config import Settings as ChromaSettings
from google import genai
from fastapi import HTTPException, status
from app.core.config import settings
from app.services.chunking_service import DocumentChunk

logger = logging.getLogger("uvicorn.error")


@dataclass
class RetrievedChunk:
    chunk_id: str
    document_id: str
    owner_id: str
    filename: str
    page_number: int
    text: str
    distance: float
    similarity_score: float


class EmbeddingClientProtocol(Protocol):
    def embed_texts(self, texts: List[str]) -> List[List[float]]:
        ...

    def embed_query(self, query: str) -> List[float]:
        ...


class GeminiEmbeddingClient:
    def __init__(self, api_key: str, model_name: str):
        self.api_key = api_key
        self.model_name = model_name
        self._client: Optional[genai.Client] = None

    @property
    def client(self) -> genai.Client:
        if not self.api_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="GEMINI_API_KEY is not configured on the backend server.",
            )
        if self._client is None:
            self._client = genai.Client(api_key=self.api_key)
        return self._client

    def embed_texts(self, texts: List[str]) -> List[List[float]]:
        if not texts:
            return []
        try:
            vectors: List[List[float]] = []
            batch_size = 32
            for i in range(0, len(texts), batch_size):
                batch = texts[i : i + batch_size]
                response = self.client.models.embed_content(
                    model=self.model_name,
                    contents=batch,
                )
                for emb in response.embeddings:
                    vectors.append(list(emb.values))
            return vectors
        except HTTPException:
            raise
        except Exception as exc:
            logger.error("Embedding call failed (model=%s): %r", self.model_name, exc)
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Embedding generation failed via provider ({self.model_name}). Please retry shortly.",
            ) from exc

    def embed_query(self, query: str) -> List[float]:
        vectors = self.embed_texts([query])
        if not vectors:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Failed to generate embedding vector for question.",
            )
        return vectors[0]


class VectorStoreService:
    def __init__(
        self,
        persist_dir: str = settings.CHROMA_PERSIST_DIR,
        embedding_client: Optional[EmbeddingClientProtocol] = None,
        collection_name: str = "pdf_brain_chunks",
    ):
        self._chroma_client = chromadb.PersistentClient(
            path=persist_dir,
            settings=ChromaSettings(anonymized_telemetry=False),
        )
        safe_model_suffix = settings.EMBEDDING_MODEL.replace("-", "_").replace("/", "_")
        full_collection_name = f"{collection_name}_{safe_model_suffix}"[:60]
        self._collection = self._chroma_client.get_or_create_collection(
            name=full_collection_name,
            metadata={"hnsw:space": "cosine"},
        )
        self.embedding_client: EmbeddingClientProtocol = embedding_client or GeminiEmbeddingClient(
            api_key=settings.GEMINI_API_KEY,
            model_name=settings.EMBEDDING_MODEL,
        )

    def embed_chunks(self, chunks: List[DocumentChunk]) -> List[List[float]]:
        return self.embedding_client.embed_texts([c.text for c in chunks])

    def index_chunks(self, chunks: List[DocumentChunk], embeddings: List[List[float]]) -> None:
        if not chunks:
            return
        try:
            self._collection.upsert(
                ids=[c.chunk_id for c in chunks],
                embeddings=embeddings,
                documents=[c.text for c in chunks],
                metadatas=[
                    {
                        "document_id": c.document_id,
                        "owner_id": c.owner_id,
                        "filename": c.filename,
                        "page_number": int(c.page_number),
                        "chunk_index": int(c.chunk_index),
                    }
                    for c in chunks
                ],
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Vector database error while indexing document chunks.",
            ) from exc

    def search_similar_chunks(
        self,
        *,
        owner_id: str,
        question: str,
        document_ids: Optional[List[str]] = None,
        top_k: int = settings.TOP_K,
        max_distance: float = settings.MAX_DISTANCE_THRESHOLD,
    ) -> List[RetrievedChunk]:
        query_vector = self.embedding_client.embed_query(question)

        if document_ids:
            if len(document_ids) == 1:
                where_filter = {
                    "$and": [
                        {"owner_id": {"$eq": owner_id}},
                        {"document_id": {"$eq": document_ids[0]}},
                    ]
                }
            else:
                where_filter = {
                    "$and": [
                        {"owner_id": {"$eq": owner_id}},
                        {"document_id": {"$in": document_ids}},
                    ]
                }
        else:
            where_filter = {"owner_id": {"$eq": owner_id}}

        try:
            results = self._collection.query(
                query_embeddings=[query_vector],
                n_results=top_k,
                where=where_filter,
                include=["documents", "metadatas", "distances"],
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Vector search failed in ChromaDB.",
            ) from exc

        ids_list = (results.get("ids") or [[]])[0]
        docs_list = (results.get("documents") or [[]])[0]
        metas_list = (results.get("metadatas") or [[]])[0]
        dists_list = (results.get("distances") or [[]])[0]

        retrieved: List[RetrievedChunk] = []
        for chunk_id, doc_text, meta, dist in zip(ids_list, docs_list, metas_list, dists_list):
            if dist is not None and float(dist) <= max_distance:
                similarity = round(max(0.0, 1.0 - float(dist)), 4)
                retrieved.append(
                    RetrievedChunk(
                        chunk_id=chunk_id,
                        document_id=str(meta["document_id"]),
                        owner_id=str(meta["owner_id"]),
                        filename=str(meta["filename"]),
                        page_number=int(meta["page_number"]),
                        text=str(doc_text),
                        distance=float(dist),
                        similarity_score=similarity,
                    )
                )
        return retrieved

    def delete_document_vectors(self, *, owner_id: str, document_id: str) -> None:
        try:
            self._collection.delete(
                where={
                    "$and": [
                        {"owner_id": {"$eq": owner_id}},
                        {"document_id": {"$eq": document_id}},
                    ]
                }
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to remove document vectors from ChromaDB.",
            ) from exc


vector_service = VectorStoreService()