-- Borrado de la base de dato por si ya estubiese creada
DROP DATABASE IF EXISTS artevida_cultura;

-- Creación de la base de datos
CREATE DATABASE artevida_cultura;

-- Uso de la base de datos
USE artevida_cultura;

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
