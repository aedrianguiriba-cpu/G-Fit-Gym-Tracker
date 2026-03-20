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
    final startTime = json['start_time'] != null 
        ? DateTime.parse(json['start_time'])
        : DateTime.parse(json['startTime']);
    final endTime = json['end_time'] != null 
        ? DateTime.parse(json['end_time'])
        : (json['endTime'] != null ? DateTime.parse(json['endTime']) : null);
    
    print('📦 Parsing Workout.fromJson:');
    print('   id: ${json['id']}');
    print('   name: ${json['name']}');
    print('   startTime: $startTime (raw: ${json['start_time']})');
    print('   endTime: $endTime (raw: ${json['end_time']})');
    print('   isCompleted: ${json['is_completed'] ?? json['isCompleted']}');
    
    return Workout(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      name: json['name'],
      startTime: startTime,
      endTime: endTime,
      exercises: (json['exercises'] as List?)
          ?.map((e) => WorkoutExercise.fromJson(e))
          .toList() ?? [],
      notes: json['notes'],
      isTemplate: _parseBool(json['is_template'] ?? json['isTemplate']),
      isCompleted: _parseBool(json['is_completed'] ?? json['isCompleted']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
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
