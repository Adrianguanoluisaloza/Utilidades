class Opinion {
  final int idOpinion;
  final int? idUsuario;
  final String? nombre;
  final String? email;
  final int rating; // 1..5
  final String comentario;
  final String? clasificacion; // mala, regular, buena, excelente
  final String? plataforma; // web, app
  final String? estado; // aprobada, pendiente, rechazada
  final DateTime createdAt;

  Opinion({
    required this.idOpinion,
    this.idUsuario,
    this.nombre,
    this.email,
    required this.rating,
    required this.comentario,
    this.clasificacion,
    this.plataforma,
    this.estado,
    required this.createdAt,
  });

  factory Opinion.fromMap(Map<String, dynamic> map) {
    return Opinion(
      idOpinion: (map['id_opinion'] ?? map['id'] ?? 0) as int,
      idUsuario: (map['id_usuario'] ?? map['usuario_id']) as int?,
      nombre: map['nombre']?.toString() ?? map['cliente_nombre']?.toString(),
      email: map['email']?.toString(),
      rating: (map['rating'] ?? map['calificacion'] ?? 5) is int
          ? (map['rating'] ?? map['calificacion'] ?? 5) as int
          : int.tryParse(
                  (map['rating'] ?? map['calificacion'] ?? '5').toString()) ??
              5,
      comentario:
          map['comentario']?.toString() ?? map['opinion']?.toString() ?? '',
      clasificacion: map['clasificacion']?.toString(),
      plataforma: map['plataforma']?.toString(),
      estado: map['estado']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ??
              map['fecha_creacion']?.toString() ??
              '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id_opinion': idOpinion,
        'id_usuario': idUsuario,
        'nombre': nombre,
        'email': email,
        'rating': rating,
        'comentario': comentario,
        'clasificacion': clasificacion,
        'plataforma': plataforma,
        'estado': estado,
        'created_at': createdAt.toIso8601String(),
      }..removeWhere((k, v) => v == null);
}
