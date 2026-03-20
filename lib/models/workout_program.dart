import 'exercise.dart';

class WorkoutProgram {
  final String id;
  final String name;
  final String description;
  final DifficultyLevel difficulty;
  final List<String> targetMuscles; // List of MuscleGroup names
  final List<ProgramExercise> exercises;
  final int estimatedDurationMinutes;
  final String? imageUrl;
  final DateTime createdAt;
  final String createdByAdmin;
  final bool isActive;

  WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.targetMuscles,
    required this.exercises,
    required this.estimatedDurationMinutes,
    this.imageUrl,
    required this.createdAt,
    required this.createdByAdmin,
    this.isActive = true,
  });

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    final difficultyValue = json['difficulty'] ?? json['difficultyLevel'] ?? 'beginner';
    
    return WorkoutProgram(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == 'DifficultyLevel.$difficultyValue',
        orElse: () => DifficultyLevel.beginner,
      ),
      targetMuscles: List<String>.from(json['targetMuscles'] as List? ?? []),
      exercises: (json['exercises'] as List?)
              ?.map((e) => ProgramExercise.fromJson(e))
              .toList() ??
          [],
      estimatedDurationMinutes: json['estimatedDurationMinutes'] ?? 30,
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      createdByAdmin: json['createdByAdmin'] ?? 'System',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty.toString().split('.').last,
      'targetMuscles': targetMuscles,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'createdByAdmin': createdByAdmin,
      'isActive': isActive,
    };
  }

  WorkoutProgram copyWith({
    String? id,
    String? name,
    String? description,
    DifficultyLevel? difficulty,
    List<String>? targetMuscles,
    List<ProgramExercise>? exercises,
    int? estimatedDurationMinutes,
    String? imageUrl,
    DateTime? createdAt,
    String? createdByAdmin,
    bool? isActive,
  }) {
    return WorkoutProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      exercises: exercises ?? this.exercises,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      createdByAdmin: createdByAdmin ?? this.createdByAdmin,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ProgramExercise {
  final String id;
  final Exercise exercise;
  final int sets;
  final int reps;
  final double? weight;
  final String? notes;
  final int restSeconds;
  final int orderIndex;

  ProgramExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.reps,
    this.weight,
    this.notes,
    this.restSeconds = 90,
    required this.orderIndex,
  });

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    return ProgramExercise(
      id: json['id'],
      exercise: Exercise.fromJson(json['exercise'] ?? json),
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? 10,
      weight: json['weight'] != null ? double.parse(json['weight'].toString()) : null,
      notes: json['notes'],
      restSeconds: json['restSeconds'] ?? 90,
      orderIndex: json['orderIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise': exercise.toJson(),
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
      'restSeconds': restSeconds,
      'orderIndex': orderIndex,
    };
  }
}
