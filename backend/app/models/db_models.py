import uuid
from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, String, Integer, DateTime, Text, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.core.database import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def generate_uuid() -> str:
    return str(uuid.uuid4())


class Document(Base):
    __tablename__ = "documents"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    owner_id = Column(String(128), nullable=False, index=True)
    filename = Column(String(255), nullable=False)
    storage_path = Column(String(512), nullable=False)
    file_hash = Column(String(64), nullable=False, index=True)
    file_size_bytes = Column(Integer, nullable=False, default=0)
    page_count = Column(Integer, nullable=False, default=0)
    chunk_count = Column(Integer, nullable=False, default=0)
    status = Column(String(40), nullable=False, default="uploading")
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    __table_args__ = (
        Index("ix_documents_owner_hash", "owner_id", "file_hash"),
    )


class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    owner_id = Column(String(128), nullable=False, index=True)
    title = Column(String(255), nullable=False, default="New Conversation")
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    messages = relationship(
        "Message",
        back_populates="conversation",
        cascade="all, delete-orphan",
        order_by="Message.created_at.asc()",
    )


class Message(Base):
    __tablename__ = "messages"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    conversation_id = Column(String(36), ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False, index=True)
    role = Column(String(20), nullable=False)
    content = Column(Text, nullable=False)
    sources_json = Column(Text, nullable=False, default="[]")
    found_in_documents = Column(Integer, nullable=False, default=1)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    conversation = relationship("Conversation", back_populates="messages")


class ChatHistoryRecord(Base):
    __tablename__ = "chat_history"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(128), nullable=False, index=True)
    title = Column(String(255), nullable=True)
    is_pinned = Column(Boolean, nullable=False, default=False)
    question = Column(Text, nullable=False)
    answer = Column(Text, nullable=False)
    found_in_documents = Column(Boolean, nullable=False, default=True)
    sources_json = Column(Text, nullable=False, default="[]")
    document_ids_json = Column(Text, nullable=False, default="[]")
    created_at = Column(DateTime(timezone=True), nullable=False, default=utc_now)