-- Brecha digital por departamento y tamaño del negocio.
WITH base_tic AS (
    SELECT
        t.cod_depto,
        CASE
            WHEN COALESCE(i.p3032_1, 0) > 0 THEN 'Con empleados'
            ELSE 'Unipersonal'
        END AS tamano,
        t.fex_c,
        CASE
            WHEN t.p2524 = 1 THEN 1
            ELSE 0
        END AS tiene_internet,
        CASE
            WHEN t.p2532 = 1 THEN 1
            ELSE 0
        END AS tiene_web,
        CASE
            WHEN t.p1006_7 = 1 THEN 1
            ELSE 0
        END AS vende_online
    FROM staging.tic AS t
    INNER JOIN staging.identificacion AS i
        ON  i.directorio = t.directorio
        AND i.secuencia_p = t.secuencia_p
        AND i.secuencia_encuesta = t.secuencia_encuesta
    WHERE t.fex_c IS NOT NULL
      AND t.fex_c > 0
      AND t.cod_depto IS NOT NULL
),
resumen_brecha AS (
    SELECT
        cod_depto,
        tamano,
        COUNT(*) AS muestra,
        SUM(fex_c) AS total_expandidos,
        SUM(CASE WHEN tiene_internet = 1 THEN fex_c ELSE 0 END) AS internet_expandidos,
        SUM(CASE WHEN tiene_web = 1 THEN fex_c ELSE 0 END) AS web_expandidos,
        SUM(CASE WHEN vende_online = 1 THEN fex_c ELSE 0 END) AS online_expandidos
    FROM base_tic
    GROUP BY cod_depto, tamano
)
SELECT
    cod_depto,
    tamano,
    muestra,
    ROUND(total_expandidos, 2) AS total_expandidos,
    ROUND((internet_expandidos / NULLIF(total_expandidos, 0)) * 100, 2) AS pct_acceso_internet,
    ROUND((web_expandidos / NULLIF(total_expandidos, 0)) * 100, 2) AS pct_presencia_web,
    ROUND((online_expandidos / NULLIF(total_expandidos, 0)) * 100, 2) AS pct_vende_online
FROM resumen_brecha
ORDER BY pct_acceso_internet ASC NULLS LAST;