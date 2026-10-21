import os
import uuid
from pathlib import Path
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.security import AuthenticatedUser, get_current_user
from app.models.db_models import Document
from app.schemas.api_schemas import DocumentListResponse, DocumentOut, DocumentStatusOut
from app.services.pdf_service import extract_text_from_pdf_bytes, read_and_validate_pdf_upload
from app.services.chunking_service import create_document_chunks
from app.services.vector_service import vector_service

router = APIRouter(prefix="/api/v1/documents", tags=["Documents"])


@router.post("/upload", response_model=DocumentOut, status_code=status.HTTP_201_CREATED)
async def upload_document(
    file: UploadFile = File(...),
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    file_bytes, safe_filename, file_hash = await read_and_validate_pdf_upload(file)

    existing_doc = (
        db.query(Document)
        .filter(
            Document.owner_id == current_user.user_id,
            Document.file_hash == file_hash,
            Document.status == "ready",
        )
        .first()
    )
    if existing_doc:
        return existing_doc

    doc_id = str(uuid.uuid4())
    server_filename = f"{doc_id}.pdf"
    storage_path = str(Path(settings.UPLOAD_DIR) / server_filename)

    doc_record = Document(
        id=doc_id,
        owner_id=current_user.user_id,
        filename=safe_filename,
        storage_path=storage_path,
        file_hash=file_hash,
        file_size_bytes=len(file_bytes),
        status="uploading",
    )
    db.add(doc_record)
    db.commit()
    db.refresh(doc_record)

    try:
        with open(storage_path, "wb") as f:
            f.write(file_bytes)

        doc_record.status = "extracting_text"
        db.commit()
        extracted = extract_text_from_pdf_bytes(file_bytes)
        doc_record.page_count = extracted.page_count

        doc_record.status = "creating_chunks"
        db.commit()
        chunks = create_document_chunks(
            document_id=doc_id,
            owner_id=current_user.user_id,
            filename=safe_filename,
            pages=extracted.pages,
            chunk_size=settings.CHUNK_SIZE,
            chunk_overlap=settings.CHUNK_OVERLAP,
        )
        if not chunks:
            raise ValueError("Unable to create text chunks from the extracted PDF text.")

        doc_record.status = "generating_embeddings"
        db.commit()
        embeddings = vector_service.embed_chunks(chunks)

        doc_record.status = "indexing_vectors"
        db.commit()
        vector_service.index_chunks(chunks, embeddings)

        doc_record.chunk_count = len(chunks)
        doc_record.status = "ready"
        doc_record.error_message = None
        db.commit()
        db.refresh(doc_record)
        return doc_record

    except ValueError as val_err:
        doc_record.status = "failed"
        doc_record.error_message = str(val_err)
        db.commit()
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(val_err))
    except HTTPException as http_exc:
        doc_record.status = "failed"
        doc_record.error_message = str(http_exc.detail)
        db.commit()
        raise
    except Exception as exc:
        doc_record.status = "failed"
        doc_record.error_message = "Unexpected error during PDF processing."
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unexpected server error while processing PDF.",
        ) from exc


@router.get("", response_model=DocumentListResponse)
def list_documents(
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    docs = (
        db.query(Document)
        .filter(Document.owner_id == current_user.user_id)
        .order_by(Document.created_at.desc())
        .all()
    )
    return DocumentListResponse(documents=[DocumentOut.model_validate(d) for d in docs])


def _get_owned_document(db: Session, document_id: str, owner_id: str) -> Document:
    doc = (
        db.query(Document)
        .filter(Document.id == document_id, Document.owner_id == owner_id)
        .first()
    )
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found or you do not have permission to access it.",
        )
    return doc


@router.get("/{document_id}", response_model=DocumentOut)
def get_document(
    document_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return _get_owned_document(db, document_id, current_user.user_id)


@router.get("/{document_id}/status", response_model=DocumentStatusOut)
def get_document_status(
    document_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    doc = _get_owned_document(db, document_id, current_user.user_id)
    return DocumentStatusOut(
        id=doc.id,
        filename=doc.filename,
        status=doc.status,
        page_count=doc.page_count,
        chunk_count=doc.chunk_count,
        error_message=doc.error_message,
    )


@router.get("/{document_id}/file")
def download_document_file(
    document_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    doc = _get_owned_document(db, document_id, current_user.user_id)
    if not os.path.exists(doc.storage_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Stored PDF file is missing on server disk.",
        )
    return FileResponse(
        path=doc.storage_path,
        media_type="application/pdf",
        filename=doc.filename,
    )


@router.delete("/{document_id}", status_code=status.HTTP_200_OK)
def delete_document(
    document_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    doc = _get_owned_document(db, document_id, current_user.user_id)
    vector_service.delete_document_vectors(owner_id=current_user.user_id, document_id=doc.id)
    if os.path.exists(doc.storage_path):
        try:
            os.remove(doc.storage_path)
        except OSError:
            pass
    db.delete(doc)
    db.commit()
    return {"deleted": True, "document_id": document_id}