class WorkoutSet {
  final String id;
  final int setNumber;
  final double weight;
  final int reps;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;

  WorkoutSet({
    required this.id,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
  });

  WorkoutSet copyWith({
    String? id,
    int? setNumber,
    double? weight,
    int? reps,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'],
      setNumber: json['setNumber'],
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}
