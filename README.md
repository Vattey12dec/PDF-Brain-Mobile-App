# PDF Brain — AI PDF Question-Answering System (Full-Stack RAG)

PDF Brain is a full-stack Retrieval-Augmented Generation (RAG) application built with Flutter (Material 3) on the frontend and FastAPI (Python) on the backend. Users upload PDF documents, index their contents into a persistent ChromaDB vector store using Google Gemini Embeddings (`gemini-embedding-001`), and ask natural-language questions answered with grounded citations using Google Gemini (`gemini-2.5-flash`).

## 1. System Architecture
Flutter UI -> FastAPI -> Supabase Auth (JWT) -> PyMuPDF -> Chunker -> ChromaDB -> Gemini API -> SQLite.

## 2. Backend Setup (FastAPI + Python)
1. Open a terminal in `backend/`:
       cd backend
       python -m venv .venv
       source .venv/bin/activate
       pip install -r requirements.txt
       cp .env.example .env
2. Edit `backend/.env` and add your `GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_JWT_SECRET`.
3. Run the FastAPI server:
       uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
4. Open Swagger API Docs at: `http://127.0.0.1:8000/docs`

## 3. Running Automated Backend Tests
Inside `backend/`, run:
    pytest -v

## 4. Frontend Setup (Flutter)
1. Open a terminal in `frontend/`:
       cd frontend
       flutter create .
       flutter pub get
2. Run the app:
       flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000 --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key

## 5. Localhost vs. Android Emulator vs. Physical Device
- Desktop / Web / iOS Simulator: `http://127.0.0.1:8000`
- Android Emulator: `http://10.0.2.2:8000`
- Physical Phone: Use your computer's Wi-Fi LAN IP (e.g., `http://192.168.1.45:8000`).