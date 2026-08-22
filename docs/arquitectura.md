---
tags:
  - arquitectura
  - dane
  - proyectos
type: arquitectura
status: activo
created: 2026-08-09
updated: 2026-08-14
---

# Arquitectura y Sistema Técnico (DANE EMICRON)

> [!tip] Guía para IA
> Este documento explica CÓMO funciona el sistema por debajo y POR QUÉ se tomaron estas decisiones. Al generar código SQL o Python, respeta estrictamente esta arquitectura.

---

## 1. Arquitectura de Datos (2 Schemas)

Se utilizan exactamente 2 schemas en PostgreSQL. No se crea un schema `analytics` separado para evitar over-engineering.

| Schema | Propósito | Naming de Columnas | Justificación |
| --- | --- | --- | --- |
| `raw` | Datos cargados directamente desde CSV. Mínima transformación. | **Mayúsculas originales del DANE** (ej: `DIRECTORIO`, `P3057`, `VENTAS_MES_ANTERIOR`). | Inmutabilidad. Permite re-procesar si el ETL cambia. Trazabilidad total contra la fuente. |
| `staging` | Datos limpios, tipados, listos para análisis. | **Minúsculas/snake_case** (ej: `directorio`, `p3057`, `ventas_mes_anterior`). | Aquí viven las queries analíticas y las vistas. Separación clara entre ingestión y análisis. |

**Tablas Obligatorias (en ambos schemas):**
`identificacion`, `caracteristicas`, `ubicacion`, `ventas`, `factores_exp`, `[modulo_diferenciador]`.

**Tipos de Datos Exactos:**
- Códigos DANE y categóricas: `INTEGER`
- Dinero (P30##, VENTAS_*, VALOR_AGREGADO, INGRESO_MIXTO): `NUMERIC(15,2)`
- Factores de expansión (`f_exp`, `fex_c`): `NUMERIC(20,10)`
- Texto libre: `VARCHAR`

**Índices Obligatorios:**
- PK compuesta en todas las tablas: `(directorio, secuencia_p, secuencia_encuesta)`
- Individual en: `cod_depto`, `grupos4`, `grupos12`, `fex_c`
- `COMMENT ON COLUMN` en cada columna con la descripción exacta del diccionario DANE.

---

## 2. Flujo ETL (Extract → Transform → Load)

1. **Extract:** Leer CSVs de `data/raw/` (ej. `identificacion.csv`).
2. **Load to Raw:** Insertar a `raw.*` tal cual vienen (columnas en mayúscula, nombres idénticos al CSV).
3. **Transform:**
   - Renombrar a minúsculas/snake_case.
   - Castear tipos de datos (ej. `VENTAS_MES_ANTERIOR` a `NUMERIC`).
   - Hacer JOIN con `factores_expansion` para traer `fex_c`.
4. **Load to Staging:** Insertar datos limpios en `staging.*`. La columna `fex_c` debe existir en **todas** las tablas de staging (ya sea replicándola en cada tabla o mediante una vista maestra `staging.v_micronegocios_core` que una `identificacion` + `factores_exp`). La forma recomendada para este proyecto: añadir `fex_c` directamente a cada tabla `staging.*` durante el ETL para simplificar las queries analíticas posteriores.
5. **Export:** Guardar `data/processed/emicron_core.parquet` para consumo ágil en Jupyter.

---

## 3. Manual de Decisiones (El "Por Qué")

### ¿Por qué PostgreSQL y no DuckDB/MySQL?
PostgreSQL es el estándar del mercado laboral colombiano para roles Data en el 80% de vacantes. Su optimizador es superior para CTEs y Window Functions. DuckDB es potente pero desconocido para reclutadores locales; MySQL está más orientado a OLTP.

### ¿Por qué dos schemas (`raw` y `staging`)?
Si mezclas datos sucios con limpios, pierdes trazabilidad. `raw` es la bodega inmutable; `staging` es la mesa de trabajo. Un tercer schema `analytics` es innecesario para 6 tablas (over-engineering).

### ¿Por qué la llave compuesta `(directorio, secuencia_p, secuencia_encuesta)`?
El DANE encuesta hogares, no negocios directamente. Un hogar (`DIRECTORIO`) puede tener múltiples personas (`SECUENCIA_P`) y cada persona múltiples encuestas/negocios (`SECUENCIA_ENCUESTA`). Usar solo `DIRECTORIO` mezclaría micronegocios distintos.

### ¿Por qué `NUMERIC` y no `FLOAT` para dinero?
Los flotantes almacenan binarios inexactos (`0.1` -> `0.10000000000000000555...`). Sumar muchos ingresos con `FLOAT` genera centavos fantasmas. `NUMERIC(15,2)` garantiza precisión exacta. Los factores de expansión usan `NUMERIC(20,10)` por sus 10 decimales estadísticos.

### ¿Por qué `fex_c` y no `f_exp`?
Cada módulo trae su `F_EXP`, pero el DANE publicó "Factores de expansión departamentales 2023" con `FEX_C` como corrección oficial. Usar `fex_c` garantiza que nuestras cifras coincidan con el boletín oficial `bol-EMICRON-2023.pdf`.

### ¿Por qué el ETL debe ser "idempotente"?
Si depuras y ejecutas el script 5 veces, sin `TRUNCATE` previo tendrías 5x las filas y todas tus queries darían resultados falsos. La idempotencia asegura que el resultado sea el mismo sin importar cuántas veces se corra.

### ¿Por qué exportar a Parquet además de PostgreSQL?
Parquet es 10x más rápido de leer que CSV, comprime mejor y conserva tipos de datos. El notebook de Jupyter lee Parquet directamente con `pandas.read_parquet()`, evitando conexiones a BD en cada iteración visual.

### ¿Por qué Sanity Checks antes del análisis?
Validar integridad referencial, rangos y suma de `fex_c` vs boletín DANE demuestra rigor metodológico. "Operar" (analizar) sin revisar "signos vitales" (calidad de datos) es mala práctica.

### ¿Por qué HTML estático y no nbviewer/GitHub nativo?
GitHub no renderiza Plotly nativamente. nbviewer tiene fallas de caché. Exportar con `nbconvert --to html --no-input` embebe el JS de Plotly, se ve perfecto en GitHub Pages y oculta el código sucio al reclutador, mostrando solo gráficos y conclusiones.

### ¿Por qué README en la raíz?
GitHub renderiza automáticamente como landing page solo el `README.md` que está en la raíz del repositorio. Si vive en `docs/`, el reclutador ve una lista de carpetas y debe hacer clic para encontrar tu documentación.
