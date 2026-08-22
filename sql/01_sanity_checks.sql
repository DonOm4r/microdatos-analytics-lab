-- ============================================================================
-- 01_sanity_checks.sql — DANE EMICRON 2023
-- FASE 3: validaciones de calidad sobre staging
--
-- Este archivo es de solo lectura: contiene únicamente consultas SELECT.
-- Resultado esperado:
--   1) Integridad referencial: 0 filas huérfanas.
--   2) fex_c agregado cercano a 5.188.402 micronegocios oficiales.
--   3) Ingresos negativos: 0 valores.
--   4) fex_c nulo o igual a cero: 0 registros.
-- ============================================================================


-- ============================================================================
-- 1. INTEGRIDAD REFERENCIAL
-- Todas las llaves de staging.ventas deben existir en staging.identificacion.
-- La consulta devuelve el detalle de las filas huérfanas; debe devolver 0 filas.
-- ============================================================================

SELECT
	v.directorio,
	v.secuencia_p,
	v.secuencia_encuesta
FROM staging.ventas AS v
LEFT JOIN staging.identificacion AS i
	ON  i.directorio = v.directorio
	AND i.secuencia_p = v.secuencia_p
	AND i.secuencia_encuesta = v.secuencia_encuesta
WHERE i.directorio IS NULL;


-- ============================================================================
-- 2. VALIDACIÓN DE POBLACIÓN EXPANDIDA
-- fex_c es el factor oficial para las agregaciones poblacionales.
-- La diferencia porcentual permite comparar el total calculado con la cifra
-- oficial de 5.188.402 micronegocios sin modificar los datos.
-- ============================================================================

WITH poblacion AS (
	SELECT
		SUM(fex_c) AS poblacion_expandida,
		CAST(5188402 AS NUMERIC(20, 10)) AS poblacion_oficial
	FROM staging.identificacion
)
SELECT
	poblacion_expandida,
	poblacion_oficial,
	poblacion_expandida - poblacion_oficial AS diferencia_absoluta,
	ROUND(
		100 * ABS(poblacion_expandida - poblacion_oficial)
		/ NULLIF(poblacion_oficial, 0),
		4
	) AS diferencia_porcentual,
	CASE
		WHEN poblacion_expandida IS NULL THEN 'SIN DATOS'
		WHEN ABS(poblacion_expandida - poblacion_oficial)
			 / NULLIF(poblacion_oficial, 0) < 0.05 THEN 'OK: diferencia menor al 5%'
		ELSE 'REVISAR: diferencia igual o mayor al 5%'
	END AS resultado
FROM poblacion;


-- ============================================================================
-- 3. RANGOS LÓGICOS: INGRESOS NEGATIVOS
-- Se revisan las variables monetarias del módulo de ventas. La consulta
-- devuelve el número de valores negativos y debe retornar 0.
-- ============================================================================

SELECT
	COUNT(*) AS total_valores_negativos
FROM staging.ventas AS v
CROSS JOIN LATERAL (
	VALUES
		('p3057', v.p3057),
		('p3058', v.p3058),
		('p3059', v.p3059),
		('p3060', v.p3060),
		('p3061', v.p3061),
		('p3062', v.p3062),
		('p4002', v.p4002),
		('p3063', v.p3063),
		('p3064', v.p3064),
		('p3065', v.p3065),
		('p3066', v.p3066),
		('p3067', v.p3067),
		('p3092', v.p3092),
		('p3093', v.p3093),
		('p4005', v.p4005),
		('p4006', v.p4006),
		('p4007', v.p4007),
		('p4008', v.p4008),
		('p4009', v.p4009),
		('p4010', v.p4010),
		('p4011', v.p4011),
		('p4012', v.p4012),
		('p4013', v.p4013),
		('p4014', v.p4014),
		('p4015', v.p4015),
		('p4016', v.p4016),
		('p4017', v.p4017),
		('p4018', v.p4018),
		('p4019', v.p4019),
		('p4020', v.p4020),
		('p4021', v.p4021),
		('p4022', v.p4022),
		('p4023', v.p4023),
		('p4024', v.p4024),
		('p4025', v.p4025),
		('p4026', v.p4026),
		('p4027', v.p4027),
		('p4028', v.p4028),
		('p4029', v.p4029),
		('p4030', v.p4030),
		('p4031', v.p4031),
		('p4032', v.p4032),
		('p4038', v.p4038),
		('p3072', v.p3072),
		('ventas_mes_anterior', v.ventas_mes_anterior),
		('ventas_mes_anio_anterior', v.ventas_mes_anio_anterior),
		('ventas_anio_anterior', v.ventas_anio_anterior),
		('valor_agregado', v.valor_agregado),
		('ingreso_mixto', v.ingreso_mixto)
) AS ingresos(nombre_variable, valor)
WHERE ingresos.valor < 0;


-- ============================================================================
-- 4. NULOS O CEROS EN EL FACTOR DE EXPANSIÓN
-- Todos los registros de identificación deben tener un fex_c positivo.
-- El resultado debe ser 0.
-- ============================================================================

SELECT
	COUNT(*) AS registros_fex_c_nulo_o_cero
FROM staging.identificacion
WHERE fex_c IS NULL
   OR fex_c = 0;
