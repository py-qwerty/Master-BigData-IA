-- Borrado de la base de dato por si ya estubiese creada
DROP DATABASE IF EXISTS artevida_cultura;

-- Creación de la base de datos
CREATE DATABASE artevida_cultura;

-- Uso de la base de datos
USE artevida_cultura;

-- ------------------ Creación de las tablas --------------


-- Tabla ASISTENTE
CREATE TABLE ASISTENTE (
    id_asistente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(100),
    email VARCHAR(100)
);

-- Tabla UBICACION
CREATE TABLE UBICACION (
    id_ubicacion INT AUTO_INCREMENT PRIMARY KEY,
    aforo INT NOT NULL CHECK (aforo >= 1),
    direccion VARCHAR(255),
    ciudad_pueblo VARCHAR(100),
    precio_alquiler DECIMAL(10,2),
    caracteristicas TEXT
);

-- Tabla ACTIVIDAD
CREATE TABLE ACTIVIDAD (
    id_actividad INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(255),
    fecha_hora DATETIME NOT NULL
);

-- Tabla ARTISTA
CREATE TABLE ARTISTA (
    id_artista INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    biografia TEXT,
    cache DECIMAL(10,2) CHECK (cache > 0)
);

-- Tabla EVENTO
CREATE TABLE EVENTO (
    id_evento INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_hora DATETIME NOT NULL,
    precio DECIMAL(10,2),
    id_ubicacion INT,
    id_actividad INT,
    estado_aforo BOOLEAN,
    FOREIGN KEY (id_ubicacion) REFERENCES UBICACION(id_ubicacion)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (id_actividad) REFERENCES ACTIVIDAD(id_actividad)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Tabla ASISTE (Relación N-M entre ASISTENTE y EVENTO)
CREATE TABLE ASISTE (
    id_evento INT,
    id_asistente INT,
    PRIMARY KEY (id_evento, id_asistente),
    FOREIGN KEY (id_evento) REFERENCES EVENTO(id_evento)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (id_asistente) REFERENCES ASISTENTE(id_asistente)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Tabla ACTUA (Relación N-M entre ACTIVIDAD y ARTISTA)
CREATE TABLE ACTUA (
    id_actividad INT,
    id_artista INT,
    cache DECIMAL(10,2) CHECK (cache > 0),
    PRIMARY KEY (id_actividad, id_artista),
    FOREIGN KEY (id_actividad) REFERENCES ACTIVIDAD(id_actividad)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (id_artista) REFERENCES ARTISTA(id_artista)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Trigger 1: Validación del Aforo en UBICACION antes de insertar en ASISTE
DELIMITER $$

CREATE TRIGGER before_asiste_insert
BEFORE INSERT ON ASISTE
FOR EACH ROW
BEGIN
    DECLARE total_asistentes INT;
    DECLARE max_aforo INT;

    -- Obtener el aforo máximo de la ubicación asociada al evento
    SELECT U.aforo INTO max_aforo
    FROM UBICACION U
    JOIN EVENTO E ON U.id_ubicacion = E.id_ubicacion
    WHERE E.id_evento = NEW.id_evento;

    -- Contar el número actual de asistentes al evento
    SELECT COUNT(*) INTO total_asistentes
    FROM ASISTE
    WHERE id_evento = NEW.id_evento;

    -- Verificar si el aforo se excedería con la nueva inserción
    IF (total_asistentes + 1) > max_aforo THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Aforo completo. No se puede agregar más asistentes.';
    ELSE
        -- Actualizar el estado_aforo en el evento
        IF (total_asistentes + 1) = max_aforo THEN
            UPDATE EVENTO
            SET estado_aforo = 1
            WHERE id_evento = NEW.id_evento;
        ELSE
            UPDATE EVENTO
            SET estado_aforo = 0
            WHERE id_evento = NEW.id_evento;
        END IF;
    END IF;
END$$

DELIMITER ;

-- Trigger 2: Validación del Aforo en UBICACION antes de eliminar de ASISTE
DELIMITER $$

CREATE TRIGGER before_asiste_delete
BEFORE DELETE ON ASISTE
FOR EACH ROW
BEGIN
    DECLARE total_asistentes INT;
    DECLARE max_aforo INT;

    -- Obtener el aforo máximo de la ubicación asociada al evento
    SELECT U.aforo INTO max_aforo
    FROM UBICACION U
    JOIN EVENTO E ON U.id_ubicacion = E.id_ubicacion
    WHERE E.id_evento = OLD.id_evento;

    -- Contar el número actual de asistentes al evento después de la eliminación
    SELECT COUNT(*) INTO total_asistentes
    FROM ASISTE
    WHERE id_evento = OLD.id_evento;

    -- Actualizar el estado_aforo en el evento
    IF total_asistentes < max_aforo THEN
        UPDATE EVENTO
        SET estado_aforo = 0
        WHERE id_evento = OLD.id_evento;
    END IF;
END$$

DELIMITER ;

-- Trigger 3: Validación del Formato de Correo y Teléfono en ASISTENTE antes de insertar
DELIMITER $$

CREATE TRIGGER before_asistente_insert
BEFORE INSERT ON ASISTENTE
FOR EACH ROW
BEGIN
	-- Validar el formato del email
	IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}$' THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Formato de email inválido.';
	END IF;


    -- Validar el formato del teléfono
    IF NEW.telefono NOT REGEXP '^\\+?[0-9]{9,15}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Formato de teléfono inválido.';
    END IF;
END$$

DELIMITER ;

-- Trigger 4: Validación de Fechas en EVENTO antes de insertar
DELIMITER $$

CREATE TRIGGER before_evento_insert
BEFORE INSERT ON EVENTO
FOR EACH ROW
BEGIN
    DECLARE fecha_actividad DATETIME;

    -- Obtener la fecha de la actividad asociada
    SELECT fecha_hora INTO fecha_actividad
    FROM ACTIVIDAD
    WHERE id_actividad = NEW.id_actividad;

    -- Verificar que la fecha y hora del evento no sea anterior a la fecha de la actividad
    IF NEW.fecha_hora < fecha_actividad THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'La fecha y hora del evento no puede ser anterior a la fecha de la actividad asociada.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER before_evento_update
BEFORE UPDATE ON EVENTO
FOR EACH ROW
BEGIN
    DECLARE fecha_actividad DATETIME;

    -- Verificar si el evento tiene una actividad asociada
    IF NEW.id_actividad IS NOT NULL THEN
        -- Obtener la fecha de la actividad asociada
        SELECT fecha_hora INTO fecha_actividad
        FROM ACTIVIDAD
        WHERE id_actividad = NEW.id_actividad;

        -- Verificar que la fecha y hora del evento no sea anterior a la fecha de la actividad
        IF NEW.fecha_hora < fecha_actividad THEN
            SIGNAL SQLSTATE '45000' 
                SET MESSAGE_TEXT = 'La fecha y hora del evento no puede ser anterior a la fecha de la actividad asociada.';
        END IF;
    END IF;
END$$

DELIMITER ;


USE artevida_cultura;

-- Cargar datos en la tabla ASISTENTE
LOAD DATA LOCAL INFILE 'D:/Master/Primer_Cuatri/SQL project/DataBase/data/ASISTENTE_Table.csv'
INTO TABLE asistente
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(nombre, telefono, email);

-- ------------------ Insercción de datos desde arhcivos .csv --------------


-- Cargar datos en la tabla UBICACION
LOAD DATA LOCAL INFILE 'D:/Master/Primer_Cuatri/SQL project/DataBase/data/UBICACION_Table.csv'
INTO TABLE UBICACION
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_ubicacion, aforo, direccion, ciudad_pueblo, precio_alquiler, caracteristicas);

-- Cargar datos en la tabla ACTIVIDAD
LOAD DATA LOCAL INFILE 'D:/Master/Primer_Cuatri/SQL project/DataBase/data/ACTIVIDAD_Table.csv'
INTO TABLE ACTIVIDAD
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_actividad, nombre, direccion, fecha_hora);

