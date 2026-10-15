-- 1. Ingreso promedio ponderado por sector, a nivel nacional y departamental.

WITH base_ingresos AS (
    SELECT
        i.cod_depto,
        i.grupos12,
        v.ventas_mes_anterior,
        v.fex_c
    FROM staging.identificacion AS i
    INNER JOIN staging.ventas AS v
        ON  v.directorio = i.directorio
        AND v.secuencia_p = i.secuencia_p
        AND v.secuencia_encuesta = i.secuencia_encuesta
    WHERE v.ventas_mes_anterior IS NOT NULL
      AND v.fex_c IS NOT NULL
      AND v.fex_c > 0
      AND i.grupos12 IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12')
),
ingresos_agregados AS (
    SELECT
        'Nacional' AS nivel,
        NULL AS cod_depto,
        grupos12,
        COUNT(*) AS micronegocios_muestra,
        SUM(fex_c) AS micronegocios_expandidos,
        SUM(ventas_mes_anterior * fex_c) / NULLIF(SUM(fex_c), 0) AS ingreso_promedio_ponderado
    FROM base_ingresos
    GROUP BY grupos12

    UNION ALL

    SELECT
        'Departamental' AS nivel,
        cod_depto,
        grupos12,
        COUNT(*) AS micronegocios_muestra,
        SUM(fex_c) AS micronegocios_expandidos,
        SUM(ventas_mes_anterior * fex_c) / NULLIF(SUM(fex_c), 0) AS ingreso_promedio_ponderado
    FROM base_ingresos
    GROUP BY cod_depto, grupos12
)
SELECT
    nivel,
    cod_depto,
    grupos12,
    micronegocios_muestra,
    ROUND(micronegocios_expandidos, 2) AS micronegocios_expandidos,
    ROUND(ingreso_promedio_ponderado, 2) AS ingreso_promedio_ponderado
FROM ingresos_agregados
ORDER BY nivel, cod_depto NULLS FIRST, ingreso_promedio_ponderado DESC NULLS LAST;


-- Validaciones complementarias de ingresos.
SELECT COUNT(*) FROM staging.identificacion i;

SELECT DISTINCT i."GRUPOS4", i."GRUPOS12" FROM raw.identificacion i;

SELECT
    i.cod_depto,
    i.grupos12,
    v.ventas_mes_anterior,
    v.fex_c,
    (v.ventas_mes_anterior * v.fex_c) AS ingreso_expandido_calculado
FROM staging.identificacion AS i
INNER JOIN staging.ventas AS v
    ON  v.directorio = i.directorio
    AND v.secuencia_p = i.secuencia_p
    AND v.secuencia_encuesta = i.secuencia_encuesta
WHERE v.ventas_mes_anterior IS NOT NULL
  AND v.fex_c IS NOT NULL
  AND v.fex_c > 0
  AND i.grupos12 = '05'
  AND i.cod_depto = '54'
LIMIT 1000;

WITH totales_departamentales AS (
    SELECT
        i.cod_depto,
        COUNT(*) AS muestra,
        SUM(v.fex_c) AS fex_c_total,
        SUM(v.ventas_mes_anterior * v.fex_c) AS ingreso_total_expandido
    FROM staging.identificacion AS i
    INNER JOIN staging.ventas AS v
        ON  v.directorio = i.directorio
        AND v.secuencia_p = i.secuencia_p
        AND v.secuencia_encuesta = i.secuencia_encuesta
    WHERE v.ventas_mes_anterior IS NOT NULL
      AND v.fex_c IS NOT NULL
      AND i.grupos12 = '05'
    GROUP BY i.cod_depto
)
SELECT
    'Nacional Calculado desde Deptos' AS nivel,
    SUM(muestra) AS muestra_nacional,
    ROUND(SUM(fex_c_total), 2) AS fex_c_nacional,
    ROUND(
        SUM(ingreso_total_expandido) / NULLIF(SUM(fex_c_total), 0),
        2
    ) AS promedio_ponderado_nacional
