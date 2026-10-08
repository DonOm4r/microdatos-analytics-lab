-- ============================================================================
-- schema.sql — DANE EMICRON 2023 (PARTE 1: schemas + raw)
-- PASO 0 (solo primera vez, conectado a la BD 'postgres'):
-- CREATE DATABASE emicron_db;
-- Luego conectarse a 'emicron_db' y ejecutar este script.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;

-- ============================================================================
-- RAW — nombres en MAYÚSCULAS idénticos al CSV, todo TEXT (carga sin fricción)
-- ============================================================================

DROP TABLE IF EXISTS raw.identificacion CASCADE;
CREATE TABLE raw.identificacion (
    "DIRECTORIO" TEXT,
    "SECUENCIA_P" TEXT,
    "SECUENCIA_ENCUESTA" TEXT,
    "COD_DEPTO" TEXT,
    "AREA" TEXT,
    "CLASE_TE" TEXT,
    "P35" TEXT,
    "P241" TEXT,
    "MES_REF" TEXT,
    "P3031" TEXT,
    "P3032_1" TEXT,
    "P3032_2" TEXT,
    "P3032_3" TEXT,
    "P3033" TEXT,
    "P3034" TEXT,
    "P3035" TEXT,
    "P3000" TEXT,
    "GRUPOS4" TEXT,
    "GRUPOS12" TEXT,
    "F_EXP" TEXT,
    CONSTRAINT pk_raw_identificacion PRIMARY KEY ("DIRECTORIO", "SECUENCIA_P", "SECUENCIA_ENCUESTA")
);

DROP TABLE IF EXISTS raw.caracteristicas CASCADE;
CREATE TABLE raw.caracteristicas (
    "DIRECTORIO" TEXT,
    "SECUENCIA_P" TEXT,
    "SECUENCIA_ENCUESTA" TEXT,
    "P1633" TEXT,
    "P986" TEXT,
    "P640" TEXT,
    "P4000" TEXT,
    "P1055" TEXT,
    "P1056" TEXT,
    "P661" TEXT,
    "P1057" TEXT,
    "P4004" TEXT,
    "P2991" TEXT,
    "P2992" TEXT,
    "P2993" TEXT,
    "CLASE_TE" TEXT,
    "COD_DEPTO" TEXT,
    "AREA" TEXT,
    "F_EXP" TEXT,
    CONSTRAINT pk_raw_caracteristicas PRIMARY KEY ("DIRECTORIO", "SECUENCIA_P", "SECUENCIA_ENCUESTA")
);

DROP TABLE IF EXISTS raw.ubicacion CASCADE;
CREATE TABLE raw.ubicacion (
    "DIRECTORIO" TEXT,
    "SECUENCIA_P" TEXT,
    "SECUENCIA_ENCUESTA" TEXT,
    "P3053" TEXT,
    "P3095" TEXT,
    "P3096" TEXT,
    "P3097" TEXT,
    "P3098" TEXT,
    "P3054" TEXT,
    "P3055" TEXT,
    "P469" TEXT,
    "CLASE_TE" TEXT,
    "COD_DEPTO" TEXT,
    "AREA" TEXT,
    "F_EXP" TEXT,
    CONSTRAINT pk_raw_ubicacion PRIMARY KEY ("DIRECTORIO", "SECUENCIA_P", "SECUENCIA_ENCUESTA")
);

DROP TABLE IF EXISTS raw.ventas CASCADE;
CREATE TABLE raw.ventas (
    "DIRECTORIO" TEXT,
    "SECUENCIA_P" TEXT,
    "SECUENCIA_ENCUESTA" TEXT,
    "P3057" TEXT,
    "P3058" TEXT,
    "P3059" TEXT,
    "P3060" TEXT,
    "P3061" TEXT,
    "P3062" TEXT,
    "P4002" TEXT,
    "P3063" TEXT,
    "P3064" TEXT,
    "P3065" TEXT,
    "P3066" TEXT,
    "P3067" TEXT,
    "P3092" TEXT,
    "P3093" TEXT,
    "P4036" TEXT,
    "P4005" TEXT,
    "P4006" TEXT,
    "P4007" TEXT,
    "P4008" TEXT,
    "P4009" TEXT,
    "P4010" TEXT,
    "P4011" TEXT,
    "P4012" TEXT,
    "P4013" TEXT,
    "P4014" TEXT,
    "P4015" TEXT,
    "P4016" TEXT,
    "P4017" TEXT,
    "P4018" TEXT,
    "P4037" TEXT,
    "P3068_ENE" TEXT,
    "P3068_FEB" TEXT,
    "P3068_MAR" TEXT,
    "P3068_ABR" TEXT,
    "P3068_MAY" TEXT,
    "P3068_JUN" TEXT,
    "P3068_JUL" TEXT,
    "P3068_AGO" TEXT,
    "P3068_SEP" TEXT,
    "P3068_OCT" TEXT,
    "P3068_NOV" TEXT,
    "P3068_DIC" TEXT,
    "P3068_TOD" TEXT,
    "P3068_NIN" TEXT,
    "P4019" TEXT,
    "P4020" TEXT,
    "P4021" TEXT,
    "P4022" TEXT,
    "P4023" TEXT,
    "P4024" TEXT,
    "P4025" TEXT,
    "P4026" TEXT,
    "P4027" TEXT,
    "P4028" TEXT,
    "P4029" TEXT,
    "P4030" TEXT,
    "P4031" TEXT,
    "P4032" TEXT,
    "P4038" TEXT,
    "P3072" TEXT,
    "VENTAS_MES_ANTERIOR" TEXT,
    "VENTAS_MES_ANIO_ANTERIOR" TEXT,
    "VENTAS_ANIO_ANTERIOR" TEXT,
    "VALOR_AGREGADO" TEXT,
    "INGRESO_MIXTO" TEXT,
    "CLASE_TE" TEXT,
    "COD_DEPTO" TEXT,
    "AREA" TEXT,
    "F_EXP" TEXT,
    CONSTRAINT pk_raw_ventas PRIMARY KEY ("DIRECTORIO", "SECUENCIA_P", "SECUENCIA_ENCUESTA")
);

