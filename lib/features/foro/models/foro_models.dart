class ForoPost {
  final String id;
  final String autor;
  final String titulo;
  final String preview;
  final String hace;
  final int respuestas;
  final List<String> tags;

  const ForoPost({
    required this.id,
    required this.autor,
    required this.titulo,
    required this.preview,
    required this.hace,
    this.respuestas = 0,
    this.tags = const [],
  });
}

class ForoState {
  final List<ForoPost> posts;
  final bool isLoading;

  const ForoState({
    this.posts = const [],
    this.isLoading = false,
  });
}
