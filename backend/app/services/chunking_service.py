from dataclasses import dataclass
from typing import List
from app.services.pdf_service import ExtractedPage


@dataclass
class DocumentChunk:
    chunk_id: str
    document_id: str
    owner_id: str
    filename: str
    page_number: int
    chunk_index: int
    text: str


def create_document_chunks(
    *,
    document_id: str,
    owner_id: str,
    filename: str,
    pages: List[ExtractedPage],
    chunk_size: int = 800,
    chunk_overlap: int = 150,
) -> List[DocumentChunk]:
    if chunk_overlap >= chunk_size:
        chunk_overlap = max(0, chunk_size // 4)

    chunks: List[DocumentChunk] = []
    global_chunk_index = 0

    for page in pages:
        text = page.text.strip()
        if not text:
            continue

        start = 0
        text_len = len(text)

        while start < text_len:
            end = min(start + chunk_size, text_len)

            if end < text_len:
                sentence_break = max(
                    text.rfind(". ", start + chunk_size // 2, end),
                    text.rfind("\n", start + chunk_size // 2, end),
                )
                if sentence_break != -1 and sentence_break > start:
                    end = sentence_break + 1
                else:
                    word_break = text.rfind(" ", start + chunk_size // 2, end)
                    if word_break != -1 and word_break > start:
                        end = word_break

            chunk_str = text[start:end].strip()
            if chunk_str:
                global_chunk_index += 1
                chunk_id = f"{document_id}_p{page.page_number}_c{global_chunk_index:04d}"
                chunks.append(
                    DocumentChunk(
                        chunk_id=chunk_id,
                        document_id=document_id,
                        owner_id=owner_id,
                        filename=filename,
                        page_number=page.page_number,
                        chunk_index=global_chunk_index,
                        text=chunk_str,
                    )
                )

            if end >= text_len:
                break

            next_start = end - chunk_overlap
            start = next_start if next_start > start else end

    return chunks