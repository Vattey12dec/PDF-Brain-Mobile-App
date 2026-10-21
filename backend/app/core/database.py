from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker
from app.core.config import settings

connect_args = {"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    future=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine, future=True)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    from app.models import database_models  # noqa: F401
    Base.metadata.create_all(bind=engine)
    if settings.DATABASE_URL.startswith("sqlite"):
        with engine.begin() as conn:
            cols = [row[1] for row in conn.execute(text("PRAGMA table_info(chat_history)")).fetchall()]
            if "title" not in cols:
                conn.execute(text("ALTER TABLE chat_history ADD COLUMN title VARCHAR(255)"))
            if "is_pinned" not in cols:
                conn.execute(text("ALTER TABLE chat_history ADD COLUMN is_pinned BOOLEAN NOT NULL DEFAULT 0"))