USE spikely_volley;

-- =====================================================================
-- 1. VISTA: resultado de cada partido (sets ganados y ganador)
--    Un partido tiene ganador cuando un equipo llega a 3 sets.
-- =====================================================================

CREATE OR REPLACE VIEW v_resultado_partido AS
SELECT
    r.resultado_id,
    r.partido_id,
    p.torneo_id,
    p.equipo_local_id,
    p.equipo_visitante_id,
    SUM(s.puntos_local > s.puntos_visitante)  AS sets_local,
    SUM(s.puntos_visitante > s.puntos_local)  AS sets_visitante,
    CASE WHEN SUM(s.puntos_local > s.puntos_visitante) >= 3     THEN 'Local'
         WHEN SUM(s.puntos_visitante > s.puntos_local) >= 3     THEN 'Visitante'
         ELSE NULL END                                          AS ganador,
    CASE WHEN SUM(s.puntos_local > s.puntos_visitante) >= 3     THEN p.equipo_local_id
         WHEN SUM(s.puntos_visitante > s.puntos_local) >= 3     THEN p.equipo_visitante_id
         ELSE NULL END                                          AS equipo_ganador_id
FROM resultado r
JOIN partido p     ON p.partido_id   = r.partido_id
JOIN set_partido s ON s.resultado_id = r.resultado_id
GROUP BY r.resultado_id, r.partido_id, p.torneo_id,
         p.equipo_local_id, p.equipo_visitante_id;


-- =====================================================================
-- 2. VISTA: tabla de posiciones (RF10)
--    Puntos: victoria 3-0 o 3-1 = 3, victoria 3-2 = 2,
--            derrota 2-3 = 1, derrota 1-3 o 0-3 = 0.
--    Consulta sugerida:
--      SELECT * FROM v_tabla_posiciones WHERE torneo_id = 1
--      ORDER BY puntos DESC, (sets_favor - sets_contra) DESC;
-- =====================================================================

CREATE OR REPLACE VIEW v_tabla_posiciones AS
SELECT
    i.torneo_id,
    i.equipo_id,
    e.nombre                                   AS equipo,
    COUNT(t.gano)                              AS partidos_jugados,
    COALESCE(SUM(t.gano), 0)                   AS partidos_ganados,
    COUNT(t.gano) - COALESCE(SUM(t.gano), 0)   AS partidos_perdidos,
    COALESCE(SUM(t.sets_favor), 0)             AS sets_favor,
    COALESCE(SUM(t.sets_contra), 0)            AS sets_contra,
    COALESCE(SUM(CASE WHEN t.gano = 1 AND t.sets_contra <= 1 THEN 3
                      WHEN t.gano = 1                        THEN 2
                      WHEN t.sets_favor = 2                  THEN 1
                      ELSE 0 END), 0)          AS puntos
FROM inscripcion i
JOIN equipo e ON e.equipo_id = i.equipo_id
LEFT JOIN (
    SELECT torneo_id, equipo_local_id AS equipo_id,
           sets_local AS sets_favor, sets_visitante AS sets_contra,
           (ganador = 'Local') AS gano
    FROM v_resultado_partido
    WHERE ganador IS NOT NULL
    UNION ALL
    SELECT torneo_id, equipo_visitante_id,
           sets_visitante, sets_local,
           (ganador = 'Visitante')
    FROM v_resultado_partido
    WHERE ganador IS NOT NULL
) t ON t.torneo_id = i.torneo_id AND t.equipo_id = i.equipo_id
WHERE i.estado = 'Aprobada'
GROUP BY i.torneo_id, i.equipo_id, e.nombre;


-- =====================================================================
-- 3. VISTA: estadísticas grupales por equipo y torneo (RF11)
-- =====================================================================

CREATE OR REPLACE VIEW v_estadisticas_equipo AS
SELECT
    p.torneo_id,
    j.equipo_id,
    e.nombre            AS equipo,
    SUM(es.puntos)      AS puntos,
    SUM(es.saques)      AS saques,
    SUM(es.bloqueos)    AS bloqueos,
    SUM(es.ataques)     AS ataques,
    SUM(es.recepciones) AS recepciones,
    SUM(es.errores)     AS errores
FROM estadistica es
JOIN jugador j ON j.jugador_id = es.jugador_id
JOIN equipo e  ON e.equipo_id  = j.equipo_id
JOIN partido p ON p.partido_id = es.partido_id
GROUP BY p.torneo_id, j.equipo_id, e.nombre;


-- =====================================================================
-- 4. TRIGGERS DE INTEGRIDAD
--    (En Workbench el DELIMITER funciona normal dentro del script.)
-- =====================================================================

DELIMITER $$

-- 4.1 RF06: los dos equipos de un partido deben tener inscripción
--     aprobada en el torneo del partido.
DROP TRIGGER IF EXISTS trg_partido_bi$$
CREATE TRIGGER trg_partido_bi BEFORE INSERT ON partido
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM inscripcion
        WHERE torneo_id = NEW.torneo_id
          AND estado = 'Aprobada'
          AND equipo_id IN (NEW.equipo_local_id, NEW.equipo_visitante_id)) < 2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ambos equipos deben tener inscripcion aprobada en el torneo';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_partido_bu$$
CREATE TRIGGER trg_partido_bu BEFORE UPDATE ON partido
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM inscripcion
        WHERE torneo_id = NEW.torneo_id
          AND estado = 'Aprobada'
          AND equipo_id IN (NEW.equipo_local_id, NEW.equipo_visitante_id)) < 2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ambos equipos deben tener inscripcion aprobada en el torneo';
    END IF;
END$$

-- 4.2 "Un usuario posee un único rol": solo entra a la tabla de su rol.
DROP TRIGGER IF EXISTS trg_administrador_bi$$
CREATE TRIGGER trg_administrador_bi BEFORE INSERT ON administrador
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario u JOIN rol r ON r.rol_id = u.rol_id
                   WHERE u.usuario_id = NEW.usuario_id AND r.nombre = 'Administrador') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene el rol Administrador';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_organizador_bi$$
CREATE TRIGGER trg_organizador_bi BEFORE INSERT ON organizador
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario u JOIN rol r ON r.rol_id = u.rol_id
                   WHERE u.usuario_id = NEW.usuario_id AND r.nombre = 'Organizador') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene el rol Organizador';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_entrenador_bi$$
CREATE TRIGGER trg_entrenador_bi BEFORE INSERT ON entrenador
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario u JOIN rol r ON r.rol_id = u.rol_id
                   WHERE u.usuario_id = NEW.usuario_id AND r.nombre = 'Entrenador') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene el rol Entrenador';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_arbitro_bi$$
CREATE TRIGGER trg_arbitro_bi BEFORE INSERT ON arbitro
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario u JOIN rol r ON r.rol_id = u.rol_id
                   WHERE u.usuario_id = NEW.usuario_id AND r.nombre = 'Arbitro') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene el rol Arbitro';
    END IF;
END$$

DELIMITER ;


-- =====================================================================
-- 5. VERIFICACIÓN
-- =====================================================================

SHOW TABLES;

-- Debe dar: Halcones 3 pts, Titanes 2 pts, Tormenta 1 pt, Águilas 0 pts.
SELECT equipo, partidos_jugados AS pj, partidos_ganados AS pg,
       partidos_perdidos AS pp, sets_favor AS sf, sets_contra AS sc, puntos
FROM v_tabla_posiciones
WHERE torneo_id = 1
ORDER BY puntos DESC, (sets_favor - sets_contra) DESC;

SELECT * FROM v_resultado_partido;
