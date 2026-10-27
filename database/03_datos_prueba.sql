USE spikely_volley;

-- =====================================================================
-- A. DATOS INICIALES (necesarios para que el sistema funcione)
-- =====================================================================

INSERT INTO rol (nombre, descripcion) VALUES
('Administrador', 'Administra el sistema, usuarios, roles y reportes'),
('Organizador',   'Gestiona los torneos, partidos y noticias'),
('Entrenador',    'Gestiona sus equipos y jugadores'),
('Arbitro',       'Controla los partidos y registra resultados'),
('Jugador',       'Consulta su equipo, estadísticas y tabla de posiciones');

INSERT INTO permiso (nombre, descripcion) VALUES
('gestionar_usuarios',     'Crear, consultar, modificar y eliminar usuarios'),     -- 1
('gestionar_roles',        'Administrar roles y asignar permisos'),                -- 2
('gestionar_arbitros',     'Administrar árbitros y asignarlos a partidos'),        -- 3
('generar_reportes',       'Generar y consultar reportes administrativos'),        -- 4
('gestionar_torneos',      'Crear, modificar y eliminar torneos'),                 -- 5
('gestionar_partidos',     'Programar y administrar partidos'),                    -- 6
('publicar_noticias',      'Crear, modificar y eliminar noticias'),                -- 7
('gestionar_equipos',      'Crear, modificar y eliminar equipos'),                 -- 8
('gestionar_jugadores',    'Crear, modificar y eliminar jugadores'),               -- 9
('inscribir_equipos',      'Inscribir equipos en torneos'),                        -- 10
('registrar_resultados',   'Registrar y actualizar resultados de partidos'),       -- 11
('ver_estadisticas',       'Consultar estadísticas de equipos y jugadores'),       -- 12
('ver_tabla_posiciones',   'Consultar la tabla de posiciones'),                    -- 13
('editar_perfil',          'Consultar y actualizar el perfil propio');             -- 14

-- Administrador (rol 1): todos los permisos
INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT 1, permiso_id FROM permiso;

-- Organizador (rol 2)
INSERT INTO rol_permiso (rol_id, permiso_id) VALUES
(2,5),(2,6),(2,7),(2,12),(2,13),(2,14);

-- Entrenador (rol 3)
INSERT INTO rol_permiso (rol_id, permiso_id) VALUES
(3,8),(3,9),(3,10),(3,12),(3,13),(3,14);

-- Arbitro (rol 4)
INSERT INTO rol_permiso (rol_id, permiso_id) VALUES
(4,11),(4,12),(4,13),(4,14);

-- Jugador (rol 5)
INSERT INTO rol_permiso (rol_id, permiso_id) VALUES
(5,12),(5,13),(5,14);


-- =====================================================================
-- B. DATOS DE PRUEBA (se pueden borrar)
-- Las contraseñas son un HASH ficticio: NO sirven para iniciar sesión.
-- =====================================================================

INSERT INTO usuario (nombre, correo, contrasena, rol_id) VALUES
('Admin Spikely',      'admin@spikely.test',       '$2b$10$HASH_DE_EJEMPLO_ADMIN',  1),  -- 1
('Marta Organizadora', 'organizador@spikely.test', '$2b$10$HASH_DE_EJEMPLO_ORG',    2),  -- 2
('Carlos Rojas',       'carlos@spikely.test',      '$2b$10$HASH_DE_EJEMPLO_CARLOS', 3),  -- 3
('Laura Pérez',        'laura@spikely.test',       '$2b$10$HASH_DE_EJEMPLO_LAURA',  3),  -- 4
('Andrés Gómez',       'andres@spikely.test',      '$2b$10$HASH_DE_EJEMPLO_ANDRES', 4),  -- 5
('Sofía Martínez',     'sofia@spikely.test',       '$2b$10$HASH_DE_EJEMPLO_SOFIA',  4);  -- 6

INSERT INTO administrador (usuario_id) VALUES (1);
INSERT INTO organizador   (usuario_id) VALUES (2);
INSERT INTO entrenador    (usuario_id) VALUES (3),(4);
INSERT INTO arbitro       (usuario_id) VALUES (5),(6);

INSERT INTO torneo (nombre, descripcion, fecha_inicio, fecha_fin, ubicacion, reglamento, estado, organizador_id) VALUES
('Copa Spikely 2026', 'Torneo amateur de voleibol de Bogotá',
 '2026-10-01', '2026-11-15', 'Coliseo El Salitre, Bogotá',
 'Partidos al mejor de 5 sets; los 4 primeros sets a 25 puntos y el quinto a 15.',
 'En curso', 2);

INSERT INTO equipo (nombre, categoria, descripcion, entrenador_id) VALUES
('Halcones', 'Masculino', 'Equipo de la zona norte',     3),  -- 1
('Titanes',  'Masculino', 'Equipo de la zona centro',    3),  -- 2
('Águilas',  'Femenino',  'Equipo de la zona sur',       4),  -- 3
('Tormenta', 'Femenino',  'Equipo de la zona occidente', 4);  -- 4