-- Cargar datos en la tabla ARTISTA
LOAD DATA LOCAL INFILE 'D:/Master/Primer_Cuatri/SQL project/DataBase/data/ARTISTA_Table.csv'
INTO TABLE ARTISTA
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_artista, nombre, biografia, cache);

-- Cargar datos en la tabla EVENTO
LOAD DATA LOCAL INFILE 'D:/Master/Primer_Cuatri/SQL project/DataBase/data/EVENTO_Table.csv'
INTO TABLE EVENTO
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_evento, nombre, descripcion, fecha_hora, precio, id_ubicacion, id_actividad, estado_aforo);

-- Cargar datos en la tabla ASISTE
LOAD DATA LOCAL INFILE 'D:/Master/Primer_Cuatri/SQL project/DataBase/data/ASISTE_Table.csv'
INTO TABLE ASISTE
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_evento, id_asistente);

-- Cargar datos en la tabla ACTUA
LOAD DATA LOCAL INFILE 'D:/Master/Primer_Cuatri/SQL project/DataBase/data/ACTUA_Table.csv'
INTO TABLE ACTUA
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id_actividad, id_artista, cache);


-- ------------------Consultas y vistas --------------

-- 1. Consulta de eventos con asistentes al límite del aforo
SELECT 
    evento.nombre AS evento,
    COUNT(asiste.id_asistente) AS total_asistentes,
    ubicacion.aforo AS aforo_maximo
