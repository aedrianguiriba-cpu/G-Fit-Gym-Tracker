import 'exercise.dart';
import 'workout_set.dart';

class WorkoutExercise {
  final String id;
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final String? notes;
  final int restSeconds;

  WorkoutExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    this.notes,
    this.restSeconds = 90,
  });

  WorkoutExercise copyWith({
    String? id,
    Exercise? exercise,
    List<WorkoutSet>? sets,
    String? notes,
    int? restSeconds,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'],
      exercise: Exercise.fromJson(json['exercise']),
      sets: (json['sets'] as List)
          .map((s) => WorkoutSet.fromJson(s))
          .toList(),
      notes: json['notes'],
      restSeconds: json['restSeconds'] ?? 90,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise': exercise.toJson(),
      'sets': sets.map((s) => s.toJson()).toList(),
      'notes': notes,
      'restSeconds': restSeconds,
    };
  }
}
