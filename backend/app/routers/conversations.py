import json
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import AuthenticatedUser, get_current_user
from app.models.db_models import Conversation, utc_now
from app.schemas.api_schemas import (
    ConversationDetailOut,
    ConversationSummaryOut,
    ConversationUpdateRequest,
    MessageOut,
    SourceReference,
)

router = APIRouter(prefix="/api/conversations", tags=["Conversations"])


def _get_owned_conversation(db: Session, conversation_id: str, owner_id: str) -> Conversation:
    conv = (
        db.query(Conversation)
        .filter(Conversation.id == conversation_id, Conversation.owner_id == owner_id)
        .first()
    )
    if not conv:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found or you do not have permission to access it.",
        )
    return conv


@router.get("", response_model=List[ConversationSummaryOut])
def list_conversations(
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Conversation)
        .filter(Conversation.owner_id == current_user.user_id)
        .order_by(Conversation.updated_at.desc())
        .all()
    )


@router.get("/{conversation_id}", response_model=ConversationDetailOut)
def get_conversation_detail(
    conversation_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    conv = _get_owned_conversation(db, conversation_id, current_user.user_id)
    messages_out: List[MessageOut] = []
    for m in conv.messages:
        raw_sources = json.loads(m.sources_json or "[]")
        sources = [SourceReference.model_validate(item) for item in raw_sources]
        messages_out.append(
            MessageOut(
                id=m.id,
                conversation_id=m.conversation_id,
                role=m.role,
                content=m.content,
                found_in_documents=bool(m.found_in_documents),
                sources=sources,
                created_at=m.created_at,
            )
        )
    return ConversationDetailOut(
        id=conv.id,
        title=conv.title,
        created_at=conv.created_at,
        updated_at=conv.updated_at,
        messages=messages_out,
    )


@router.patch("/{conversation_id}", response_model=ConversationSummaryOut)
def rename_conversation(
    conversation_id: str,
    payload: ConversationUpdateRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    conv = _get_owned_conversation(db, conversation_id, current_user.user_id)
    conv.title = payload.title.strip()
    conv.updated_at = utc_now()
    db.commit()
    db.refresh(conv)
    return conv


@router.delete("/{conversation_id}", status_code=status.HTTP_200_OK)
def delete_conversation(
    conversation_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    conv = _get_owned_conversation(db, conversation_id, current_user.user_id)
    db.delete(conv)
    db.commit()
    return {"deleted": True, "conversation_id": conversation_id}