FROM evento
JOIN asiste ON evento.id_evento = asiste.id_evento
JOIN ubicacion ON evento.id_ubicacion = ubicacion.id_ubicacion
GROUP BY evento.id_evento, ubicacion.aforo
HAVING COUNT(asiste.id_asistente) = ubicacion.aforo;

-- 2. Actividades con artistas y sus caches totales
SELECT 
    actividad.nombre AS actividad,
    artista.nombre AS artista,
    SUM(actua.cache) AS cache_total
FROM actividad
JOIN actua ON actividad.id_actividad = actua.id_actividad
JOIN artista ON actua.id_artista = artista.id_artista
GROUP BY actividad.id_actividad, artista.id_artista
ORDER BY cache_total DESC;

-- 3. Total de asistentes por evento y su ubicación
SELECT 
    ubicacion.id_ubicacion AS id_ubicacion,
    evento.nombre AS evento,
    COUNT(asiste.id_asistente) AS total_asistentes
FROM ubicacion
JOIN evento ON ubicacion.id_ubicacion = evento.id_ubicacion
JOIN asiste ON evento.id_evento = asiste.id_evento
GROUP BY ubicacion.id_ubicacion, evento.id_evento;

-- 4. Eventos con ingresos totales por entradas
SELECT 
    evento.nombre AS evento,
    COUNT(asiste.id_asistente) * evento.precio AS ingresos_totales
FROM evento
JOIN asiste ON evento.id_evento = asiste.id_evento
GROUP BY evento.id_evento
ORDER BY ingresos_totales DESC;

-- 5. Promedio del caché por artista
SELECT 
    artista.nombre AS artista,
    AVG(actua.cache) AS promedio_cache
FROM artista
JOIN actua ON artista.id_artista = actua.id_artista
GROUP BY artista.id_artista
ORDER BY promedio_cache DESC;

-- 6. Eventos sin asistentes
SELECT 
    evento.nombre AS evento,
    evento.fecha_hora AS fecha_evento
FROM evento
LEFT JOIN asiste ON evento.id_evento = asiste.id_evento
WHERE asiste.id_asistente IS NULL;

-- 7. Artistas con más de 3 actividades
SELECT 
    artista.nombre AS artista,
    COUNT(DISTINCT actua.id_actividad) AS total_actividades
FROM artista
JOIN actua ON artista.id_artista = actua.id_artista
GROUP BY artista.id_artista
HAVING COUNT(DISTINCT actua.id_actividad) > 3;

-- 8. Actividades y el total de asistentes a sus eventos relacionados
SELECT 
    actividad.nombre AS actividad,
    COUNT(asiste.id_asistente) AS total_asistentes
FROM actividad
JOIN evento ON actividad.id_actividad = evento.id_actividad
JOIN asiste ON evento.id_evento = asiste.id_evento
GROUP BY actividad.id_actividad
ORDER BY total_asistentes DESC;

-- 9. Ubicaciones con más eventos realizados
SELECT 
    ubicacion.direccion AS direccion,
    COUNT(evento.id_evento) AS total_eventos
FROM ubicacion
JOIN evento ON ubicacion.id_ubicacion = evento.id_ubicacion
GROUP BY ubicacion.direccion
ORDER BY total_eventos DESC;

	-- 10. Asistentes que han participado en más de un evento
	SELECT 
		asistente.nombre AS asistente,
		COUNT(DISTINCT asiste.id_evento) AS total_eventos
	FROM asistente
	JOIN asiste ON asistente.id_asistente = asiste.id_asistente
	GROUP BY asistente.id_asistente
	HAVING COUNT(DISTINCT asiste.id_evento) > 1
	ORDER BY total_eventos DESC;
    
    
    -- Creación de la vista de ganancias o perdidas
    
    CREATE VIEW evento_balance_anual AS
SELECT 
    YEAR(evento.fecha_hora) AS anio,
    evento.nombre AS evento,
    ubicacion.precio_alquiler AS costo_ubicacion,
    IFNULL(SUM(actua.cache), 0) AS costo_total_artistas,
    IFNULL(COUNT(asiste.id_asistente) * evento.precio, 0) AS ingresos_totales,
    (IFNULL(COUNT(asiste.id_asistente) * evento.precio, 0) - 
     (ubicacion.precio_alquiler + IFNULL(SUM(actua.cache), 0))) AS balance
FROM evento
LEFT JOIN ubicacion ON evento.id_ubicacion = ubicacion.id_ubicacion
LEFT JOIN actua ON evento.id_actividad = actua.id_actividad
LEFT JOIN asiste ON evento.id_evento = asiste.id_evento
GROUP BY anio, evento.id_evento, ubicacion.precio_alquiler
ORDER BY anio, balance DESC;

SELECT * FROM evento_balance_anual;