DROP TABLE IF EXISTS raw.factores_exp CASCADE;
CREATE TABLE raw.factores_exp (
    "DIRECTORIO" TEXT,
    "SECUENCIA_P" TEXT,
    "SECUENCIA_ENCUESTA" TEXT,
    "FEX_C" TEXT,
    CONSTRAINT pk_raw_factores_exp PRIMARY KEY ("DIRECTORIO", "SECUENCIA_P", "SECUENCIA_ENCUESTA")
);

-- ============================================================================
-- STAGING — snake_case, tipado exacto, fex_c replicado en todas las tablas
-- NUMERIC(15,2) dinero | NUMERIC(20,10) factores | VARCHAR códigos con
-- cero a la izquierda | INTEGER conteos/categóricas
-- ============================================================================

DROP TABLE IF EXISTS staging.identificacion CASCADE;
CREATE TABLE staging.identificacion (
    directorio          INTEGER NOT NULL,
    secuencia_p         INTEGER NOT NULL,
    secuencia_encuesta  INTEGER NOT NULL,
    cod_depto           VARCHAR(2),
    area                VARCHAR(2),
    clase_te            INTEGER,
    p35                 INTEGER,
    p241                INTEGER,
    mes_ref             VARCHAR(15),
    p3031               INTEGER,
    p3032_1             INTEGER,
    p3032_2             INTEGER,
    p3032_3             INTEGER,
    p3033               INTEGER,
    p3034               INTEGER,
    p3035               INTEGER,
    p3000               INTEGER,
    grupos4             VARCHAR(2),
    grupos12            VARCHAR(2),
    f_exp               NUMERIC(20,10),
    fex_c               NUMERIC(20,10),
    CONSTRAINT pk_identificacion PRIMARY KEY (directorio, secuencia_p, secuencia_encuesta)
);

COMMENT ON TABLE staging.identificacion IS 'Módulo de identificación: llaves, datos del propietario y clasificación CIIU';
COMMENT ON COLUMN staging.identificacion.directorio IS 'Directorio (identificador del hogar)';
COMMENT ON COLUMN staging.identificacion.secuencia_p IS 'Secuencia P (persona dentro del hogar)';
COMMENT ON COLUMN staging.identificacion.secuencia_encuesta IS 'Secuencia Encuesta (negocio de la persona)';
COMMENT ON COLUMN staging.identificacion.cod_depto IS 'Departamento (código DANE, preserva cero a la izquierda)';
COMMENT ON COLUMN staging.identificacion.area IS 'Ciudades principales y áreas metropolitanas';
COMMENT ON COLUMN staging.identificacion.clase_te IS 'Clase (cabecera / centros poblados y rural disperso)';
COMMENT ON COLUMN staging.identificacion.p35 IS 'Sexo del propietario del micronegocio';
COMMENT ON COLUMN staging.identificacion.p241 IS 'Edad del propietario del micronegocio';
COMMENT ON COLUMN staging.identificacion.mes_ref IS 'Mes de referencia';
COMMENT ON COLUMN staging.identificacion.p3031 IS 'En su actividad o negocio, ¿tiene personas que le ayudan?';
COMMENT ON COLUMN staging.identificacion.p3032_1 IS '¿Trabajadores(as) que reciben un pago?';
COMMENT ON COLUMN staging.identificacion.p3032_2 IS '¿Socios(as)?';
COMMENT ON COLUMN staging.identificacion.p3032_3 IS '¿Trabajadores(as) o familiares sin remuneración?';
COMMENT ON COLUMN staging.identificacion.p3033 IS 'En su negocio o actividad, usted es:';
COMMENT ON COLUMN staging.identificacion.p3034 IS '¿Cuántos meses lleva trabajando en su negocio o su actividad?';
COMMENT ON COLUMN staging.identificacion.p3035 IS 'El negocio ¿tiene nombre comercial?';
COMMENT ON COLUMN staging.identificacion.p3000 IS '¿Tiene correo electrónico?';
COMMENT ON COLUMN staging.identificacion.grupos4 IS 'Rama de actividad CIIU Rev. 4 agrupada en 4 grupos';
COMMENT ON COLUMN staging.identificacion.grupos12 IS 'Rama de actividad CIIU Rev. 4 agrupada en 12 grupos';
COMMENT ON COLUMN staging.identificacion.f_exp IS 'Factor de expansión del módulo (referencia, NO usar en agregaciones)';
COMMENT ON COLUMN staging.identificacion.fex_c IS 'Factor de expansión departamental oficial 2023 (usar en TODA agregación poblacional)';

