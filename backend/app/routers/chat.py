import json
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session
from app.core.security import AuthenticatedUser, get_current_user
from app.core.database import get_db
from app.models.db_models import ChatHistoryRecord, Document
from app.schemas.api_schemas import (
    ChatAnswerResponse,
    ChatHistoryItemOut,
    ChatHistoryListResponse,
    ChatQuestionRequest,
    ChatUpdateRequest,
    SourceReference,
)
from app.services.rag_service import rag_service
from app.services.vector_service import vector_service

router = APIRouter(prefix="/api/v1/chat", tags=["Chat & RAG"])


def _default_title(question: str) -> str:
    clean = " ".join(question.strip().split())
    return clean if len(clean) <= 56 else f"{clean[:53]}..."


def _record_to_item(r: ChatHistoryRecord) -> ChatHistoryItemOut:
    try:
        raw_sources = json.loads(r.sources_json or "[]")
        sources = [SourceReference(**s) for s in raw_sources]
    except Exception:
        sources = []
    try:
        doc_ids = json.loads(r.document_ids_json or "[]")
    except Exception:
        doc_ids = []

    return ChatHistoryItemOut(
        id=r.id,
        title=r.title or _default_title(r.question),
        is_pinned=bool(r.is_pinned),
        question=r.question,
        answer=r.answer,
        found_in_documents=r.found_in_documents,
        sources=sources,
        document_ids=doc_ids,
        created_at=r.created_at,
    )


@router.post("/ask", response_model=ChatAnswerResponse)
def ask_question(
    payload: ChatQuestionRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ready_docs_query = db.query(Document).filter(
    Document.owner_id == current_user.user_id,
    Document.status == "ready",

    )

    if payload.document_ids:
        ready_docs = ready_docs_query.filter(Document.id.in_(payload.document_ids)).all()
        if not ready_docs:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="None of the selected PDFs are ready for querying.",
            )
    else:
        ready_docs = ready_docs_query.all()
        if not ready_docs:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You do not have any processed PDF documents yet. Please upload a PDF first.",
            )

    target_doc_ids = [d.id for d in ready_docs]

    retrieved_chunks = vector_service.search_similar_chunks(
        owner_id=current_user.user_id,
        question=payload.question,
        document_ids=target_doc_ids,
)

    answer_text, found_in_docs, verified_sources = rag_service.answer_question(
        question=payload.question,
        retrieved_chunks=retrieved_chunks,
    )

    computed_title = (payload.title or "").strip() or _default_title(payload.question)

    history_record = ChatHistoryRecord(
        user_id=current_user.user_id,
        title=computed_title,
        is_pinned=False,
        question=payload.question.strip(),
        answer=answer_text,
        found_in_documents=found_in_docs,
        sources_json=json.dumps([s.model_dump() for s in verified_sources]),
        document_ids_json=json.dumps(target_doc_ids),
    )
    db.add(history_record)
    db.commit()
    db.refresh(history_record)

    return ChatAnswerResponse(
        history_id=history_record.id,
        title=history_record.title or computed_title,
        is_pinned=bool(history_record.is_pinned),
        question=history_record.question,
        answer=history_record.answer,
        found_in_documents=history_record.found_in_documents,
        sources=verified_sources,
        document_ids=target_doc_ids,
        created_at=history_record.created_at,
    )


@router.get("/history", response_model=ChatHistoryListResponse)
def list_chat_history(
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    records = (
        db.query(ChatHistoryRecord)
        .filter(ChatHistoryRecord.user_id == current_user.user_id)
        .order_by(ChatHistoryRecord.is_pinned.desc(), ChatHistoryRecord.created_at.desc())
        .limit(100)
        .all()
    )
    return ChatHistoryListResponse(items=[_record_to_item(r) for r in records])


@router.patch("/history/{history_id}", response_model=ChatHistoryItemOut)
def update_history_item(
    history_id: str,
    payload: ChatUpdateRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    record = (
        db.query(ChatHistoryRecord)
        .filter(
            ChatHistoryRecord.id == history_id,
            ChatHistoryRecord.user_id == current_user.user_id,
        )
        .first()
    )
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation history item not found.",
        )

    if payload.title is not None:
        cleaned = payload.title.strip()
        if cleaned:
            record.title = cleaned
    if payload.is_pinned is not None:
        record.is_pinned = payload.is_pinned

    db.commit()
    db.refresh(record)
    return _record_to_item(record)


@router.delete("/history/{history_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_history_item(
    history_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    record = (
        db.query(ChatHistoryRecord)
        .filter(
            ChatHistoryRecord.id == history_id,
            ChatHistoryRecord.user_id == current_user.user_id,
        )
        .first()
    )
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation history item not found.",
        )

    db.delete(record)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)