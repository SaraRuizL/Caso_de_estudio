
CREATE DATABASE coleccion;
USE coleccion;

-- Tabla de usuarios
CREATE TABLE usuarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    ultimo_login DATETIME
);

-- Tabla de artistas
CREATE TABLE artistas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    creado DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de álbumes
CREATE TABLE albumes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT NOT NULL,
    titulo VARCHAR(100) NOT NULL,
    anio INT,
    descripcion TEXT,
    formato ENUM('CD', 'Vinilo', 'Casete', 'Digital', 'Otro') NOT NULL,
    creado DATETIME DEFAULT CURRENT_TIMESTAMP,
    actualizado DATETIME ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Tabla de canciones
CREATE TABLE canciones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(100) NOT NULL,
    duracion INT NOT NULL,
    creado DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario_id INT NOT NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Relación álbumes-artistas
CREATE TABLE album_artista (
    album_id INT NOT NULL,
    artista_id INT NOT NULL,
    rol ENUM('Intérprete', 'Compositor', 'Productor', 'Otro'),
    PRIMARY KEY (album_id, artista_id),
    FOREIGN KEY (album_id) REFERENCES albumes(id),
    FOREIGN KEY (artista_id) REFERENCES artistas(id)
);

-- Relación álbumes-canciones
CREATE TABLE album_cancion (
    album_id INT NOT NULL,
    cancion_id INT NOT NULL,
    pista INT,
    PRIMARY KEY (album_id, cancion_id),
    FOREIGN KEY (album_id) REFERENCES albumes(id),
    FOREIGN KEY (cancion_id) REFERENCES canciones(id)
);

-- Relación canciones-artistas
CREATE TABLE cancion_artista (
    cancion_id INT NOT NULL,
    artista_id INT NOT NULL,
    PRIMARY KEY (cancion_id, artista_id),
    FOREIGN KEY (cancion_id) REFERENCES canciones(id),
    FOREIGN KEY (artista_id) REFERENCES artistas(id)
);

-- Datos de ejemplo para usuarios
INSERT INTO usuarios (nombre, password, ultimo_login) VALUES 
('mj_fan', SHA2('thriller123', 256), '2023-05-15 10:30:00'),
('queen_lover', SHA2('bohemian456', 256), '2023-05-16 14:45:00'),
('rock_clasico', SHA2('stairway789', 256), '2023-05-17 09:15:00');

-- Datos de ejemplo para artistas
INSERT INTO artistas (nombre, descripcion) VALUES 
('Michael Jackson', 'El Rey del Pop'),
('Queen', 'Banda británica de rock'),
('Led Zeppelin', 'Banda pionera del hard rock'),
('Freddie Mercury', 'Vocalista de Queen');

-- Datos de ejemplo para álbumes
INSERT INTO albumes (usuario_id, titulo, anio, descripcion, formato) VALUES 
(1, 'Thriller', 1982, 'Álbum más vendido de la historia', 'Vinilo'),
(2, 'A Night at the Opera', 1975, 'Incluye Bohemian Rhapsody', 'CD'),
(3, 'Led Zeppelin IV', 1971, 'Incluye Stairway to Heaven', 'Vinilo'),
(1, 'Bad', 1987, 'Séptimo álbum de estudio de MJ', 'Casete');

-- Relaciones álbumes-artistas
INSERT INTO album_artista VALUES 
(1, 1, 'Intérprete'),
(2, 2, 'Intérprete'),
(2, 4, 'Intérprete'),
(3, 3, 'Intérprete'),
(4, 1, 'Intérprete');

-- Datos de ejemplo para canciones
INSERT INTO canciones (titulo, duracion, usuario_id) VALUES 
('Billie Jean', 294, 1),
('Beat It', 258, 1),
('Bohemian Rhapsody', 354, 2),
('Stairway to Heaven', 482, 3),
('Smooth Criminal', 253, 1),
('Another One Bites the Dust', 215, 2);