DROP TABLE IF EXISTS staging.caracteristicas CASCADE;
CREATE TABLE staging.caracteristicas (
    directorio          INTEGER NOT NULL,
    secuencia_p         INTEGER NOT NULL,
    secuencia_encuesta  INTEGER NOT NULL,
    p1633               INTEGER,
    p986                INTEGER,
    p640                INTEGER,
    p4000               INTEGER,
    p1055               INTEGER,
    p1056               INTEGER,
    p661                INTEGER,
    p1057               INTEGER,
    p4004               INTEGER,
    p2991               INTEGER,
    p2992               INTEGER,
    p2993               INTEGER,
    clase_te            INTEGER,
    cod_depto           VARCHAR(2),
    area                VARCHAR(2),
    f_exp               NUMERIC(20,10),
    fex_c               NUMERIC(20,10),
    CONSTRAINT pk_caracteristicas PRIMARY KEY (directorio, secuencia_p, secuencia_encuesta)
);

COMMENT ON TABLE staging.caracteristicas IS 'Módulo de características: formalización, registros y declaraciones de impuestos';
COMMENT ON COLUMN staging.caracteristicas.directorio IS 'Directorio (identificador del hogar)';
COMMENT ON COLUMN staging.caracteristicas.secuencia_p IS 'Secuencia P (persona dentro del hogar)';
COMMENT ON COLUMN staging.caracteristicas.secuencia_encuesta IS 'Secuencia Encuesta (negocio de la persona)';
COMMENT ON COLUMN staging.caracteristicas.p1633 IS '¿El negocio o actividad tiene Registro Único Tributario (RUT)?';
COMMENT ON COLUMN staging.caracteristicas.p986 IS '¿A qué régimen pertenece?';
COMMENT ON COLUMN staging.caracteristicas.p640 IS '¿Cuál es el principal registro que utiliza para llevar sus cuentas?';
COMMENT ON COLUMN staging.caracteristicas.p4000 IS '¿Cuál es la razón principal por la cual no lleva algún tipo de registro?';
COMMENT ON COLUMN staging.caracteristicas.p1055 IS '¿El negocio o actividad se encuentra registrado en alguna Cámara de Comercio?';
COMMENT ON COLUMN staging.caracteristicas.p1056 IS '¿Cómo está registrado?';
COMMENT ON COLUMN staging.caracteristicas.p661 IS '¿Obtuvo o renovó ese registro este año?';
COMMENT ON COLUMN staging.caracteristicas.p1057 IS '¿Ha registrado el negocio ante alguna autoridad o entidad (alcaldía, ministerios u otros)?';
COMMENT ON COLUMN staging.caracteristicas.p4004 IS '¿Cuál autoridad o entidad?';
COMMENT ON COLUMN staging.caracteristicas.p2991 IS 'En el último año, ¿realizó declaración(es) de impuesto sobre la renta?';
COMMENT ON COLUMN staging.caracteristicas.p2992 IS 'En el último año, ¿realizó declaración(es) de IVA?';
COMMENT ON COLUMN staging.caracteristicas.p2993 IS 'En el último año, ¿realizó declaración(es) de ICA?';
COMMENT ON COLUMN staging.caracteristicas.clase_te IS 'Clase (cabecera / centros poblados y rural disperso)';
COMMENT ON COLUMN staging.caracteristicas.cod_depto IS 'Departamento (código DANE)';
COMMENT ON COLUMN staging.caracteristicas.area IS 'Ciudades principales y áreas metropolitanas';
COMMENT ON COLUMN staging.caracteristicas.f_exp IS 'Factor de expansión del módulo (referencia, NO usar en agregaciones)';
COMMENT ON COLUMN staging.caracteristicas.fex_c IS 'Factor de expansión departamental oficial 2023';

