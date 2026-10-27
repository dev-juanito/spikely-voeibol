USE spikely_volley;


-- =====================================================================
-- 1. ROLES Y PERMISOS
-- =====================================================================

CREATE TABLE rol (
    rol_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE permiso (
    permiso_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE rol_permiso (
    rol_id INT NOT NULL,
    permiso_id INT NOT NULL,
    PRIMARY KEY (rol_id, permiso_id),
    CONSTRAINT fk_rol_permiso_rol
        FOREIGN KEY (rol_id) REFERENCES rol(rol_id),
    CONSTRAINT fk_rol_permiso_permiso
        FOREIGN KEY (permiso_id) REFERENCES permiso(permiso_id)
) ENGINE=InnoDB;


-- =====================================================================
-- 2. USUARIO Y ESPECIALIZACIONES
-- =====================================================================

CREATE TABLE usuario (
    usuario_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,      -- guardar siempre el HASH (RNF01)
    foto VARCHAR(255),                     -- RF04: perfil con fotografía
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado BOOLEAN DEFAULT TRUE,
    rol_id INT NOT NULL,
    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (rol_id) REFERENCES rol(rol_id)
) ENGINE=InnoDB;

CREATE TABLE administrador (
    usuario_id INT PRIMARY KEY,
    CONSTRAINT fk_administrador_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE organizador (
    usuario_id INT PRIMARY KEY,
    CONSTRAINT fk_organizador_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE entrenador (
    usuario_id INT PRIMARY KEY,
    CONSTRAINT fk_entrenador_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE arbitro (
    usuario_id INT PRIMARY KEY,
    CONSTRAINT fk_arbitro_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- RF03: recuperación de contraseña mediante enlace por correo
CREATE TABLE recuperacion_contrasena (
    recuperacion_id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    fecha_expiracion DATETIME NOT NULL,
    usado BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_recuperacion_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- =====================================================================
-- 3. TORNEO, EQUIPO, JUGADOR, INSCRIPCION
-- =====================================================================

CREATE TABLE torneo (
    torneo_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    ubicacion VARCHAR(200),
    reglamento TEXT,
    estado VARCHAR(30) NOT NULL DEFAULT 'Programado',
    organizador_id INT NOT NULL,
    CONSTRAINT fk_torneo_organizador
        FOREIGN KEY (organizador_id) REFERENCES organizador(usuario_id),
    CONSTRAINT chk_torneo_fechas
        CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT chk_torneo_estado
        CHECK (estado IN ('Programado', 'En curso', 'Finalizado', 'Cancelado'))
) ENGINE=InnoDB;

CREATE TABLE equipo (
    equipo_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    descripcion TEXT,
    entrenador_id INT NOT NULL,
    CONSTRAINT fk_equipo_entrenador
        FOREIGN KEY (entrenador_id) REFERENCES entrenador(usuario_id)
) ENGINE=InnoDB;

CREATE TABLE jugador (
    jugador_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,              -- la edad se calcula, no se guarda
    genero VARCHAR(30),
    posicion VARCHAR(50),
    numero_camiseta INT,
    equipo_id INT NOT NULL,
    usuario_id INT NULL UNIQUE,         -- opcional: cuenta de usuario del jugador
    CONSTRAINT fk_jugador_equipo
        FOREIGN KEY (equipo_id) REFERENCES equipo(equipo_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_jugador_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id)
        ON DELETE SET NULL,
    CONSTRAINT uq_jugador_camiseta
        UNIQUE (equipo_id, numero_camiseta),
    CONSTRAINT chk_jugador_camiseta
        CHECK (numero_camiseta IS NULL OR numero_camiseta BETWEEN 0 AND 99)
) ENGINE=InnoDB;

-- Tabla intermedia de la relación muchos a muchos equipo <-> torneo
CREATE TABLE inscripcion (
    inscripcion_id INT AUTO_INCREMENT PRIMARY KEY,
    fecha_inscripcion DATE NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'Pendiente',
    torneo_id INT NOT NULL,
    equipo_id INT NOT NULL,
    CONSTRAINT fk_inscripcion_torneo
        FOREIGN KEY (torneo_id) REFERENCES torneo(torneo_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_inscripcion_equipo
        FOREIGN KEY (equipo_id) REFERENCES equipo(equipo_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_inscripcion UNIQUE (torneo_id, equipo_id),
    CONSTRAINT chk_inscripcion_estado
        CHECK (estado IN ('Pendiente', 'Aprobada', 'Rechazada'))
) ENGINE=InnoDB;


-- =====================================================================
-- 4. PARTIDO, RESULTADO, SETS, ESTADISTICA
-- =====================================================================

CREATE TABLE partido (
    partido_id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATETIME NOT NULL,
    cancha VARCHAR(100),
    estado VARCHAR(30) NOT NULL DEFAULT 'Programado',
    equipo_local_id INT NOT NULL,
    equipo_visitante_id INT NOT NULL,
    arbitro_id INT,
    torneo_id INT NOT NULL,
    CONSTRAINT fk_partido_equipo_local
        FOREIGN KEY (equipo_local_id) REFERENCES equipo(equipo_id),
    CONSTRAINT fk_partido_equipo_visitante
        FOREIGN KEY (equipo_visitante_id) REFERENCES equipo(equipo_id),
    CONSTRAINT fk_partido_arbitro
        FOREIGN KEY (arbitro_id) REFERENCES arbitro(usuario_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_partido_torneo
        FOREIGN KEY (torneo_id) REFERENCES torneo(torneo_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_partido_equipos
        CHECK (equipo_local_id <> equipo_visitante_id),
    CONSTRAINT chk_partido_estado
        CHECK (estado IN ('Programado', 'En curso', 'Finalizado', 'Suspendido', 'Cancelado'))
) ENGINE=InnoDB;

-- Un partido genera un único resultado. El ganador y los sets ganados
-- NO se guardan aquí: se calculan desde set_partido.
CREATE TABLE resultado (
    resultado_id INT AUTO_INCREMENT PRIMARY KEY,
    partido_id INT NOT NULL UNIQUE,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    CONSTRAINT fk_resultado_partido
        FOREIGN KEY (partido_id) REFERENCES partido(partido_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Un resultado tiene de 1 a 5 sets (reemplaza las columnas set1..set5)
CREATE TABLE set_partido (
    resultado_id INT NOT NULL,
    numero_set TINYINT NOT NULL,
    puntos_local INT NOT NULL,
    puntos_visitante INT NOT NULL,
    PRIMARY KEY (resultado_id, numero_set),
    CONSTRAINT fk_set_resultado
        FOREIGN KEY (resultado_id) REFERENCES resultado(resultado_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_set_numero
        CHECK (numero_set BETWEEN 1 AND 5),
    CONSTRAINT chk_set_puntos
        CHECK (puntos_local >= 0 AND puntos_visitante >= 0
               AND puntos_local <> puntos_visitante)
) ENGINE=InnoDB;

CREATE TABLE estadistica (
    estadistica_id INT AUTO_INCREMENT PRIMARY KEY,
    partido_id INT NOT NULL,
    jugador_id INT NOT NULL,
    puntos INT DEFAULT 0,
    saques INT DEFAULT 0,
    bloqueos INT DEFAULT 0,
    ataques INT DEFAULT 0,
    recepciones INT DEFAULT 0,
    errores INT DEFAULT 0,
    CONSTRAINT fk_estadistica_partido
        FOREIGN KEY (partido_id) REFERENCES partido(partido_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_estadistica_jugador
        FOREIGN KEY (jugador_id) REFERENCES jugador(jugador_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_estadistica UNIQUE (partido_id, jugador_id),
    CONSTRAINT chk_estadistica_valores
        CHECK (puntos >= 0 AND saques >= 0 AND bloqueos >= 0
               AND ataques >= 0 AND recepciones >= 0 AND errores >= 0)
) ENGINE=InnoDB;


-- =====================================================================
-- 5. NOTIFICACION, NOTICIA, HISTORIAL, REPORTE
-- =====================================================================

CREATE TABLE notificacion (
    notificacion_id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    mensaje TEXT NOT NULL,
    tipo VARCHAR(50),
    fecha_envio DATETIME DEFAULT CURRENT_TIMESTAMP,
    leida BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_notificacion_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE noticia (
    noticia_id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    contenido TEXT NOT NULL,
    fecha_publicacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    imagen VARCHAR(255),
    organizador_id INT NOT NULL,
    CONSTRAINT fk_noticia_organizador
        FOREIGN KEY (organizador_id) REFERENCES organizador(usuario_id)
) ENGINE=InnoDB;

CREATE TABLE historial_torneo (
    historial_id INT AUTO_INCREMENT PRIMARY KEY,
    torneo_id INT NOT NULL UNIQUE,
    fecha_cierre DATETIME DEFAULT CURRENT_TIMESTAMP,
    resumen TEXT,
    campeon_id INT NULL,
    CONSTRAINT fk_historial_torneo
        FOREIGN KEY (torneo_id) REFERENCES torneo(torneo_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_historial_campeon
        FOREIGN KEY (campeon_id) REFERENCES equipo(equipo_id)
        ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE reporte (
    reporte_id INT AUTO_INCREMENT PRIMARY KEY,
    administrador_id INT NOT NULL,
    tipo VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_generacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reporte_administrador
        FOREIGN KEY (administrador_id) REFERENCES administrador(usuario_id)
) ENGINE=InnoDB;


-- =====================================================================
-- 6. ÍNDICES PARA CONSULTAS FRECUENTES
-- =====================================================================

CREATE INDEX idx_partido_fecha              ON partido (fecha);
CREATE INDEX idx_notificacion_usuario_leida ON notificacion (usuario_id, leida);
CREATE INDEX idx_noticia_fecha              ON noticia (fecha_publicacion);
