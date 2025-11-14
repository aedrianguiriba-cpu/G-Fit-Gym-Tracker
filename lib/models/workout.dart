import 'workout_exercise.dart';

class Workout {
  final String id;
  final String userId;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutExercise> exercises;
  final String? notes;
  final bool isTemplate;
  final bool isCompleted;

  Workout({
    required this.id,
    required this.userId,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.notes,
    this.isTemplate = false,
    this.isCompleted = false,
  });

  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return Duration.zero;
  }

  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
  }

  int get completedSets {
    return exercises.fold(
      0,
      (sum, exercise) =>
          sum + exercise.sets.where((s) => s.isCompleted).length,
    );
  }

  double get totalVolume {
    return exercises.fold(
      0.0,
      (sum, exercise) => sum + exercise.sets.fold(
        0.0,
        (setSum, set) => setSum + (set.weight * set.reps),
      ),
    );
  }

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    List<WorkoutExercise>? exercises,
    String? notes,
    bool? isTemplate,
    bool? isCompleted,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      isTemplate: isTemplate ?? this.isTemplate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e))
          .toList(),
      notes: json['notes'],
      isTemplate: json['isTemplate'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'notes': notes,
      'isTemplate': isTemplate,
      'isCompleted': isCompleted,
    };
  }
}
