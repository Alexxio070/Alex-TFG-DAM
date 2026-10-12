enum NoteOrigin { mobile, pc }

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