DROP TABLE IF EXISTS staging.ubicacion CASCADE;
CREATE TABLE staging.ubicacion (
    directorio          INTEGER NOT NULL,
    secuencia_p         INTEGER NOT NULL,
    secuencia_encuesta  INTEGER NOT NULL,
    p3053               INTEGER,
    p3095               INTEGER,
    p3096               INTEGER,
    p3097               INTEGER,
    p3098               INTEGER,
    p3054               INTEGER,
    p3055               INTEGER,
    p469                INTEGER,
    clase_te            INTEGER,
    cod_depto           VARCHAR(2),
    area                VARCHAR(2),
    f_exp               NUMERIC(20,10),
    fex_c               NUMERIC(20,10),
    CONSTRAINT pk_ubicacion PRIMARY KEY (directorio, secuencia_p, secuencia_encuesta)
);

COMMENT ON TABLE staging.ubicacion IS 'Módulo de sitio o ubicación: tipo de local, visibilidad y geografía';
COMMENT ON COLUMN staging.ubicacion.directorio IS 'Directorio (identificador del hogar)';
COMMENT ON COLUMN staging.ubicacion.secuencia_p IS 'Secuencia P (persona dentro del hogar)';
COMMENT ON COLUMN staging.ubicacion.secuencia_encuesta IS 'Secuencia Encuesta (negocio de la persona)';
COMMENT ON COLUMN staging.ubicacion.p3053 IS '¿El negocio o actividad se encuentra principalmente:';
COMMENT ON COLUMN staging.ubicacion.p3095 IS 'La vivienda ¿';
COMMENT ON COLUMN staging.ubicacion.p3096 IS 'Especifique cuál ¿';
COMMENT ON COLUMN staging.ubicacion.p3097 IS 'La actividad la desarrolla principalmente …';
COMMENT ON COLUMN staging.ubicacion.p3098 IS 'La actividad es ¿';
COMMENT ON COLUMN staging.ubicacion.p3054 IS '¿Cuántos puestos, establecimientos, oficinas, talleres, vehículos tiene el negocio?';
COMMENT ON COLUMN staging.ubicacion.p3055 IS 'El puesto, local, oficina o lugar donde desarrolla su negocio es:';
COMMENT ON COLUMN staging.ubicacion.p469 IS '¿El negocio o actividad económica es visible al público?';
COMMENT ON COLUMN staging.ubicacion.clase_te IS 'Clase (cabecera / centros poblados y rural disperso)';
COMMENT ON COLUMN staging.ubicacion.cod_depto IS 'Departamento (código DANE)';
COMMENT ON COLUMN staging.ubicacion.area IS 'Ciudades principales y áreas metropolitanas';
COMMENT ON COLUMN staging.ubicacion.f_exp IS 'Factor de expansión del módulo (referencia, NO usar en agregaciones)';
COMMENT ON COLUMN staging.ubicacion.fex_c IS 'Factor de expansión departamental oficial 2023';

DROP TABLE IF EXISTS staging.ventas CASCADE;
CREATE TABLE staging.ventas (
    directorio                  INTEGER NOT NULL,
    secuencia_p                 INTEGER NOT NULL,
    secuencia_encuesta          INTEGER NOT NULL,
    p3057                       NUMERIC(15,2),
    p3058                       NUMERIC(15,2),
    p3059                       NUMERIC(15,2),
    p3060                       NUMERIC(15,2),
    p3061                       NUMERIC(15,2),
    p3062                       NUMERIC(15,2),
    p4002                       NUMERIC(15,2),
    p3063                       NUMERIC(15,2),
    p3064                       NUMERIC(15,2),
    p3065                       NUMERIC(15,2),
    p3066                       NUMERIC(15,2),
    p3067                       NUMERIC(15,2),
    p3092                       NUMERIC(15,2),
    p3093                       NUMERIC(15,2),
    p4036                       NUMERIC(15,2),
    p4005                       NUMERIC(15,2),
    p4006                       NUMERIC(15,2),
    p4007                       NUMERIC(15,2),
    p4008                       NUMERIC(15,2),
    p4009                       NUMERIC(15,2),
    p4010                       NUMERIC(15,2),
    p4011                       NUMERIC(15,2),
    p4012                       NUMERIC(15,2),
    p4013                       NUMERIC(15,2),
    p4014                       NUMERIC(15,2),
    p4015                       NUMERIC(15,2),
    p4016                       NUMERIC(15,2),
    p4017                       NUMERIC(15,2),
    p4018                       NUMERIC(15,2),
    p4037                       NUMERIC(15,2),
    p3068_ene                   INTEGER,
    p3068_feb                   INTEGER,
    p3068_mar                   INTEGER,
    p3068_abr                   INTEGER,
    p3068_may                   INTEGER,
    p3068_jun                   INTEGER,
    p3068_jul                   INTEGER,
    p3068_ago                   INTEGER,
    p3068_sep                   INTEGER,
    p3068_oct                   INTEGER,
    p3068_nov                   INTEGER,
    p3068_dic                   INTEGER,
    p3068_tod                   INTEGER,
    p3068_nin                   INTEGER,
    p4019                       NUMERIC(15,2),
    p4020                       NUMERIC(15,2),
    p4021                       NUMERIC(15,2),
    p4022                       NUMERIC(15,2),
    p4023                       NUMERIC(15,2),
    p4024                       NUMERIC(15,2),
    p4025                       NUMERIC(15,2),
    p4026                       NUMERIC(15,2),
    p4027                       NUMERIC(15,2),
    p4028                       NUMERIC(15,2),
    p4029                       NUMERIC(15,2),
    p4030                       NUMERIC(15,2),
    p4031                       NUMERIC(15,2),
    p4032                       NUMERIC(15,2),
    p4038                       NUMERIC(15,2),
    p3072                       NUMERIC(15,2),
    ventas_mes_anterior         NUMERIC(15,2),
    ventas_mes_anio_anterior    NUMERIC(15,2),
    ventas_anio_anterior        NUMERIC(15,2),
    valor_agregado              NUMERIC(15,2),
    ingreso_mixto               NUMERIC(15,2),
    clase_te                    INTEGER,
    cod_depto                   VARCHAR(2),
    area                        VARCHAR(2),
    f_exp                       NUMERIC(20,10),
    fex_c                       NUMERIC(20,10),
    CONSTRAINT pk_ventas PRIMARY KEY (directorio, secuencia_p, secuencia_encuesta)
);

