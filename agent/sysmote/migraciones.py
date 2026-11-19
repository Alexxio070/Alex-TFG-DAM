"""Cambios de esquema que se aplican a las bases de datos que ya existen.

`schema.sql` describe siempre el esquema actual y es lo que usan las bases de datos nuevas. A las que
ya existen no les llega con `CREATE TABLE IF NOT EXISTS`, así que todo cambio sobre una tabla que ya
existe (una columna nueva, por ejemplo) se escribe aquí además de en `schema.sql`.

Para añadir un cambio, se agrega al final de `MIGRACIONES` una tupla con sus sentencias SQL. La
versión del esquema es `1 + len(MIGRACIONES)` y se guarda en la propia base de datos
(`PRAGMA user_version`); la versión 1 es el esquema con el que se publicó el agente.
"""

MIGRACIONES: tuple[tuple[str, ...], ...] = ()


def version_esquema() -> int:
    """Devuelve la versión del esquema que corresponde a este código."""
    return 1 + len(MIGRACIONES)