FROM totales_departamentales;

-- 2. Formalización por ciudad: índice promedio y cumplimiento de los cuatro criterios.

WITH indicadores_formalizacion AS (
    SELECT
        i.area,
        i.fex_c,
        CASE WHEN c.p1633 = 1 THEN 1 ELSE 0 END AS tiene_rut,
        CASE WHEN c.p1055 = 1 THEN 1 ELSE 0 END AS tiene_camara,
        CASE WHEN c.p640 IN (1, 2, 4) THEN 1 ELSE 0 END
            AS tiene_registro_contable_formal,
        CASE
            WHEN c.p2991 = 1 OR c.p2992 = 1 OR c.p2993 = 1 THEN 1
            ELSE 0
        END AS declaro_impuestos
    FROM staging.identificacion AS i
    INNER JOIN staging.caracteristicas AS c
        ON  c.directorio = i.directorio
        AND c.secuencia_p = i.secuencia_p
        AND c.secuencia_encuesta = i.secuencia_encuesta
    WHERE i.area IS NOT NULL
      AND i.fex_c IS NOT NULL
      AND i.fex_c > 0
),
indice_por_ciudad AS (
    SELECT
        area,
        COUNT(*) AS micronegocios_muestra,
        SUM(fex_c) AS micronegocios_expandidos,
        SUM(
            (tiene_rut + tiene_camara + tiene_registro_contable_formal
             + declaro_impuestos) * fex_c
        ) / NULLIF(4 * SUM(fex_c), 0) * 100
            AS indice_formalizacion_pct,
        SUM(
            CASE
                WHEN tiene_rut = 1
                 AND tiene_camara = 1
                 AND tiene_registro_contable_formal = 1
                 AND declaro_impuestos = 1
                THEN fex_c
                ELSE 0
            END
        ) / NULLIF(SUM(fex_c), 0) * 100 AS formalizacion_completa_pct
    FROM indicadores_formalizacion
    GROUP BY area
)
SELECT
    area,
    micronegocios_muestra,
    ROUND(micronegocios_expandidos, 2) AS micronegocios_expandidos,
    ROUND(indice_formalizacion_pct, 2) AS indice_formalizacion_pct,
    ROUND(formalizacion_completa_pct, 2) AS formalizacion_completa_pct
FROM indice_por_ciudad
ORDER BY indice_formalizacion_pct DESC NULLS LAST,
         formalizacion_completa_pct DESC NULLS LAST;

WITH base_rut AS (
    SELECT
        i.area,
        i.fex_c,
        CASE WHEN c.p1633 = 1 THEN 1 ELSE 0 END AS tiene_rut
    FROM staging.identificacion AS i
    INNER JOIN staging.caracteristicas AS c
        ON  c.directorio = i.directorio
        AND c.secuencia_p = i.secuencia_p
        AND c.secuencia_encuesta = i.secuencia_encuesta
    WHERE i.area IS NOT NULL
      AND i.fex_c IS NOT NULL
      AND i.fex_c > 0
),
porcentaje_rut AS (
    SELECT
        area,
        COUNT(*) AS micronegocios_muestra,
        SUM(fex_c) AS micronegocios_expandidos,
        SUM(CASE WHEN tiene_rut = 1 THEN fex_c ELSE 0 END)
            / NULLIF(SUM(fex_c), 0) * 100 AS pct_tiene_rut
    FROM base_rut
    GROUP BY area
)
SELECT
    area,
    micronegocios_muestra,
    ROUND(micronegocios_expandidos, 2) AS micronegocios_expandidos,
    ROUND(pct_tiene_rut, 2) AS pct_tiene_rut
FROM porcentaje_rut
ORDER BY pct_tiene_rut DESC;


-- 3. Formalización por sector, clase y tamaño del negocio.

