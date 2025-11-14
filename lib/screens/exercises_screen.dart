import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/exercise.dart';
import '../widgets/exercise_video_player.dart';
import '../widgets/branded_app_bar.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _searchQuery = '';
  MuscleGroup? _selectedMuscle;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    List<Exercise> exercises;

    if (_selectedMuscle != null) {
      exercises = appState.getExercisesByMuscleGroup(_selectedMuscle!);
    } else if (_searchQuery.isNotEmpty) {
      exercises = appState.searchExercises(_searchQuery);
    } else {
      exercises = appState.exercises;
    }

    return Scaffold(
      appBar: const BrandedAppBar(
        title: 'Exercise Library',
        showLogo: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _selectedMuscle = null;
                });
              },
            ),
          ),

          // Muscle group filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedMuscle == null,
                  onTap: () {
                    setState(() => _selectedMuscle = null);
                  },
                ),
                ...MuscleGroup.values.map((muscle) {
                  return _FilterChip(
                    label: _muscleName(muscle),
                    isSelected: _selectedMuscle == muscle,
                    onTap: () {
                      setState(() {
                        _selectedMuscle = muscle;
                        _searchQuery = '';
                      });
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'No exercises found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _getMuscleColor(exercise.primaryMuscle),
                            child: Icon(
                              _getEquipmentIcon(exercise.equipment),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            exercise.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            '${_muscleName(exercise.primaryMuscle)} • ${_equipmentName(exercise.equipment)}',
                            style: TextStyle(color: Colors.white.withOpacity(0.6)),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _showExerciseDetail(context, exercise);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetail(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getMuscleColor(exercise.primaryMuscle),
                      child: Icon(
                        _getEquipmentIcon(exercise.equipment),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _muscleName(exercise.primaryMuscle),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Animation/Video Preview
                ExerciseVideoPlayer(
                  videoUrl: exercise.videoUrl,
                  muscleGroup: exercise.primaryMuscle,
                ),
                const SizedBox(height: 24),
                
                _InfoRow(
                  icon: Icons.fitness_center,
                  label: 'Equipment',
                  value: _equipmentName(exercise.equipment),
                ),
                const SizedBox(height: 12),
                
                _InfoRow(
                  icon: Icons.accessibility_new,
                  label: 'Primary Muscle',
                  value: _muscleName(exercise.primaryMuscle),
                ),
                
                if (exercise.secondaryMuscles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.group_work,
                    label: 'Secondary Muscles',
                    value: exercise.secondaryMuscles
                        .map((m) => _muscleName(m))
                        .join(', '),
                  ),
                ],
                
                if (exercise.instructions != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.list_alt,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      exercise.instructions!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Add to workout functionality
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add to Workout'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _muscleName(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.cardio:
        return 'Cardio';
      case MuscleGroup.fullBody:
        return 'Full Body';
    }
  }

  String _equipmentName(EquipmentType equipment) {
    switch (equipment) {
      case EquipmentType.barbell:
        return 'Barbell';
      case EquipmentType.dumbbell:
        return 'Dumbbell';
      case EquipmentType.machine:
        return 'Machine';
      case EquipmentType.bodyweight:
        return 'Bodyweight';
      case EquipmentType.cable:
        return 'Cable';
      case EquipmentType.kettlebell:
        return 'Kettlebell';
      case EquipmentType.bands:
        return 'Bands';
    }
  }

  Color _getMuscleColor(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.chest:
        return Colors.red;
      case MuscleGroup.back:
        return Colors.blue;
      case MuscleGroup.shoulders:
        return Colors.orange;
      case MuscleGroup.arms:
        return Colors.purple;
      case MuscleGroup.legs:
        return Colors.green;
      case MuscleGroup.core:
        return Colors.teal;
      case MuscleGroup.cardio:
        return Colors.pink;
      case MuscleGroup.fullBody:
        return Colors.indigo;
    }
  }

  IconData _getEquipmentIcon(EquipmentType equipment) {
    switch (equipment) {
      case EquipmentType.barbell:
      case EquipmentType.dumbbell:
      case EquipmentType.kettlebell:
        return Icons.fitness_center;
      case EquipmentType.machine:
        return Icons.precision_manufacturing;
      case EquipmentType.bodyweight:
        return Icons.accessibility_new;
      case EquipmentType.cable:
        return Icons.cable;
      case EquipmentType.bands:
        return Icons.straighten;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
