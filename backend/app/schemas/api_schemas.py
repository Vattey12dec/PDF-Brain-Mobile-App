from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator


class DocumentOut(BaseModel):
    id: str
    filename: str
    file_size_bytes: int
    page_count: int
    chunk_count: int
    status: str
    error_message: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}

class DocumentStatusOut(BaseModel):
    id: str
    filename: str
    status: str
    page_count: int
    chunk_count: int
    error_message: Optional[str] = None

    model_config = {"from_attributes": True}

class DocumentListResponse(BaseModel):
    documents: List[DocumentOut]


class SourceReference(BaseModel):
    document_id: str
    filename: str
    page_number: int
    excerpt: str
    similarity_score: float


class ChatQuestionRequest(BaseModel):
    question: str = Field(..., min_length=2, max_length=2000)
    document_ids: Optional[List[str]] = None
    title: Optional[str] = Field(default=None, max_length=255)

    @field_validator("question")
    @classmethod
    def question_not_blank(cls, v: str) -> str:
        cleaned = v.strip()
        if len(cleaned) < 2:
            raise ValueError("Question must contain at least 2 non-space characters.")
        return cleaned


class ChatUpdateRequest(BaseModel):
    title: Optional[str] = Field(default=None, max_length=255)
    is_pinned: Optional[bool] = None


class ChatAnswerResponse(BaseModel):
    history_id: str
    title: str
    is_pinned: bool = False
    question: str
    answer: str
    found_in_documents: bool
    sources: List[SourceReference]
    document_ids: List[str] = Field(default_factory=list)
    created_at: datetime


class ChatHistoryItemOut(BaseModel):
    id: str
    title: str
    is_pinned: bool
    question: str
    answer: str
    found_in_documents: bool
    sources: List[SourceReference]
    document_ids: List[str]
    created_at: datetime


class ChatHistoryListResponse(BaseModel):
    items: List[ChatHistoryItemOut]

class MessageOut(BaseModel):
    id: str
    role: str
    content: str
    sources: List[SourceReference] = []
    found_in_documents: bool = True
    created_at: datetime

    model_config = {"from_attributes": True}


class ConversationSummaryOut(BaseModel):
    id: str
    title: str
    created_at: datetime
    updated_at: datetime
    message_count: int = 0

    model_config = {"from_attributes": True}


class ConversationDetailOut(BaseModel):
    id: str
    title: str
    created_at: datetime
    updated_at: datetime
    messages: List[MessageOut] = []

    model_config = {"from_attributes": True}


class ConversationUpdateRequest(BaseModel):
    title: str = Field(min_length=1, max_length=255)