-- Tamaño según presencia de empleados remunerados.
WITH indicadores_formalizacion AS (
    SELECT
        i.grupos4,
        i.grupos12,
        i.clase_te,
        CASE
            WHEN COALESCE(i.p3032_1, 0) > 0 THEN 'Con empleados'
            ELSE 'Unipersonal'
        END AS tamano,
        i.fex_c,
        CASE WHEN c.p1633 = 1 THEN 1 ELSE 0 END AS tiene_rut,
        CASE WHEN c.p1055 = 1 THEN 1 ELSE 0 END AS tiene_camara,
        CASE WHEN c.p640 IN (1, 2, 4) THEN 1 ELSE 0 END AS tiene_registro_contable_formal,
        CASE
            WHEN c.p2991 = 1 OR c.p2992 = 1 OR c.p2993 = 1 THEN 1
            ELSE 0
        END AS declaro_impuestos
    FROM staging.identificacion AS i
    INNER JOIN staging.caracteristicas AS c
        ON  c.directorio = i.directorio
        AND c.secuencia_p = i.secuencia_p
        AND c.secuencia_encuesta = i.secuencia_encuesta
    WHERE i.grupos12 IS NOT NULL
      AND i.clase_te IS NOT NULL
      AND i.fex_c IS NOT NULL
      AND i.fex_c > 0
      AND i.grupos12 IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12')
      AND i.grupos4 IN ('01', '02', '03', '04')
),
segmentos AS (
    SELECT
        grupos4,
        grupos12,
        clase_te,
        tamano,
        COUNT(*) AS micronegocios_muestra,
        SUM(fex_c) AS micronegocios_expandidos,
        SUM(
            (tiene_rut + tiene_camara + tiene_registro_contable_formal
             + declaro_impuestos) * fex_c
        ) / NULLIF(4 * SUM(fex_c), 0) * 100
            AS indice_formalizacion_pct,
        SUM(
            CASE
                WHEN tiene_rut = 1
                 AND tiene_camara = 1
                 AND tiene_registro_contable_formal = 1
                 AND declaro_impuestos = 1
                THEN fex_c
                ELSE 0
            END
        ) / NULLIF(SUM(fex_c), 0) * 100 AS formalizacion_completa_pct
    FROM indicadores_formalizacion
    GROUP BY grupos4, grupos12, clase_te, tamano
)
SELECT
    grupos4,
    grupos12,
    clase_te,
    tamano,
    micronegocios_muestra,
    ROUND(micronegocios_expandidos, 2) AS micronegocios_expandidos,
    ROUND(indice_formalizacion_pct, 2) AS indice_formalizacion_pct,
    ROUND(formalizacion_completa_pct, 2) AS formalizacion_completa_pct
FROM segmentos
ORDER BY indice_formalizacion_pct ASC NULLS LAST,
         formalizacion_completa_pct ASC NULLS LAST;


