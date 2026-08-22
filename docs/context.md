---
tags:
  - context
  - dane
  - ia
  - proyectos
type: context
status: activo
created: 2026-08-09
updated: 2026-08-14
---

# Contexto del Proyecto — SQL Analysis DANE EMICRON

> [!info] Visión General
> Proyecto de portafolio individual (coordinado en equipo de 3) orientado a roles Data Analyst/Engineer en Colombia.
> **Objetivo:** Limpiar, modelar, analizar y visualizar microdatos crudos de la Encuesta de Micronegocios (EMICRON) del DANE 2023. El diferenciador es usar datos sucios reales, aplicar el factor de expansión departamental y validar los resultados contra el boletín oficial y sus anexos estadísticos.

---

## 🛠️ Stack Tecnológico
- **Base de datos:** PostgreSQL 17 (Local).
- **ETL:** Python 3.11+ (Pandas, SQLAlchemy, psycopg2-binary). Salida dual: PostgreSQL + Parquet.
- **Análisis:** SQL avanzado (CTEs, Window Functions, JOINs complejos).
- **Visualización:** Jupyter Notebook + Plotly (exportado a HTML estático).
- **Publicación:** GitHub Pages (desplegando HTML estático desde `notebooks/html/`).
- **Documentación:** Markdown + README profesional en raíz del repo.

---

## ⚙️ Comandos y Entorno
```bash
# Activar entorno virtual
.\.venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar ETL (Fase 2)
python etl/clean_data.py

# Lanzar Notebook (Fase 5)
jupyter notebook
```

**Variables de entorno (`.env`):**
- `DB_HOST=localhost`
- `DB_NAME=emicron_db`
- `DB_USER=postgres`
- `DB_PASSWORD=****` (Nunca commitear)

---

## 🤖 Reglas de Negocio del Proyecto (Inquebrantables)

1. **Motor de BD:** Usa estrictamente PostgreSQL 17. No sugieras DuckDB ni MySQL.
2. **Tipos de Datos:** Para dinero y factores de expansión usa `NUMERIC` (ej. `NUMERIC(15,2)` o `NUMERIC(20,10)`). **Prohibido usar `FLOAT` o `DOUBLE PRECISION`**.
3. **Factor de Expansión:** En TODA agregación que infiera resultados poblacionales, usa la columna `fex_c` (traída desde `factores_expansion`). No uses `f_exp` de los módulos individuales.
4. **Llaves Primarias:** Toda tabla debe tener PK compuesta por `(directorio, secuencia_p, secuencia_encuesta)`.
5. **Idempotencia:** Los scripts ETL deben ser idempotentes (usar `TRUNCATE` antes de `INSERT` para no duplicar datos en reejecuciones).
6. **Cero recortes:** TODAS las columnas del diccionario DANE deben existir en el schema inicial, sin importar si se usan o no en el análisis.
7. **Validación Oficial:** Las queries de negocio deben validar sus cifras contra el boletín oficial `bol-EMICRON-2023.pdf` y sus anexos Excel. Documentar diferencias >5% en `docs/validacion_dane.md`.
8. **README en Raíz:** El `README.md` profesional debe vivir en la raíz del repositorio (no en `docs/`), obligatorio para que GitHub lo renderice como landing page.
9. **Anexos de Referencia:** Descargar y guardar en `data/dictionaries/` los anexos Excel del DANE (`anex-EMICRON-2023.xlsx` y `anex-EMICRON-24Ciudades-2023.xlsx`) como fuente de validación. No subir a Git.

---

## 🎯 Preguntas de Negocio a Resolver (SQL)

**4 Comunes (para validación cruzada del equipo):**

1. **Sectores por ingresos:** ¿Cuáles son los sectores CIIU con mayor ingreso total mensual promedio a nivel nacional? ¿Cómo varía por departamento?
   - *Validación:* Boletín PDF Tabla 1 (pág 7) + Anexo nacional Cuadro I.2.

2. **Ciudades con mayor formalización empresarial:** ¿Qué ciudades principales y áreas metropolitanas (de las 24 del DANE) concentran la mayor proporción de micronegocios formalizados? Formalización medida como índice compuesto: tenencia de RUT, registro en Cámara de Comercio, tipo de registro contable formal, y declaración de impuestos.
   - *Validación:* Anexo 24 ciudades Cuadros F.1, F.4, F.6.

3. **Segmentos con menor formalización empresarial:** ¿Qué combinaciones de sector económico (GRUPOS4/GRUPOS12) + dominio geográfico (cabeceras vs centros poblados/rural) + tamaño del micronegocio muestran los niveles más bajos de formalización?
   - *Validación:* Anexo nacional Cuadros F.1, F.4, F.6, F.11-F.13.

4. **Ranking de crecimiento interanual de ingresos:** ¿Cuáles son los 10 departamentos y/o 24 ciudades principales con mayor crecimiento porcentual interanual en ingresos del micronegocio (2023 vs 2022)?
   - *Validación:* Boletín PDF Tabla 1 (pág 7) + Anexo 24 ciudades Cuadro I.1.

**1 Propia (Módulo Diferenciador):**

- **Kevin (Inclusión financiera):** ¿Qué proporción de micronegocios accede a crédito formal vs informal, y cómo varía por región y sector? Análisis de solicitud, aprobación, negación y uso del crédito.
  - *Validación:* Anexo nacional Cuadros H.2, H.4, H.5, H.5A.

- **Omar (TIC):** ¿Cuál es la brecha digital de los micronegocios (uso de internet, presencia web, medios de pago digitales) por departamento y tamaño?
  - *Validación:* Anexo nacional Cuadros G.1, G.9, G.14.

- **Juan (Costos, gastos y activos):** ¿Cómo se distribuye la estructura de costos (fijos vs variables) y qué relación tiene con la rentabilidad estimada por sector?
  - *Nota importante:* El DANE no publica anexos de divulgación para este módulo. La pregunta se responde como **análisis exploratorio puro** de los microdatos crudos. Documentar en README esta limitación como valor diferenciador: *"Analizo una dimensión que el DANE recolecta pero no publica en cuadros oficiales."*

---

## 📂 Módulos de Datos (CSV en `data/raw/`)

**Núcleo (Comunes para los 3 integrantes):**
1. `identificacion.csv` (Llaves primarias y datos del propietario)
2. `caracteristicas.csv` (Formalización, sector, registros)
3. `ventas_ingresos.csv` (Ingresos actuales y año anterior - 72 columnas)
4. `sitio_ubicacion.csv` (Dept/Municipio, tipo de local)
5. `factores_expansion.csv` (Contiene `fex_c` - obligatorio para representatividad)

**Diferenciador (uno por persona):**
- Kevin: `inclusion_financiera.csv`
- Omar: `tic.csv`
- Juan: `costos_gastos_activos.csv`

**Documentos de validación (en `data/dictionaries/`, no subir a Git):**
- `bol-EMICRON-2023.pdf`
- `anex-EMICRON-2023.xlsx`
- `anex-EMICRON-24Ciudades-2023.xlsx`