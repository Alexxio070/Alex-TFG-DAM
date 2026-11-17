-- El agente ejecuta PRAGMA foreign_keys = ON en cada conexión (ver database.py);
-- sin eso SQLite ignora las claves foráneas y el ON DELETE CASCADE.

CREATE TABLE IF NOT EXISTS usuario (
    id INTEGER PRIMARY KEY,
    nombre_usuario TEXT NOT NULL UNIQUE,
    hash_contrasena TEXT NOT NULL,
    creado_en TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sesion (
    id INTEGER PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuario(id),
    hash_token TEXT NOT NULL UNIQUE,
    dispositivo TEXT NOT NULL,
    creado_en TEXT NOT NULL,
    ultimo_acceso TEXT NOT NULL,
    revocada INTEGER NOT NULL DEFAULT 0,
    motivo_revocacion TEXT
);

CREATE TABLE IF NOT EXISTS intento_login (
    id INTEGER PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuario(id),
    nombre_usuario TEXT NOT NULL,
    origen TEXT NOT NULL,
    fecha TEXT NOT NULL,
    exito INTEGER NOT NULL
);

-- Efímera: la solicitud de login pendiente cuando ya hay otra sesión activa.
-- El id es el valor aleatorio de 32 bytes de GET /login/solicitud/{id}, no un
-- autoincremental (contrato de la fase 3, §2).
CREATE TABLE IF NOT EXISTS solicitud_login (
    id TEXT PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuario(id),
    dispositivo TEXT NOT NULL,
    creada TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'pendiente',
    caduca_en TEXT NOT NULL
);