-- Tamaño según el total de personas ocupadas.
WITH indicadores_formalizacion AS (
    SELECT
        i.grupos4,
        i.grupos12,
        i.clase_te,
        CASE
            WHEN (
                1
                + COALESCE(i.p3032_1, 0)
                + COALESCE(i.p3032_2, 0)
                + COALESCE(i.p3032_3, 0)
            ) = 1 THEN 'Unipersonal'
            WHEN (
                1
                + COALESCE(i.p3032_1, 0)
                + COALESCE(i.p3032_2, 0)
                + COALESCE(i.p3032_3, 0)
            ) BETWEEN 2 AND 5 THEN 'Micro (2-5)'
            WHEN (
                1
                + COALESCE(i.p3032_1, 0)
                + COALESCE(i.p3032_2, 0)
                + COALESCE(i.p3032_3, 0)
            ) >= 6 THEN 'Pequeño (6+)'
        END AS tamano,
        i.fex_c,
        CASE WHEN c.p1633 = 1 THEN 1 ELSE 0 END AS tiene_rut,
        CASE WHEN c.p1055 = 1 THEN 1 ELSE 0 END AS tiene_camara,
        CASE WHEN c.p640 IN (1, 2, 4) THEN 1 ELSE 0 END AS tiene_registro_contable_formal,
        CASE
            WHEN c.p2991 = 1 OR c.p2992 = 1 OR c.p2993 = 1 THEN 1
            ELSE 0
        END AS declaro_impuestos
    FROM staging.identificacion AS i
    INNER JOIN staging.caracteristicas AS c
        ON  c.directorio = i.directorio
        AND c.secuencia_p = i.secuencia_p
        AND c.secuencia_encuesta = i.secuencia_encuesta
    WHERE i.grupos12 IS NOT NULL
      AND i.clase_te IS NOT NULL
      AND i.fex_c IS NOT NULL
      AND i.fex_c > 0
      AND i.grupos12 IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12')
      AND i.grupos4 IN ('01', '02', '03', '04')
),
segmentos AS (
    SELECT
        grupos4,
        grupos12,
        clase_te,
        tamano,
        COUNT(*) AS micronegocios_muestra,
        SUM(fex_c) AS micronegocios_expandidos,
        SUM(
            (tiene_rut + tiene_camara + tiene_registro_contable_formal
             + declaro_impuestos) * fex_c
        ) / NULLIF(4 * SUM(fex_c), 0) * 100
            AS indice_formalizacion_pct,
        SUM(
            CASE
                WHEN tiene_rut = 1
                 AND tiene_camara = 1
                 AND tiene_registro_contable_formal = 1
                 AND declaro_impuestos = 1
                THEN fex_c
                ELSE 0
            END
        ) / NULLIF(SUM(fex_c), 0) * 100 AS formalizacion_completa_pct
    FROM indicadores_formalizacion
    GROUP BY grupos4, grupos12, clase_te, tamano
)
SELECT
    grupos4,
    grupos12,
    clase_te,
    tamano,
    micronegocios_muestra,
    ROUND(micronegocios_expandidos, 2) AS micronegocios_expandidos,
    ROUND(indice_formalizacion_pct, 2) AS indice_formalizacion_pct,
    ROUND(formalizacion_completa_pct, 2) AS formalizacion_completa_pct
FROM segmentos
ORDER BY formalizacion_completa_pct ASC NULLS LAST,
         indice_formalizacion_pct ASC NULLS LAST;


-- 4. Diez departamentos con mayor variación entre el ingreso anualizado de 2023 y 2022.

WITH crecimiento_departamento AS (
    SELECT
        v.cod_depto,
        COUNT(*) AS micronegocios_muestra,
        SUM(v.fex_c) AS micronegocios_expandidos,
        SUM(v.ventas_mes_anterior * v.fex_c) * 12 AS ingresos_2023_anualizados,
        SUM(v.ventas_anio_anterior * v.fex_c) AS ingresos_2022_anual,
        (
            (SUM(v.ventas_mes_anterior * v.fex_c) * 12)
            - SUM(v.ventas_anio_anterior * v.fex_c)
        ) / NULLIF(SUM(v.ventas_anio_anterior * v.fex_c), 0) * 100
            AS variacion_interanual_pct
    FROM staging.ventas AS v
    WHERE v.cod_depto IS NOT NULL
      AND v.fex_c IS NOT NULL
      AND v.fex_c > 0
      AND v.ventas_mes_anterior IS NOT NULL
      AND v.ventas_anio_anterior IS NOT NULL
      AND v.ventas_anio_anterior > 0
    GROUP BY v.cod_depto
),
ranking AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY variacion_interanual_pct DESC NULLS LAST
        ) AS ranking_departamento
    FROM crecimiento_departamento
)
SELECT
    cod_depto,
    ranking_departamento,
    micronegocios_muestra,
    ROUND(micronegocios_expandidos, 2) AS micronegocios_expandidos,
    ROUND(ingresos_2023_anualizados, 2) AS ingresos_2023_anualizados,
    ROUND(ingresos_2022_anual, 2) AS ingresos_2022_anual,
    ROUND(variacion_interanual_pct, 2) AS variacion_interanual_pct
FROM ranking
WHERE ranking_departamento <= 10
ORDER BY ranking_departamento;