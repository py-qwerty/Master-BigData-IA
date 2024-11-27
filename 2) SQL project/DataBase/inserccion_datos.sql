USE artevida_cultura;

-- Cargar datos en la tabla ASISTENTE
LOAD DATA LOCAL INFILE 'D:/Master/Primer_Cuatri/SQL project/DataBase/data/ASISTENTE_Table.csv'
INTO TABLE asistente
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(nombre, telefono, email);



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
