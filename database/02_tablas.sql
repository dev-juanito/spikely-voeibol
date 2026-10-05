-- =====================================================
-- ROLES
-- =====================================================

CREATE TABLE rol (
    rol_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
) ENGINE=InnoDB;


-- =====================================================
-- PERMISOS
-- =====================================================

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
        FOREIGN KEY (rol_id)
        REFERENCES rol(rol_id),

    CONSTRAINT fk_rol_permiso_permiso
        FOREIGN KEY (permiso_id)
        REFERENCES permiso(permiso_id)
) ENGINE=InnoDB;


-- =====================================================
-- USUARIO
-- =====================================================

CREATE TABLE usuario (
    usuario_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado BOOLEAN DEFAULT TRUE,
    rol_id INT NOT NULL,

    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (rol_id)
        REFERENCES rol(rol_id)
) ENGINE=InnoDB;


-- =====================================================
-- ESPECIALIZACIONES
-- =====================================================

CREATE TABLE administrador (
    usuario_id INT PRIMARY KEY,

    CONSTRAINT fk_administrador_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE organizador (
    usuario_id INT PRIMARY KEY,

    CONSTRAINT fk_organizador_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE entrenador (
    usuario_id INT PRIMARY KEY,

    CONSTRAINT fk_entrenador_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE arbitro (
    usuario_id INT PRIMARY KEY,

    CONSTRAINT fk_arbitro_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- =====================================================
-- TORNEO
-- =====================================================

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
        FOREIGN KEY (organizador_id)
        REFERENCES organizador(usuario_id)
) ENGINE=InnoDB;


-- =====================================================
-- EQUIPO
-- =====================================================

CREATE TABLE equipo (
    equipo_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    descripcion TEXT,
    entrenador_id INT NOT NULL,

    CONSTRAINT fk_equipo_entrenador
        FOREIGN KEY (entrenador_id)
        REFERENCES entrenador(usuario_id)
) ENGINE=InnoDB;


-- =====================================================
-- JUGADOR
-- =====================================================

CREATE TABLE jugador (
    jugador_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    genero VARCHAR(30),
    posicion VARCHAR(50),
    numero_camiseta INT,
    equipo_id INT NOT NULL,

    CONSTRAINT fk_jugador_equipo
        FOREIGN KEY (equipo_id)
        REFERENCES equipo(equipo_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- =====================================================
-- INSCRIPCION
-- =====================================================

CREATE TABLE inscripcion (
    inscripcion_id INT AUTO_INCREMENT PRIMARY KEY,
    fecha_inscripcion DATE NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'Pendiente',
    torneo_id INT NOT NULL,
    equipo_id INT NOT NULL,

    CONSTRAINT fk_inscripcion_torneo
        FOREIGN KEY (torneo_id)
        REFERENCES torneo(torneo_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_inscripcion_equipo
        FOREIGN KEY (equipo_id)
        REFERENCES equipo(equipo_id)
        ON DELETE CASCADE,

    UNIQUE (torneo_id, equipo_id)
) ENGINE=InnoDB;


-- =====================================================
-- PARTIDO
-- =====================================================

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
        FOREIGN KEY (equipo_local_id)
        REFERENCES equipo(equipo_id),

    CONSTRAINT fk_partido_equipo_visitante
        FOREIGN KEY (equipo_visitante_id)
        REFERENCES equipo(equipo_id),

    CONSTRAINT fk_partido_arbitro
        FOREIGN KEY (arbitro_id)
        REFERENCES arbitro(usuario_id)
        ON DELETE SET NULL,

    CONSTRAINT fk_partido_torneo
        FOREIGN KEY (torneo_id)
        REFERENCES torneo(torneo_id)
        ON DELETE CASCADE,

    CHECK (equipo_local_id <> equipo_visitante_id)
) ENGINE=InnoDB;


-- =====================================================
-- RESULTADO
-- =====================================================

CREATE TABLE resultado (
    resultado_id INT AUTO_INCREMENT PRIMARY KEY,

    partido_id INT NOT NULL UNIQUE,

    set1_local INT,
    set1_visitante INT,

    set2_local INT,
    set2_visitante INT,

    set3_local INT,
    set3_visitante INT,

    ganador VARCHAR(20),

    CONSTRAINT fk_resultado_partido
        FOREIGN KEY (partido_id)
        REFERENCES partido(partido_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- =====================================================
-- ESTADISTICA
-- =====================================================

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
        FOREIGN KEY (partido_id)
        REFERENCES partido(partido_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_estadistica_jugador
        FOREIGN KEY (jugador_id)
        REFERENCES jugador(jugador_id)
        ON DELETE CASCADE,

    UNIQUE (partido_id, jugador_id)
) ENGINE=InnoDB;


-- =====================================================
-- TABLA DE POSICIONES
-- =====================================================

CREATE TABLE tabla_posiciones (
    posicion_id INT AUTO_INCREMENT PRIMARY KEY,

    torneo_id INT NOT NULL,
    equipo_id INT NOT NULL,

    partidos_jugados INT DEFAULT 0,
    partidos_ganados INT DEFAULT 0,
    partidos_perdidos INT DEFAULT 0,

    sets_favor INT DEFAULT 0,
    sets_contra INT DEFAULT 0,

    puntos INT DEFAULT 0,

    CONSTRAINT fk_posiciones_torneo
        FOREIGN KEY (torneo_id)
        REFERENCES torneo(torneo_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_posiciones_equipo
        FOREIGN KEY (equipo_id)
        REFERENCES equipo(equipo_id)
        ON DELETE CASCADE,

    UNIQUE (torneo_id, equipo_id)
) ENGINE=InnoDB;


-- =====================================================
-- NOTIFICACION
-- =====================================================

CREATE TABLE notificacion (
    notificacion_id INT AUTO_INCREMENT PRIMARY KEY,

    usuario_id INT NOT NULL,

    titulo VARCHAR(150) NOT NULL,
    mensaje TEXT NOT NULL,
    tipo VARCHAR(50),
    fecha_envio DATETIME DEFAULT CURRENT_TIMESTAMP,
    leida BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_notificacion_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(usuario_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- =====================================================
-- NOTICIA
-- =====================================================

CREATE TABLE noticia (
    noticia_id INT AUTO_INCREMENT PRIMARY KEY,

    titulo VARCHAR(200) NOT NULL,
    contenido TEXT NOT NULL,
    fecha_publicacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    imagen VARCHAR(255),

    organizador_id INT NOT NULL,

    CONSTRAINT fk_noticia_organizador
        FOREIGN KEY (organizador_id)
        REFERENCES organizador(usuario_id)
) ENGINE=InnoDB;


-- =====================================================
-- HISTORIAL DE TORNEOS
-- =====================================================

CREATE TABLE historial_torneo (
    historial_id INT AUTO_INCREMENT PRIMARY KEY,

    torneo_id INT NOT NULL UNIQUE,
    fecha_cierre DATETIME DEFAULT CURRENT_TIMESTAMP,
    resumen TEXT,

    CONSTRAINT fk_historial_torneo
        FOREIGN KEY (torneo_id)
        REFERENCES torneo(torneo_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- =====================================================
-- REPORTES
-- =====================================================

CREATE TABLE reporte (
    reporte_id INT AUTO_INCREMENT PRIMARY KEY,

    administrador_id INT NOT NULL,
    tipo VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_generacion DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reporte_administrador
        FOREIGN KEY (administrador_id)
        REFERENCES administrador(usuario_id)
) ENGINE=InnoDB;