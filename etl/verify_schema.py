"""
verify_schema.py — Auditoría de FASE 1.

Compara los headers reales de los CSVs en data/raw/ contra las columnas
de las tablas raw.* en PostgreSQL (information_schema.columns).

Criterio de éxito: para cada módulo, el conjunto de columnas del CSV debe
ser IDÉNTICO al de la tabla (ni faltantes ni sobrantes).

Uso:
    python etl/verify_schema.py

Requiere: variables DB_HOST, DB_NAME, DB_USER, DB_PASSWORD en .env
"""

import csv
import logging
import os
import sys
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"
LOG_DIR = PROJECT_ROOT / "etl" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "verify_schema.log", encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger(__name__)

# Módulos base del proyecto más el módulo diferenciador de Omar.
MODULES = {
    "identificacion": "identificacion.csv",
    "caracteristicas": "caracteristicas.csv",
    "ubicacion": "sitio_ubicacion.csv",
    "ventas": "ventas_ingresos.csv",
    "factores_exp": "factores_expansion.csv",
    "tic": "tic.csv",
}


# ---------------------------------------------------------------------------
# Funciones
# ---------------------------------------------------------------------------


def get_db_connection() -> psycopg2.extensions.connection:
    """Crea conexión a PostgreSQL leyendo credenciales desde .env."""
    load_dotenv(PROJECT_ROOT / ".env")
    required = ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD"]
    missing = [v for v in required if not os.getenv(v)]
    if missing:
        log.error(
            "Faltan variables en .env: %s. Copia .env.example y complétalo.", missing
        )
        sys.exit(1)
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        port=os.getenv("DB_PORT", "5432"),
    )


def read_csv_header(csv_path: Path) -> list[str]:
    """Lee solo la primera línea del CSV y devuelve los nombres de columna."""
    with open(csv_path, newline="", encoding="utf-8") as f:
        return next(csv.reader(f))


def get_table_columns(conn, table_name: str) -> list[str]:
    """Devuelve las columnas de raw.<table_name> ordenadas según la BD."""
    query = """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'raw' AND table_name = %s
        ORDER BY ordinal_position;
    """
    with conn.cursor() as cur:
        cur.execute(query, (table_name,))
        return [row[0] for row in cur.fetchall()]


def verify_module(conn, table: str, csv_file: str) -> bool:
    """Compara header del CSV vs columnas de la tabla. True si coinciden."""
    csv_path = RAW_DIR / csv_file
    if not csv_path.exists():
        log.error("[%s] CSV no encontrado: %s", table, csv_path)
        return False

    csv_cols = read_csv_header(csv_path)
    db_cols = get_table_columns(conn, table)

    if not db_cols:
        log.error("[%s] La tabla raw.%s no existe o no tiene columnas.", table, table)
        return False

    missing_in_db = set(csv_cols) - set(db_cols)
    extra_in_db = set(db_cols) - set(csv_cols)

    if not missing_in_db and not extra_in_db:
        log.info("[%s] OK — %d columnas coinciden exactamente.", table, len(csv_cols))
        return True

    if missing_in_db:
        log.error(
            "[%s] Columnas en CSV pero NO en BD: %s", table, sorted(missing_in_db)
        )
    if extra_in_db:
        log.error("[%s] Columnas en BD pero NO en CSV: %s", table, sorted(extra_in_db))
    return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    log.info("=== Auditoría de schema raw vs CSVs (FASE 1) ===")
    conn = get_db_connection()
    try:
        results = {t: verify_module(conn, t, f) for t, f in MODULES.items()}
    finally:
        conn.close()

    failed = [t for t, ok in results.items() if not ok]
    if failed:
        log.error("Auditoría FALLIDA en: %s", failed)
        sys.exit(1)
    log.info(
        "Auditoría EXITOSA — las %d tablas raw coinciden con sus CSVs.", len(results)
    )


if __name__ == "__main__":
    main()
