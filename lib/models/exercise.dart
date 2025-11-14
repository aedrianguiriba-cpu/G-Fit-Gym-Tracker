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

class Exercise {
  final String id;
  final String name;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final EquipmentType equipment;
  final String? instructions;
  final String? videoUrl;
  final bool isCustom;

  Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    this.instructions,
    this.videoUrl,
    this.isCustom = false,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      primaryMuscle: MuscleGroup.values.firstWhere(
        (e) => e.toString() == 'MuscleGroup.${json['primaryMuscle']}',
      ),
      secondaryMuscles: (json['secondaryMuscles'] as List?)
              ?.map((m) => MuscleGroup.values.firstWhere(
                    (e) => e.toString() == 'MuscleGroup.$m',
                  ))
              .toList() ??
          [],
      equipment: EquipmentType.values.firstWhere(
        (e) => e.toString() == 'EquipmentType.${json['equipment']}',
      ),
      instructions: json['instructions'],
      videoUrl: json['videoUrl'],
      isCustom: json['isCustom'] ?? false,
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
      'instructions': instructions,
      'videoUrl': videoUrl,
      'isCustom': isCustom,
    };
  }
}
