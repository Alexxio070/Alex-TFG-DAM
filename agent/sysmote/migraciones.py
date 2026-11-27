"""Cambios de esquema que se aplican a las bases de datos que ya existen.

`schema.sql` describe siempre el esquema actual y es lo que usan las bases de datos nuevas. A las que
ya existen no les llega con `CREATE TABLE IF NOT EXISTS`, así que todo cambio sobre una tabla que ya
existe (una columna nueva, por ejemplo) se escribe aquí además de en `schema.sql`.

Para añadir un cambio, se agrega al final de `MIGRACIONES` una tupla con sus sentencias SQL. La
versión del esquema es `1 + len(MIGRACIONES)` y se guarda en la propia base de datos
(`PRAGMA user_version`); la versión 1 es el esquema con el que se publicó el agente.
"""

MIGRACIONES: tuple[tuple[str, ...], ...] = (
    # Migración 1 (esquema 2): la sesión pasa a caducar a los 7 días de iniciarse. Las sesiones que
    # ya existían reciben `creado_en + 7 días`; las más antiguas fallan en su próximo uso. El DEFAULT
    # solo hace falta porque SQLite no deja añadir una columna NOT NULL sin él; el UPDATE lo sustituye.
    (
        "ALTER TABLE sesion ADD COLUMN caduca_en TEXT NOT NULL DEFAULT ''",
        "UPDATE sesion SET caduca_en = strftime('%Y-%m-%dT%H:%M:%f', creado_en, '+7 days') || '+00:00'",
    ),
)


def version_esquema() -> int:
    """Devuelve la versión del esquema que corresponde a este código."""
    return 1 + len(MIGRACIONES)
