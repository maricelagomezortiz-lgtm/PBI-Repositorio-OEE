--SCRIPT DE ESTRUCTURA 

CREATE DATABASE EstampadoAutomotriz;
GO

-- CENTROS DE TRABAJO
CREATE TABLE centros_trabajo (
    id_centro INT PRIMARY KEY,
    nombre VARCHAR(50),
    tonelaje INT,
    costo_hora DECIMAL(10,2)
);

-- ARTICULOS

CREATE TABLE articulos (
    id_articulo INT PRIMARY KEY,
    nombre VARCHAR(100),
    tipo VARCHAR(50)
);

--RUTAS
CREATE TABLE rutas (
    id_ruta INT PRIMARY KEY,
    id_articulo INT
);

--OPERACIONES
CREATE TABLE operaciones (
    id_operacion INT PRIMARY KEY,
    id_ruta INT,
    id_centro INT,
    secuencia INT,
    piezas_hora DECIMAL(10,2),
    tiempo_std_pza DECIMAL(10,5)
);

--ORDENES DE PRODUCCION
CREATE TABLE ordenes_produccion (
    id_orden INT PRIMARY KEY,
    id_articulo INT,
    fecha DATE
);
--CAUSAS DE PIEZAS NO OK
CREATE TABLE causas_scrap (
    id_causa INT PRIMARY KEY,
    descripcion VARCHAR(50)
);

--CAUSAS DE TIEMPO MUERTO
CREATE TABLE causas_tiempo_muerto (
    id_causa INT PRIMARY KEY,
    descripcion VARCHAR(50)
);

-- HISTORICO
CREATE TABLE reporte_tiempos (
    id_reporte INT PRIMARY KEY,
    id_orden INT,
    id_operacion INT,
    id_centro INT,
    fecha DATE,
    cantidad_producida INT,
    tiempo_real_horas DECIMAL(10,2),
    tiempo_muerto_horas DECIMAL(10,2),
    causa_tiempo_muerto VARCHAR(50),
    tiempo_muerto DECIMAL(10,2),
    piezas_malas INT,
    causa_scrap VARCHAR(50)
);

--DATOS CENTROS DE TRABAJO

INSERT INTO centros_trabajo VALUES
(1,'Prensa 200T',200,80),
(2,'Prensa 300T',300,90),
(3,'Prensa 400T',400,100),
(4,'Prensa 500T',500,120),
(5,'Prensa 600T',600,140),
(6,'Prensa 800T',800,160),
(7,'Prensa 1000T',1000,180),
(8,'Prensa Transfer 1',1200,200),
(9,'Prensa Transfer 2',1500,220),
(10,'Prensa Alta Velocidad',250,110);


--DATOS ARTICULOS

DECLARE @i INT = 1;

WHILE @i <= 50
BEGIN
    INSERT INTO articulos VALUES (
        @i,
        CONCAT('Pieza Automotriz ', @i),
        CASE 
            WHEN @i % 3 = 0 THEN 'Refuerzo'
            WHEN @i % 3 = 1 THEN 'Panel'
            ELSE 'Estructural'
        END
    );
    SET @i += 1;
END;

--DATOS RUTAS

INSERT INTO rutas
SELECT id_articulo, id_articulo
FROM articulos;


--DATOS OPERACIONES DE RUTA 

-- CORTE
INSERT INTO operaciones
SELECT 
    id_articulo,
    id_articulo,
    (id_articulo % 10) + 1,
    1,
    20 + (id_articulo % 10),
    1.0 / (20 + (id_articulo % 10))
FROM articulos;

-- FORMADO
INSERT INTO operaciones
SELECT 
    1000 + id_articulo,
    id_articulo,
    ((id_articulo + 3) % 10) + 1,
    2,
    10 + (id_articulo % 8),
    1.0 / (10 + (id_articulo % 8))
FROM articulos;

-- ACABADO
INSERT INTO operaciones
SELECT 
    2000 + id_articulo,
    id_articulo,
    ((id_articulo + 5) % 10) + 1,
    3,
    15 + (id_articulo % 6),
    1.0 / (15 + (id_articulo % 6))
FROM articulos;

--DATOS ORDENES

DECLARE @fecha_inicio DATE = '2026-01-01';
DECLARE @orden INT = 1;

