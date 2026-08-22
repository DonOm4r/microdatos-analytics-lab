from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

if __package__ in {None, ""}:
    project_root = Path(__file__).resolve().parent.parent
    if str(project_root) not in sys.path:
        sys.path.insert(0, str(project_root))

from etl.utils import get_engine, get_logger, load_db_config, truncate_table

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

RAW_MODULES = {
    "identificacion": "identificacion.csv",
    "caracteristicas": "caracteristicas.csv",
    "ubicacion": "sitio_ubicacion.csv",
    "ventas": "ventas_ingresos.csv",
    "factores_exp": "factores_expansion.csv",
}

KEY_COLUMNS = ["directorio", "secuencia_p", "secuencia_encuesta"]

STAGING_COLUMNS = {
    "identificacion": [
        "directorio",
        "secuencia_p",
        "secuencia_encuesta",
        "cod_depto",
        "area",
        "clase_te",
        "p35",
        "p241",
        "mes_ref",
        "p3031",
        "p3032_1",
        "p3032_2",
        "p3032_3",
        "p3033",
        "p3034",
        "p3035",
        "p3000",
        "grupos4",
        "grupos12",
        "f_exp",
        "fex_c",
    ],
    "caracteristicas": [
        "directorio",
        "secuencia_p",
        "secuencia_encuesta",
        "p1633",
        "p986",
        "p640",
        "p4000",
        "p1055",
        "p1056",
        "p661",
        "p1057",
        "p4004",
        "p2991",
        "p2992",
        "p2993",
        "clase_te",
        "cod_depto",
        "area",
        "f_exp",
        "fex_c",
    ],
    "ubicacion": [
        "directorio",
        "secuencia_p",
        "secuencia_encuesta",
        "p3053",
        "p3095",
        "p3096",
        "p3097",
        "p3098",
        "p3054",
        "p3055",
        "p469",
        "clase_te",
        "cod_depto",
        "area",
        "f_exp",
        "fex_c",
    ],
    "ventas": [
        "directorio",
        "secuencia_p",
        "secuencia_encuesta",
        "p3057",
        "p3058",
        "p3059",
        "p3060",
        "p3061",
        "p3062",
        "p4002",
        "p3063",
        "p3064",
        "p3065",
        "p3066",
        "p3067",
        "p3092",
        "p3093",
        "p4036",
        "p4005",
        "p4006",
        "p4007",
        "p4008",
        "p4009",
        "p4010",
        "p4011",
        "p4012",
        "p4013",
        "p4014",
        "p4015",
        "p4016",
        "p4017",
        "p4018",
        "p4037",
        "p3068_ene",
        "p3068_feb",
        "p3068_mar",
        "p3068_abr",
        "p3068_may",
        "p3068_jun",
        "p3068_jul",
        "p3068_ago",
        "p3068_sep",
        "p3068_oct",
        "p3068_nov",
        "p3068_dic",
        "p3068_tod",
        "p3068_nin",
        "p4019",
        "p4020",
        "p4021",
        "p4022",
        "p4023",
        "p4024",
        "p4025",
        "p4026",
        "p4027",
        "p4028",
        "p4029",
        "p4030",
        "p4031",
        "p4032",
        "p4038",
        "p3072",
        "ventas_mes_anterior",
        "ventas_mes_anio_anterior",
        "ventas_anio_anterior",
        "valor_agregado",
        "ingreso_mixto",
        "clase_te",
        "cod_depto",
        "area",
        "f_exp",
        "fex_c",
    ],
    "factores_exp": [
        "directorio",
        "secuencia_p",
        "secuencia_encuesta",
        "fex_c",
    ],
}


def _normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [str(col).strip().lower() for col in df.columns]
    return df