COMMENT ON TABLE staging.ventas IS 'Módulo de ventas o ingresos: ingresos por fuente, meses de operación y agregados económicos';
COMMENT ON COLUMN staging.ventas.directorio IS 'Directorio (identificador del hogar)';
COMMENT ON COLUMN staging.ventas.secuencia_p IS 'Secuencia P (persona dentro del hogar)';
COMMENT ON COLUMN staging.ventas.secuencia_encuesta IS 'Secuencia Encuesta (negocio de la persona)';
COMMENT ON COLUMN staging.ventas.p3057 IS 'Ventas de productos elaborados (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3058 IS 'Servicio de maquila (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3059 IS 'Servicios de reparación y mantenimiento (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3060 IS 'Otros ingresos (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3061 IS 'Venta de mercancía (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3062 IS 'Por consignación o comisión (mes anterior)';
COMMENT ON COLUMN staging.ventas.p4002 IS 'Servicios de reparación y mantenimiento (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3063 IS 'Otros ingresos (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3064 IS 'Ingresos por los servicios ofrecidos (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3065 IS 'Ingresos por mantenimiento y reparación (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3066 IS 'Por ventas de mercancías (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3067 IS 'Otros ingresos (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3092 IS 'Ingresos por venta de productos agrícolas, ganaderos, pesqueros o mineros (mes anterior)';
COMMENT ON COLUMN staging.ventas.p3093 IS 'Otros ingresos (mes anterior)';
COMMENT ON COLUMN staging.ventas.p4036 IS 'P4036 (variable de control del módulo)';
COMMENT ON COLUMN staging.ventas.p4005 IS 'Ventas de productos elaborados (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4006 IS 'Servicio de maquila (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4007 IS 'Servicios de reparación y mantenimiento (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4008 IS 'Otros ingresos (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4009 IS 'Venta de mercancía (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4010 IS 'Por consignación o comisión (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4011 IS 'Servicios de reparación y mantenimiento (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4012 IS 'Otros ingresos (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4013 IS 'Ingresos por los servicios ofrecidos (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4014 IS 'Ingresos por mantenimiento y reparación (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4015 IS 'Por ventas de mercancías (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4016 IS 'Otros ingresos (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4017 IS 'Ingresos por venta de productos agrícolas, ganaderos, pesqueros o mineros (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4018 IS 'Otros ingresos (mismo mes año anterior)';
COMMENT ON COLUMN staging.ventas.p4037 IS 'P4037 (variable de control del módulo)';
COMMENT ON COLUMN staging.ventas.p3068_ene IS 'Meses de funcionamiento año anterior: enero';
COMMENT ON COLUMN staging.ventas.p3068_feb IS 'Meses de funcionamiento año anterior: febrero';
COMMENT ON COLUMN staging.ventas.p3068_mar IS 'Meses de funcionamiento año anterior: marzo';
COMMENT ON COLUMN staging.ventas.p3068_abr IS 'Meses de funcionamiento año anterior: abril';
COMMENT ON COLUMN staging.ventas.p3068_may IS 'Meses de funcionamiento año anterior: mayo';
COMMENT ON COLUMN staging.ventas.p3068_jun IS 'Meses de funcionamiento año anterior: junio';
COMMENT ON COLUMN staging.ventas.p3068_jul IS 'Meses de funcionamiento año anterior: julio';
COMMENT ON COLUMN staging.ventas.p3068_ago IS 'Meses de funcionamiento año anterior: agosto';
COMMENT ON COLUMN staging.ventas.p3068_sep IS 'Meses de funcionamiento año anterior: septiembre';
COMMENT ON COLUMN staging.ventas.p3068_oct IS 'Meses de funcionamiento año anterior: octubre';
COMMENT ON COLUMN staging.ventas.p3068_nov IS 'Meses de funcionamiento año anterior: noviembre';
COMMENT ON COLUMN staging.ventas.p3068_dic IS 'Meses de funcionamiento año anterior: diciembre';
COMMENT ON COLUMN staging.ventas.p3068_tod IS 'Meses de funcionamiento año anterior: todos';
COMMENT ON COLUMN staging.ventas.p3068_nin IS 'Meses de funcionamiento año anterior: ninguno';
COMMENT ON COLUMN staging.ventas.p4019 IS 'Ventas de productos elaborados (año anterior)';
COMMENT ON COLUMN staging.ventas.p4020 IS 'Servicio de maquila (año anterior)';
COMMENT ON COLUMN staging.ventas.p4021 IS 'Servicios de reparación y mantenimiento (año anterior)';
COMMENT ON COLUMN staging.ventas.p4022 IS 'Otros ingresos (año anterior)';
COMMENT ON COLUMN staging.ventas.p4023 IS 'Venta de mercancía (año anterior)';
COMMENT ON COLUMN staging.ventas.p4024 IS 'Por consignación o comisión (año anterior)';
COMMENT ON COLUMN staging.ventas.p4025 IS 'Servicios de reparación y mantenimiento (año anterior)';
COMMENT ON COLUMN staging.ventas.p4026 IS 'Otros ingresos (año anterior)';
COMMENT ON COLUMN staging.ventas.p4027 IS 'Ingresos por los servicios ofrecidos (año anterior)';
COMMENT ON COLUMN staging.ventas.p4028 IS 'Ingresos por mantenimiento y reparación (año anterior)';
COMMENT ON COLUMN staging.ventas.p4029 IS 'Por ventas de mercancías (año anterior)';
COMMENT ON COLUMN staging.ventas.p4030 IS 'Otros ingresos (año anterior)';
COMMENT ON COLUMN staging.ventas.p4031 IS 'Ingresos por venta de productos agrícolas, ganaderos, pesqueros o mineros (año anterior)';
COMMENT ON COLUMN staging.ventas.p4032 IS 'Otros ingresos (año anterior)';
COMMENT ON COLUMN staging.ventas.p4038 IS 'Ventas o ingresos totales (año anterior)';
COMMENT ON COLUMN staging.ventas.p3072 IS 'En promedio ¿cuánto le deja su negocio o actividad al mes?';
COMMENT ON COLUMN staging.ventas.ventas_mes_anterior IS 'Ventas o ingresos mensuales (calculada DANE)';
COMMENT ON COLUMN staging.ventas.ventas_mes_anio_anterior IS 'Ventas o ingresos del mismo mes del año anterior (calculada DANE)';
COMMENT ON COLUMN staging.ventas.ventas_anio_anterior IS 'Ventas o ingresos del año anterior (calculada DANE)';
COMMENT ON COLUMN staging.ventas.valor_agregado IS 'Valor agregado mensual (calculada DANE)';
COMMENT ON COLUMN staging.ventas.ingreso_mixto IS 'Ingreso mixto mensual (calculada DANE)';
COMMENT ON COLUMN staging.ventas.clase_te IS 'Clase (cabecera / centros poblados y rural disperso)';
COMMENT ON COLUMN staging.ventas.cod_depto IS 'Departamento (código DANE)';
COMMENT ON COLUMN staging.ventas.area IS 'Ciudades principales y áreas metropolitanas';
COMMENT ON COLUMN staging.ventas.f_exp IS 'Factor de expansión del módulo (referencia, NO usar en agregaciones)';
COMMENT ON COLUMN staging.ventas.fex_c IS 'Factor de expansión departamental oficial 2023';

DROP TABLE IF EXISTS staging.factores_exp CASCADE;
CREATE TABLE staging.factores_exp (
    directorio          INTEGER NOT NULL,
    secuencia_p         INTEGER NOT NULL,
    secuencia_encuesta  INTEGER NOT NULL,
    fex_c               NUMERIC(20,10),
    CONSTRAINT pk_factores_exp PRIMARY KEY (directorio, secuencia_p, secuencia_encuesta)
);

COMMENT ON TABLE staging.factores_exp IS 'Factores de expansión departamentales 2023 (fuente oficial de fex_c)';
COMMENT ON COLUMN staging.factores_exp.directorio IS 'Directorio (identificador del hogar)';
COMMENT ON COLUMN staging.factores_exp.secuencia_p IS 'Secuencia P (persona dentro del hogar)';
COMMENT ON COLUMN staging.factores_exp.secuencia_encuesta IS 'Secuencia Encuesta (negocio de la persona)';
COMMENT ON COLUMN staging.factores_exp.fex_c IS 'Factor de expansión departamental oficial 2023 (usar en TODA agregación poblacional)';

-- ============================================================================
-- ÍNDICES — aceleran filtros y joins frecuentes en las queries de negocio
-- (cod_depto/grupos4/grupos12 para cruces geográficos y sectoriales;
--  fex_c para agregaciones ponderadas)
-- ============================================================================

CREATE INDEX idx_identificacion_depto   ON staging.identificacion (cod_depto);
CREATE INDEX idx_identificacion_grupos4  ON staging.identificacion (grupos4);
CREATE INDEX idx_identificacion_grupos12 ON staging.identificacion (grupos12);
CREATE INDEX idx_identificacion_fexc     ON staging.identificacion (fex_c);

CREATE INDEX idx_caracteristicas_depto   ON staging.caracteristicas (cod_depto);
CREATE INDEX idx_caracteristicas_fexc    ON staging.caracteristicas (fex_c);

CREATE INDEX idx_ubicacion_depto         ON staging.ubicacion (cod_depto);
CREATE INDEX idx_ubicacion_fexc          ON staging.ubicacion (fex_c);

CREATE INDEX idx_ventas_depto            ON staging.ventas (cod_depto);
CREATE INDEX idx_ventas_fexc             ON staging.ventas (fex_c);

CREATE INDEX idx_factores_exp_fexc       ON staging.factores_exp (fex_c);

-- ============================================================================
-- PKs en RAW — definidas inline en cada CREATE TABLE; garantizan unicidad de
-- la llave compuesta desde la carga. NOTA: si algún CSV trae duplicados de
-- llave, el INSERT fallará aquí y no en staging (fail-fast en la bodega
-- inmutable, donde debe detectarse).
-- ============================================================================

-- ============================================================================
-- TIC — módulo diferenciador de Omar
-- ============================================================================

DROP TABLE IF EXISTS raw.tic CASCADE;
CREATE TABLE raw.tic (
    "DIRECTORIO" TEXT,
    "SECUENCIA_P" TEXT,
    "SECUENCIA_ENCUESTA" TEXT,
    "P4001" TEXT,
    "P1087" TEXT,
    "P1088" TEXT,
    "P977" TEXT,
    "P976" TEXT,
    "P978" TEXT,
    "P979" TEXT,
    "P994" TEXT,
    "P2532" TEXT,
    "P1559" TEXT,
    "P2524" TEXT,
    "P1093" TEXT,
    "P2528" TEXT,
    "P1095" TEXT,
    "P980" TEXT,
    "P1006_1" TEXT,
    "P1006_2" TEXT,
    "P1006_3" TEXT,
    "P1006_4" TEXT,
    "P1006_5" TEXT,
    "P1006_6" TEXT,
    "P1006_7" TEXT,
    "P1006_8" TEXT,
    "P1006_9" TEXT,
    "P1006_10" TEXT,
    "P1006_11" TEXT,
    "P1006_12" TEXT,
    "P1006_13" TEXT,
    "CLASE_TE" TEXT,
    "COD_DEPTO" TEXT,
    "AREA" TEXT,
    "F_EXP" TEXT,
    CONSTRAINT pk_raw_tic
        PRIMARY KEY ("DIRECTORIO", "SECUENCIA_P", "SECUENCIA_ENCUESTA")
);

DROP TABLE IF EXISTS staging.tic CASCADE;
CREATE TABLE staging.tic (
    directorio          INTEGER NOT NULL,
    secuencia_p         INTEGER NOT NULL,
    secuencia_encuesta  INTEGER NOT NULL,
    p4001               INTEGER,
    p1087               INTEGER,
    p1088               INTEGER,
    p977                INTEGER,
    p976                INTEGER,
    p978                INTEGER,
    p979                INTEGER,
    p994                INTEGER,
    p2532               INTEGER,
    p1559               INTEGER,
    p2524               INTEGER,
    p1093               INTEGER,
    p2528               INTEGER,
    p1095               INTEGER,
    p980                INTEGER,
    p1006_1             INTEGER,
    p1006_2             INTEGER,
    p1006_3             INTEGER,
    p1006_4             INTEGER,
    p1006_5             INTEGER,
    p1006_6             INTEGER,
    p1006_7             INTEGER,
    p1006_8             INTEGER,
    p1006_9             INTEGER,
    p1006_10            INTEGER,
    p1006_11            INTEGER,
    p1006_12            INTEGER,
    p1006_13            INTEGER,
    clase_te            INTEGER,
    cod_depto           VARCHAR(2),
    area                VARCHAR(2),
    f_exp               NUMERIC(20,10),
    fex_c               NUMERIC(20,10),
    CONSTRAINT pk_tic
        PRIMARY KEY (directorio, secuencia_p, secuencia_encuesta)
);

COMMENT ON TABLE staging.tic IS 'Módulo de TIC: dispositivos, internet y usos digitales del micronegocio';
COMMENT ON COLUMN staging.tic.directorio IS 'Directorio';
COMMENT ON COLUMN staging.tic.secuencia_p IS 'Secuencia P';
COMMENT ON COLUMN staging.tic.secuencia_encuesta IS 'Secuencia Encuesta';
COMMENT ON COLUMN staging.tic.p4001 IS '¿Para su negocio o actividad utiliza alguno(a) de los siguientes dispositivos electrónicos?';
COMMENT ON COLUMN staging.tic.p1087 IS '¿Cuántos computadores de escritorio tiene en uso el negocio o actividad?';
COMMENT ON COLUMN staging.tic.p1088 IS '¿Cuántos computadores portátiles tiene en uso el negocio o actividad?';
COMMENT ON COLUMN staging.tic.p977 IS '¿Cuántas tabletas tiene en uso el negocio o actividad?';
COMMENT ON COLUMN staging.tic.p976 IS '¿Para su negocio o actividad utiliza el teléfono celular?';
COMMENT ON COLUMN staging.tic.p978 IS '¿Cuántos teléfonos celulares inteligentes (Smartphone) tiene en uso el negocio o actividad?';
COMMENT ON COLUMN staging.tic.p979 IS '¿Cuántos teléfonos celular convencional tiene en uso el negocio o actividad?';
COMMENT ON COLUMN staging.tic.p994 IS '¿Cuál es la principal razón por la cual el negocio o actividad no tiene en uso computador, tableta o Smartphone?';
COMMENT ON COLUMN staging.tic.p2532 IS '¿El negocio o actividad tiene página web o presencia en un sitio web?';
COMMENT ON COLUMN staging.tic.p1559 IS '¿El negocio o actividad tiene presencia en redes sociales?';
COMMENT ON COLUMN staging.tic.p2524 IS '¿Este negocio o actividad tiene acceso o utiliza el servicio de internet?';
COMMENT ON COLUMN staging.tic.p1093 IS '¿Utiliza internet con conexión dentro del negocio o donde desarrolla su actividad?';
COMMENT ON COLUMN staging.tic.p2528 IS '¿Qué tipo de conexión utiliza principalmente el negocio para acceder a internet?';
COMMENT ON COLUMN staging.tic.p1095 IS '¿Cuál es la principal razón por la cual el negocio o actividad no utiliza internet?';
COMMENT ON COLUMN staging.tic.p980 IS '¿Cuántas personas ocupadas utilizan internet para el desarrollo de sus actividades?';
COMMENT ON COLUMN staging.tic.p1006_1 IS 'Búsqueda de información de dependencias oficiales y autoridades';
COMMENT ON COLUMN staging.tic.p1006_2 IS 'Banca electrónica y otros servicios financieros';
COMMENT ON COLUMN staging.tic.p1006_3 IS 'Transacciones con organismos gubernamentales';
COMMENT ON COLUMN staging.tic.p1006_4 IS 'Servicio al cliente';
COMMENT ON COLUMN staging.tic.p1006_5 IS 'Entrega de productos en forma digitalizada';
COMMENT ON COLUMN staging.tic.p1006_6 IS 'Comprar a proveedores por internet mediante una plataforma electrónica';
COMMENT ON COLUMN staging.tic.p1006_7 IS 'Vender productos a clientes por internet mediante una plataforma electrónica';
COMMENT ON COLUMN staging.tic.p1006_8 IS 'Uso de aplicaciones';
COMMENT ON COLUMN staging.tic.p1006_9 IS 'Enviar o recibir correo electrónico';
COMMENT ON COLUMN staging.tic.p1006_10 IS 'Búsqueda de información sobre bienes y servicios';
COMMENT ON COLUMN staging.tic.p1006_11 IS 'Llamadas telefónicas por internet o videoconferencias';
COMMENT ON COLUMN staging.tic.p1006_12 IS 'Capacitación del personal';
COMMENT ON COLUMN staging.tic.p1006_13 IS 'Mensajería instantánea o chat';
COMMENT ON COLUMN staging.tic.clase_te IS 'Clase';
COMMENT ON COLUMN staging.tic.cod_depto IS 'Departamento';
COMMENT ON COLUMN staging.tic.area IS 'Ciudades principales y áreas metropolitanas';
COMMENT ON COLUMN staging.tic.f_exp IS 'Factor de expansión';
COMMENT ON COLUMN staging.tic.fex_c IS 'Factor de expansión departamental oficial 2023';

CREATE INDEX idx_tic_depto ON staging.tic (cod_depto);
CREATE INDEX idx_tic_area ON staging.tic (area);
CREATE INDEX idx_tic_fexc ON staging.tic (fex_c);
