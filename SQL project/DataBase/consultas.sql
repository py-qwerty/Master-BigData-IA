USE artevida_cultura;

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
