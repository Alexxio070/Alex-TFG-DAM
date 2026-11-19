// Modelo de una nota.

/// Dónde se creó la nota.
enum NoteOrigin { mobile, pc }

/// Nota de texto con su origen y sus fechas de creación y de última edición.
class Note {
  const Note({
    required this.id,
    required this.content,
    required this.origin,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String content;
  final NoteOrigin origin;
  final DateTime createdAt;
  final DateTime updatedAt;
}