def _preserve_csv_headers(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [str(col).strip() for col in df.columns]
    return df


def _replace_empty_with_na(series: pd.Series) -> pd.Series:
    """Reemplaza cadenas vacías (y nulos ya existentes) por pd.NA."""
    return series.mask(series.isna() | (series == "") | (series == " "), pd.NA)


def _clean_strings(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    for col in df.columns:
        if df[col].dtype == object:
            df[col] = _replace_empty_with_na(df[col])
    return df


def _normalize_blank_numeric_values(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df = df.replace(r"^\s*$", pd.NA, regex=True)
    return df


def _write_table_in_chunks(
    engine,
    df: pd.DataFrame,
    schema: str,
    table_name: str,
    chunksize: int = 1,
) -> None:
    """Write a dataframe row-by-row in tiny chunks to avoid PostgreSQL parameter limits."""
    for start in range(0, len(df), chunksize):
        chunk = df.iloc[start : start + chunksize]
        chunk.to_sql(
            name=table_name,
            con=engine,
            schema=schema,
            index=False,
            if_exists="append",
            method="multi",
            chunksize=1,
        )


def _coerce_numeric_columns(df: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    df = df.copy()
    for col in columns:
        if col in df.columns:
            df[col] = pd.to_numeric(_replace_empty_with_na(df[col]), errors="coerce")
    return df


def ensure_raw_files() -> None:
    missing = [
        str(RAW_DIR / csv_name)
        for _, csv_name in RAW_MODULES.items()
        if not (RAW_DIR / csv_name).exists()
    ]
    if missing:
        raise FileNotFoundError(
            "Faltan CSVs requeridos en data/raw/: " + ", ".join(missing)
        )


def load_raw_tables(engine) -> None:
    logger = get_logger("etl")
    for table_name, csv_name in RAW_MODULES.items():
        csv_path = RAW_DIR / csv_name
        logger.info("Cargando raw.%s desde %s", table_name, csv_path.name)
        df = pd.read_csv(csv_path, dtype=str, keep_default_na=False)
        df = _clean_strings(df)
        df = _preserve_csv_headers(df)
        truncate_table(engine, "raw", table_name)
        _write_table_in_chunks(engine, df, "raw", table_name, chunksize=50)
        logger.info("raw.%s cargada: %d filas", table_name, len(df))


def build_staging_tables(engine) -> None:
    logger = get_logger("etl")
    factors = pd.read_sql_query("SELECT * FROM raw.factores_exp", engine)
    factors = _normalize_columns(factors)
    factors = factors[KEY_COLUMNS + ["fex_c"]]
    factors["fex_c"] = pd.to_numeric(factors["fex_c"], errors="coerce")

    for table_name, expected_columns in STAGING_COLUMNS.items():
        logger.info("Transformando staging.%s", table_name)
        raw_df = pd.read_sql_query(f"SELECT * FROM raw.{table_name}", engine)
        raw_df = _normalize_columns(raw_df)
        raw_df = _clean_strings(raw_df)
        raw_df = _normalize_blank_numeric_values(raw_df)

        if table_name != "factores_exp":
            raw_df = raw_df.merge(factors, on=KEY_COLUMNS, how="left")

        if "f_exp" in raw_df.columns:
            raw_df["f_exp"] = pd.to_numeric(raw_df["f_exp"], errors="coerce")
        if "fex_c" in raw_df.columns:
            raw_df["fex_c"] = pd.to_numeric(raw_df["fex_c"], errors="coerce")

        # Convert key columns to nullable integers
        for col in KEY_COLUMNS:
            if col in raw_df.columns:
                raw_df[col] = pd.to_numeric(raw_df[col], errors="coerce").astype(
                    "Int64"
                )

        text_like_columns = {"cod_depto", "area", "mes_ref", "grupos4", "grupos12"}
        for col in raw_df.columns:
            if col in text_like_columns:
                continue
            if col not in {"directorio", "secuencia_p", "secuencia_encuesta"}:
                raw_df[col] = pd.to_numeric(raw_df[col], errors="coerce")

        # Cast integer-like columns that appear in the stage schema
        integer_fields = {
            "clase_te",
            "p35",
            "p241",
            "p3031",
            "p3032_1",
            "p3032_2",
            "p3032_3",
            "p3033",
            "p3034",
            "p3035",
            "p3000",
            "p1633",
            "p986",
            "p640",
            "p4000",
            "p1055",
            "p1056",
            "p661",
            "p1057",
            "p4004",
            "p2991",
            "p2992",
            "p2993",
            "p3053",
            "p3095",
            "p3096",
            "p3097",
            "p3098",
            "p3054",
            "p3055",
            "p469",
            "p3068_ene",
            "p3068_feb",
            "p3068_mar",
            "p3068_abr",
            "p3068_may",
            "p3068_jun",
            "p3068_jul",
            "p3068_ago",
            "p3068_sep",
            "p3068_oct",
            "p3068_nov",
            "p3068_dic",
            "p3068_tod",
            "p3068_nin",
        }
        for col in sorted(integer_fields):
            if col in raw_df.columns:
                raw_df[col] = pd.to_numeric(raw_df[col], errors="coerce").astype(
                    "Int64"
                )

        # Ensure the column order matches the final table structure
        raw_df = raw_df[[col for col in expected_columns if col in raw_df.columns]]

        # Add missing columns if some are absent due to source format differences
        for col in expected_columns:
            if col not in raw_df.columns:
                raw_df[col] = pd.NA

        raw_df = raw_df[expected_columns]
        truncate_table(engine, "staging", table_name)
        _write_table_in_chunks(engine, raw_df, "staging", table_name, chunksize=50)
        logger.info("staging.%s cargada: %d filas", table_name, len(raw_df))


def export_core_parquet(engine) -> Path:
    logger = get_logger("etl")
    core_df = pd.read_sql_query(
        "SELECT * FROM staging.identificacion ORDER BY directorio, secuencia_p, secuencia_encuesta",
        engine,
    )

    for table_name in ["caracteristicas", "ubicacion", "ventas"]:
        extra = pd.read_sql_query(
            f"SELECT * FROM staging.{table_name} ORDER BY directorio, secuencia_p, secuencia_encuesta",
            engine,
        )
        core_df = core_df.merge(
            extra,
            on=KEY_COLUMNS,
            how="left",
            suffixes=("", f"_{table_name}"),
        )

    output_path = PROCESSED_DIR / "emicron_core.parquet"
    core_df.to_parquet(output_path, index=False)
    logger.info("Parquet exportado en %s", output_path)
    return output_path


def main() -> None:
    logger = get_logger("etl")
    logger.info("=== INICIO ETL FASE 2 ===")
    engine = get_engine()
    try:
        load_db_config()
        ensure_raw_files()
        load_raw_tables(engine)
        build_staging_tables(engine)
        export_core_parquet(engine)
        logger.info("=== ETL FASE 2 COMPLETADO EXITOSAMENTE ===")
    except Exception as exc:  # pragma: no cover - logging path for runtime failures
        error_detail = str(exc).splitlines()[0][:300]
        logger.error("ETL falló (%s): %s", type(exc).__name__, error_detail)
        raise
    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
