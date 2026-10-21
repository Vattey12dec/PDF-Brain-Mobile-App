import hashlib
import re
from dataclasses import dataclass
from pathlib import Path
from typing import List
import fitz  # PyMuPDF
from fastapi import HTTPException, UploadFile, status
from app.core.config import settings

PDF_MAGIC_BYTES = b"%PDF-"


@dataclass
class ExtractedPage:
    page_number: int
    text: str


@dataclass
class ExtractedPDFResult:
    page_count: int
    pages: List[ExtractedPage]


def sanitize_display_filename(filename: str) -> str:
    clean_name = Path(filename or "document.pdf").name
    clean_name = re.sub(r"[^\w\.\-\(\) ]+", "_", clean_name).strip()
    if not clean_name.lower().endswith(".pdf"):
        clean_name += ".pdf"
    return clean_name[:200]


async def read_and_validate_pdf_upload(upload_file: UploadFile) -> tuple[bytes, str, str]:
    raw_filename = upload_file.filename or ""
    if not raw_filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Only PDF files (.pdf) are allowed.",
        )

    file_bytes = await upload_file.read()
    max_bytes = settings.MAX_FILE_SIZE_MB * 1024 * 1024

    if len(file_bytes) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The uploaded PDF file is empty (0 bytes).",
        )

    if len(file_bytes) > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"PDF file exceeds the maximum allowed size of {settings.MAX_FILE_SIZE_MB} MB.",
        )

    if not file_bytes.startswith(PDF_MAGIC_BYTES):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid PDF file signature. The file does not contain a valid %PDF- header.",
        )

    safe_filename = sanitize_display_filename(raw_filename)
    file_hash = hashlib.sha256(file_bytes).hexdigest()
    return file_bytes, safe_filename, file_hash


def extract_text_from_pdf_bytes(file_bytes: bytes) -> ExtractedPDFResult:
    try:
        doc = fitz.open(stream=file_bytes, filetype="pdf")
    except Exception as exc:
        raise ValueError("Corrupted or unreadable PDF file. Could not parse PDF structure.") from exc

    if doc.is_encrypted:
        doc.close()
        raise ValueError("Password-protected or encrypted PDFs are not supported.")

    page_count = len(doc)
    if page_count == 0:
        doc.close()
        raise ValueError("The uploaded PDF contains 0 pages.")

    extracted_pages: List[ExtractedPage] = []
    total_non_whitespace_chars = 0

    for idx in range(page_count):
        page = doc.load_page(idx)
        raw_text = page.get_text("text") or ""
        cleaned_text = re.sub(r"[ \t]+", " ", raw_text).strip()
        if cleaned_text:
            total_non_whitespace_chars += len(cleaned_text)
            extracted_pages.append(ExtractedPage(page_number=idx + 1, text=cleaned_text))

    doc.close()

    if total_non_whitespace_chars < 15:
        raise ValueError(
            "No extractable text found in this PDF. It appears to be a scanned image-only PDF. "
            "OCR is not enabled in this build; please upload a PDF containing selectable digital text."
        )

    return ExtractedPDFResult(page_count=page_count, pages=extracted_pages)