INSERT INTO jugador (nombre, fecha_nacimiento, genero, posicion, numero_camiseta, equipo_id) VALUES
('Juan Torres',    '2000-03-14', 'Masculino', 'Colocador',   1, 1),  -- 1
('Pedro Ruiz',     '1999-07-02', 'Masculino', 'Central',     5, 1),  -- 2
('Luis Mora',      '2001-11-20', 'Masculino', 'Opuesto',     9, 1),  -- 3
('Camilo Díaz',    '2000-01-08', 'Masculino', 'Colocador',   2, 2),  -- 4
('Felipe Cruz',    '1998-09-25', 'Masculino', 'Libero',      7, 2),  -- 5
('Mateo Vargas',   '2002-05-30', 'Masculino', 'Central',    10, 2),  -- 6
('Valentina Ríos', '2001-02-17', 'Femenino',  'Colocadora',  3, 3),  -- 7
('Daniela Soto',   '2000-12-05', 'Femenino',  'Opuesta',     8, 3),  -- 8
('Natalia Peña',   '1999-06-19', 'Femenino',  'Central',    11, 3),  -- 9
('Isabela León',   '2002-08-11', 'Femenino',  'Libero',      4, 4),  -- 10
('Camila Ortiz',   '2001-04-23', 'Femenino',  'Opuesta',     6, 4),  -- 11
('Paula Herrera',  '2000-10-09', 'Femenino',  'Colocadora', 12, 4);  -- 12

INSERT INTO inscripcion (fecha_inscripcion, estado, torneo_id, equipo_id) VALUES
('2026-09-15', 'Aprobada', 1, 1),
('2026-09-16', 'Aprobada', 1, 2),
('2026-09-17', 'Aprobada', 1, 3),
('2026-09-18', 'Aprobada', 1, 4);

INSERT INTO partido (fecha, cancha, estado, equipo_local_id, equipo_visitante_id, arbitro_id, torneo_id) VALUES
('2026-10-03 15:00:00', 'Cancha 1', 'Finalizado', 1, 3, 5, 1),  -- 1: Halcones vs Águilas
('2026-10-03 17:00:00', 'Cancha 2', 'Finalizado', 2, 4, 6, 1),  -- 2: Titanes vs Tormenta
('2026-10-29 15:00:00', 'Cancha 1', 'Programado', 1, 2, 5, 1);  -- 3: Halcones vs Titanes

INSERT INTO resultado (partido_id, observaciones) VALUES
(1, NULL),                                    -- resultado 1
(2, 'Definido en el quinto set');             -- resultado 2

-- Sets del resultado 1: Halcones 3 - 0 Águilas
-- Sets del resultado 2: Titanes 3 - 2 Tormenta
INSERT INTO set_partido (resultado_id, numero_set, puntos_local, puntos_visitante) VALUES
(1, 1, 25, 20),
(1, 2, 25, 22),
(1, 3, 25, 18),
(2, 1, 25, 22),
(2, 2, 20, 25),
(2, 3, 25, 23),
(2, 4, 22, 25),
(2, 5, 15, 10);

INSERT INTO estadistica (partido_id, jugador_id, puntos, saques, bloqueos, ataques, recepciones, errores) VALUES
(1, 1,  8, 3, 1,  4,  6, 2),
(1, 2, 12, 1, 4,  7,  2, 1),
(1, 3, 15, 2, 0, 13,  3, 3),
(1, 7,  6, 1, 0,  5,  8, 4),
(1, 8, 10, 2, 1,  7,  4, 5),
(1, 9,  7, 0, 3,  4,  1, 2),
(2, 4,  9, 2, 0,  5,  7, 3),
(2, 6, 14, 1, 5,  8,  2, 2),
(2, 10, 5, 0, 0,  2, 12, 1),
(2, 11,13, 3, 1,  9,  3, 4);

INSERT INTO notificacion (usuario_id, titulo, mensaje, tipo) VALUES
(3, 'Nuevo partido programado', 'Halcones vs Titanes el 29 de octubre a las 3:00 p. m.', 'Partido'),
(4, 'Resultado registrado',     'Se registró el resultado de Halcones vs Águilas.',       'Resultado'),
(5, 'Partido asignado',         'Fuiste asignado como árbitro del partido #3.',           'Asignacion');

INSERT INTO noticia (titulo, contenido, organizador_id) VALUES
('¡Arranca la Copa Spikely 2026!',   'Cuatro equipos competirán hasta mediados de noviembre en el Coliseo El Salitre.', 2),
('Resultados de la primera jornada', 'Halcones y Titanes ganaron sus partidos de la fecha 1.', 2);

INSERT INTO reporte (administrador_id, tipo, descripcion) VALUES
(1, 'Resumen de torneo', 'Reporte de inscripciones y partidos de la Copa Spikely 2026.');

-- historial_torneo se llena cuando un torneo termina (el torneo 1 sigue en curso).
