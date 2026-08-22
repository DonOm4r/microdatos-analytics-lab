from __future__ import annotations

import logging
import os
from logging.handlers import RotatingFileHandler
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENV_PATH = PROJECT_ROOT / ".env"
LOG_DIR = PROJECT_ROOT / "etl" / "logs"
LOG_FILE = LOG_DIR / "etl.log"
MAX_LOG_BYTES = 2_000_000
LOG_BACKUP_COUNT = 3


def load_db_config() -> dict[str, str]:
    """Load database credentials from .env and validate required values."""
    load_dotenv(dotenv_path=ENV_PATH)

    required = ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD"]
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise RuntimeError(
            "Missing required DB variables in .env: " + ", ".join(missing)
        )

    return {
        "DB_HOST": os.environ["DB_HOST"],
        "DB_NAME": os.environ["DB_NAME"],
        "DB_USER": os.environ["DB_USER"],
        "DB_PASSWORD": os.environ["DB_PASSWORD"],
        "DB_PORT": os.getenv("DB_PORT", "5432") or "5432",
    }


def get_engine() -> Engine:
    """Create a SQLAlchemy engine connected to the project database."""
    cfg = load_db_config()
    db_url = (
        f"postgresql+psycopg2://{cfg['DB_USER']}:{cfg['DB_PASSWORD']}@"
        f"{cfg['DB_HOST']}:{cfg['DB_PORT']}/{cfg['DB_NAME']}"
    )
    return create_engine(db_url, pool_pre_ping=True, future=True)


def get_logger(name: str = "etl") -> logging.Logger:
    """Get a project logger that writes both to file and console."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    logger.propagate = False

    if logger.handlers:
        return logger

    file_handler = RotatingFileHandler(
        LOG_FILE,
        maxBytes=MAX_LOG_BYTES,
        backupCount=LOG_BACKUP_COUNT,
        encoding="utf-8",
    )
    file_handler.setFormatter(
        logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")
    )

    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(
        logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")
    )

    logger.addHandler(file_handler)
    logger.addHandler(stream_handler)
    return logger


def truncate_table(engine: Engine, schema: str, table: str) -> None:
    """Truncate a table in a schema with CASCADE to allow idempotent reloads."""
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE {schema}.{table} CASCADE;"))