-- Relaciones canciones-artistas
INSERT INTO cancion_artista VALUES 
(1, 1),
(2, 1),
(3, 2),
(3, 4),
(4, 3),
(5, 1),
(6, 2);

-- Relaciones álbumes-canciones
INSERT INTO album_cancion VALUES 
(1, 1, 2),
(1, 2, 3),
(2, 3, 1),
(3, 4, 4),
(4, 5, 1),
(2, 6, 3);

-- Procedimientos almacenados
DELIMITER //

-- Procedimiento para registrar usuario
CREATE PROCEDURE registrar_usuario(
    IN p_nombre VARCHAR(50),
    IN p_password VARCHAR(255)
)
BEGIN
    INSERT INTO usuarios (nombre, password)
    VALUES (p_nombre, SHA2(p_password, 256));
END //

-- Procedimiento para iniciar sesión
CREATE PROCEDURE iniciar_sesion(
    IN p_nombre VARCHAR(50),
    IN p_password VARCHAR(255)
)
BEGIN
    SELECT id, nombre
    FROM usuarios
    WHERE nombre = p_nombre
    AND password = SHA2(p_password, 256);
    
    UPDATE usuarios
    SET ultimo_login = NOW()
    WHERE nombre = p_nombre;
END //

-- Procedimiento para agregar canción a álbum
CREATE PROCEDURE agregar_cancion_album(
    IN p_album_id INT,
    IN p_cancion_id INT,
    IN p_pista INT,
    IN p_usuario_id INT
)
BEGIN
    DECLARE creador INT;
    
    IF EXISTS (SELECT 1 FROM albumes WHERE id = p_album_id AND usuario_id = p_usuario_id) THEN
        SELECT usuario_id INTO creador FROM canciones WHERE id = p_cancion_id;
        
        IF creador = p_usuario_id THEN
            INSERT INTO album_cancion (album_id, cancion_id, pista)
            VALUES (p_album_id, p_cancion_id, p_pista);
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No tienes permiso para esta canción';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No eres el dueño del álbum';
    END IF;
END //

DELIMITER ;

-- Consultas de ejemplo
-- Mostrar álbumes de un usuario
SELECT * FROM albumes WHERE usuario_id = 1;

-- Mostrar canciones de un álbum con duración y artista
SELECT c.titulo, 
       CONCAT(FLOOR(c.duracion / 60), ':', LPAD(c.duracion % 60, 2, '0')) AS duracion,
       a.nombre AS artista
FROM album_cancion ac
JOIN canciones c ON ac.cancion_id = c.id
JOIN cancion_artista ca ON c.id = ca.cancion_id
JOIN artistas a ON ca.artista_id = a.id
WHERE ac.album_id = 1
GROUP BY c.id, ac.pista
ORDER BY ac.pista;

-- Buscar canciones por título
SELECT c.titulo, 
       CONCAT(FLOOR(c.duracion / 60), ':', LPAD(c.duracion % 60, 2, '0')) AS duracion,
       GROUP_CONCAT(a.nombre SEPARATOR ', ') AS artistas,
       u.nombre AS creador
FROM canciones c
JOIN cancion_artista ca ON c.id = ca.cancion_id
JOIN artistas a ON ca.artista_id = a.id
JOIN usuarios u ON c.usuario_id = u.id
WHERE c.titulo LIKE '%Bohemian%'
GROUP BY c.id;

-- Ejecutar procedimientos almacenados
CALL registrar_usuario('nuevo_usuario', 'password123');
CALL iniciar_sesion('mj_fan', 'thriller123');
CALL agregar_cancion_album(1, 6, 5, 1);

-- Mostrar estructura de la base de datos
SHOW TABLES;
DESCRIBE artistas;
DESCRIBE usuarios;
DESCRIBE canciones;
DESCRIBE album_cancion;
DESCRIBE albumes;