WHILE @orden <= 400
BEGIN
    INSERT INTO ordenes_produccion VALUES (
        @orden,
        ((@orden - 1) % 50) + 1,
        DATEADD(DAY, (@orden % 60), @fecha_inicio)
    );

    SET @orden += 1;
END;

--DATOS CAUSAS DE SCARP Y TIEMPO MUERTO
INSERT INTO causas_scrap VALUES
(1, 'Golpe'),
(2, 'Deformacion'),
(3, 'Rayado'),
(4, 'Falta de material'),
(5, 'Mal formado'),
(6, 'Fisura'),
(7, 'Error operador'),
(8, 'Herramental dañado');



INSERT INTO causas_tiempo_muerto VALUES
(1, 'Falla mecanica'),
(2, 'Falta de material'),
(3, 'Setup'),
(4, 'Cambio de herramental'),
(5, 'Mantenimiento'),
(6, 'Ajuste de proceso'),
(7, 'Falla electrica'),
(8, 'Paro no programado');


--DATOS HISTORICO - TABLA DE HECHOS -

INSERT INTO reporte_tiempos
(
    id_reporte,
    id_orden,
    id_operacion,
    id_centro,
    fecha,
    cantidad_producida,
    tiempo_real_horas,
    piezas_malas,
    causa_scrap,
    tiempo_muerto_horas,
    causa_tiempo_muerto
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY o.id_orden, op.id_operacion),
    o.id_orden,
    op.id_operacion,
    op.id_centro,
    o.fecha,

    -- PRODUCCIÓN
    prod.piezas,

    -- TIEMPO REAL (variación fuerte)
    prod.piezas * op.tiempo_std_pza *
    CASE 
        WHEN RAND(CHECKSUM(NEWID())) < 0.2 THEN 0.7 + RAND(CHECKSUM(NEWID())) * 0.2
        WHEN RAND(CHECKSUM(NEWID())) < 0.6 THEN 0.9 + RAND(CHECKSUM(NEWID())) * 0.3
        WHEN RAND(CHECKSUM(NEWID())) < 0.9 THEN 1.2 + RAND(CHECKSUM(NEWID())) * 0.6
        ELSE 1.8 + RAND(CHECKSUM(NEWID())) * 1.5
    END,

    -- SCRAP
    scrap.piezas_malas,

    CASE 
        WHEN scrap.piezas_malas = 0 THEN NULL
        ELSE 
            CASE scrap.id_causa
                WHEN 1 THEN 'Golpe'
                WHEN 2 THEN 'Deformacion'
                WHEN 3 THEN 'Rayado'
                WHEN 4 THEN 'Falta de material'
                WHEN 5 THEN 'Mal formado'
                WHEN 6 THEN 'Fisura'
                WHEN 7 THEN 'Error operador'
                WHEN 8 THEN 'Herramental dañado'
            END
    END,

    -- TIEMPO MUERTO (0 a 3 horas, con probabilidad)
    paro.tiempo_muerto,

    CASE 
        WHEN paro.tiempo_muerto = 0 THEN NULL
        ELSE 
            CASE paro.id_causa
                WHEN 1 THEN 'Falla mecanica'
                WHEN 2 THEN 'Falta de material'
                WHEN 3 THEN 'Setup'
                WHEN 4 THEN 'Cambio de herramental'
                WHEN 5 THEN 'Mantenimiento'
                WHEN 6 THEN 'Ajuste de proceso'
                WHEN 7 THEN 'Falla electrica'
                WHEN 8 THEN 'Paro no programado'
            END
    END

FROM ordenes_produccion o
JOIN operaciones op 
    ON o.id_articulo = op.id_ruta

-- PRODUCCIÓN
CROSS APPLY (
    SELECT 80 + (ABS(CHECKSUM(NEWID())) % 200) AS piezas
) prod

-- SCRAP
CROSS APPLY (
    SELECT 
        CAST(prod.piezas * (RAND(CHECKSUM(NEWID())) * 0.20) AS INT) AS piezas_malas,
        ABS(CHECKSUM(NEWID())) % 8 + 1 AS id_causa
) scrap

-- PAROS (30% probabilidad)
CROSS APPLY (
    SELECT 
        CASE 
            WHEN RAND(CHECKSUM(NEWID())) < 0.3 
                THEN RAND(CHECKSUM(NEWID())) * 3 
            ELSE 0 
        END AS tiempo_muerto,
        ABS(CHECKSUM(NEWID())) % 8 + 1 AS id_causa
) paro;
