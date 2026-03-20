enum MuscleGroup {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core,
  cardio,
  fullBody,
}

enum EquipmentType {
  barbell,
  dumbbell,
  machine,
  bodyweight,
  cable,
  kettlebell,
  bands,
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
}

class Exercise {
  final String id;
  final String name;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final EquipmentType equipment;
  final DifficultyLevel difficulty;
  final String? instructions;
  final String? videoUrl;
  final bool isCustom;
  final int? suggestedSets;
  final int? suggestedReps;

  Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    this.difficulty = DifficultyLevel.beginner,
    this.instructions,
    this.videoUrl,
    this.isCustom = false,
    this.suggestedSets,
    this.suggestedReps,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase (from API) and snake_case (from database)
    final muscleGroupValue = json['primaryMuscle'] ?? json['primary_muscle'] ?? json['muscle_group'] ?? 'chest';
    final equipmentValue = json['equipment'] ?? 'bodyweight';
    final difficultyValue = json['difficulty'] ?? json['difficultyLevel'] ?? 'beginner';

    return Exercise(
      id: json['id'],
      name: json['name'],
      primaryMuscle: MuscleGroup.values.firstWhere(
        (e) => e.toString() == 'MuscleGroup.$muscleGroupValue',
        orElse: () => MuscleGroup.chest,
      ),
      secondaryMuscles: _parseSecondaryMuscles(
          json['secondaryMuscles'] ?? json['secondary_muscles']) ??
          <MuscleGroup>[],
      equipment: EquipmentType.values.firstWhere(
        (e) => e.toString() == 'EquipmentType.$equipmentValue',
        orElse: () => EquipmentType.bodyweight,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == 'DifficultyLevel.$difficultyValue',
        orElse: () => DifficultyLevel.beginner,
      ),
      instructions: json['instructions'] ?? json['description'],
      videoUrl: json['videoUrl'] ?? json['video_url'],
      isCustom: json['isCustom'] ?? json['is_custom'] ?? false,
      suggestedSets: json['suggestedSets'] ?? json['suggested_sets'],
      suggestedReps: json['suggestedReps'] ?? json['suggested_reps'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryMuscle': primaryMuscle.toString().split('.').last,
      'secondaryMuscles':
          secondaryMuscles.map((m) => m.toString().split('.').last).toList(),
      'equipment': equipment.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'instructions': instructions,
      'videoUrl': videoUrl,
      'isCustom': isCustom,
    };
  }

  // Helper method to safely parse secondary_muscles from List<dynamic>
  static List<MuscleGroup>? _parseSecondaryMuscles(dynamic input) {
    if (input == null) return null;

    try {
      // Handle List<dynamic> from database
      if (input is List) {
        if (input.isEmpty) return <MuscleGroup>[];

        return input
            .where((item) => item != null && item is String)
            .cast<String>()
            .map((m) => MuscleGroup.values.firstWhere(
                  (e) => e.toString() == 'MuscleGroup.$m',
                  orElse: () => MuscleGroup.chest,
                ))
            .toList();
      }
    } catch (e) {
      print('⚠️ Error parsing secondary_muscles: $e (input: $input)');
    }

    return null;
  }
}
