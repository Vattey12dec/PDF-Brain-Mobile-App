# AI & RAG Technical Documentation — PDF Brain

## 1. Pretrained RAG Workflow vs. Fine-Tuning
PDF Brain does not fine-tune or train an AI model when PDFs are uploaded. It uses a pretrained Retrieval-Augmented Generation (RAG) pipeline:
1. Extract text page-by-page using PyMuPDF (`fitz`).
2. Split text into overlapping page-bounded chunks (`CHUNK_SIZE=800`, `CHUNK_OVERLAP=150`).
3. Generate vector embeddings using Google's `gemini-embedding-001`.
4. Store vectors and metadata (`owner_id`, `document_id`, `filename`, `page_number`, `chunk_id`) in persistent ChromaDB.
5. Retrieve top-K (`TOP_K=5`) chunks filtered by `owner_id` and cosine distance (`MAX_DISTANCE_THRESHOLD=0.78`).
6. Pass retrieved excerpts to `gemini-2.5-flash` using structured JSON output (`LLMGenerationSchema`) and verify citations server-side.

## 2. Model Selection & Configuration
- Generation Model (`GEMINI_MODEL`): Defaults to `gemini-2.5-flash` (configurable via `.env`). Selected for low latency, large context window, and native structured JSON schema enforcement.
- Embedding Model (`EMBEDDING_MODEL`): Defaults to `gemini-embedding-001` (configurable via `.env`).

## 3. Representative Request & Response Formats

### Format 1: Normal Grounded Question Answering
Request (`POST /api/chat/ask`):
    {
      "question": "How does the TCP three-way handshake work?",
      "document_ids": ["doc_123"]
    }

Response:
    {
      "conversation_id": "conv_001",
      "message_id": "msg_002",
      "answer": "The TCP three-way handshake uses SYN, SYN-ACK, and ACK packets to establish a connection.",
      "found_in_documents": true,
      "sources": [
        {
          "document_id": "doc_123",
          "filename": "networking_notes.pdf",
          "page_number": 2,
          "excerpt": "Page 2: The TCP three-way handshake uses SYN, SYN-ACK, and ACK packets...",
          "similarity_score": 0.91
        }
      ]
    }

### Format 2: Answer-Not-Found Handling
Request (`POST /api/chat/ask`):
    {
      "question": "What is the recipe for lasagna?"
    }

Response:
    {
      "conversation_id": "conv_001",
      "message_id": "msg_004",
      "answer": "The information could not be found in the uploaded documents.",
      "found_in_documents": false,
      "sources": []
    }

### Format 3: Multi-Document Synthesis with Source Excerpts
Request (`POST /api/chat/ask`):
    {
      "question": "Compare the transport handshake in doc_one.pdf with encryption in doc_two.pdf",
      "document_ids": ["doc_1", "doc_2"]
    }

Response: Returns a synthesized answer with verified citations from both documents.

## 4. Privacy, Costs & Known Limitations
- Document excerpts and questions are sent over HTTPS to Google's Gemini API. Do not upload confidential documents.
- Scanned image-only PDFs without selectable text are rejected unless OCR is enabled.
- RAG reduces unsupported answers and verifies citation metadata, but users should always verify critical answers against the cited PDF page.