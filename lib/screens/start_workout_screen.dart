import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'dart:async';

class StartWorkoutScreen extends StatefulWidget {
  final Workout? template;

  const StartWorkoutScreen({super.key, this.template});

  @override
  State<StartWorkoutScreen> createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends State<StartWorkoutScreen> {
  late Workout _currentWorkout;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    
    if (appState.hasActiveWorkout) {
      _currentWorkout = appState.activeWorkout!;
      _elapsedTime = DateTime.now().difference(_currentWorkout.startTime);
    } else if (widget.template != null) {
      _currentWorkout = widget.template!.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        isTemplate: false,
      );
      appState.startWorkout(_currentWorkout);
    } else {
      _currentWorkout = Workout(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: appState.currentUser!.id,
        name: 'Workout',
        startTime: DateTime.now(),
        exercises: [],
      );
      appState.startWorkout(_currentWorkout);
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_currentWorkout.startTime);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addExercise() async {
    final appState = context.read<AppState>();
    final exercises = appState.exercises;

    final selected = await showDialog<dynamic>(
      context: context,
      builder: (context) => _ExercisePickerDialog(exercises: exercises),
    );

    if (selected != null) {
      setState(() {
        final newExercise = WorkoutExercise(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          exercise: selected,
          sets: [
            WorkoutSet(
              id: '${DateTime.now().millisecondsSinceEpoch}',
              setNumber: 1,
              weight: 0,
              reps: 0,
            ),
          ],
        );
        _currentWorkout = _currentWorkout.copyWith(
          exercises: [..._currentWorkout.exercises, newExercise],
        );
      });
      _saveWorkout();
    }
  }

  void _saveWorkout() {
    context.read<AppState>().updateActiveWorkout(_currentWorkout);
  }

  void _finishWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: const Text('Are you sure you want to finish this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AppState>().finishWorkout();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _cancelWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Workout?'),
        content: const Text('All progress will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AppState>().cancelWorkout();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentWorkout.name),
            Text(
              _formatDuration(_elapsedTime),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelWorkout,
          ),
        ],
      ),
      body: _currentWorkout.exercises.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No exercises added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add exercises',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _currentWorkout.exercises.length,
              itemBuilder: (context, index) {
                final workoutExercise = _currentWorkout.exercises[index];
                return _ExerciseCard(
                  workoutExercise: workoutExercise,
                  onUpdate: (updated) {
                    setState(() {
                      final exercises = List.of(_currentWorkout.exercises);
                      exercises[index] = updated;
                      _currentWorkout = _currentWorkout.copyWith(exercises: exercises);
                    });
                    _saveWorkout();
                  },
                  onDelete: () {
                    setState(() {
                      final exercises = List.of(_currentWorkout.exercises);
                      exercises.removeAt(index);
                      _currentWorkout = _currentWorkout.copyWith(exercises: exercises);
                    });
                    _saveWorkout();
                  },
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addExercise,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'finish',
            onPressed: _currentWorkout.exercises.isEmpty ? null : _finishWorkout,
            icon: const Icon(Icons.check),
            label: const Text('Finish'),
            backgroundColor: _currentWorkout.exercises.isEmpty
                ? Colors.grey
                : Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExercise workoutExercise;
  final Function(WorkoutExercise) onUpdate;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.workoutExercise,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    workoutExercise.exercise.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Set headers
            Row(
              children: [
                const SizedBox(width: 50),
                const Expanded(
                  child: Text('Weight (kg)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Expanded(
                  child: Text('Reps',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 8),

            // Sets
            ...workoutExercise.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return _SetRow(
                setNumber: index + 1,
                set: set,
                onUpdate: (updatedSet) {
                  final sets = List.of(workoutExercise.sets);
                  sets[index] = updatedSet;
                  onUpdate(workoutExercise.copyWith(sets: sets));
                },
                onDelete: () {
                  if (workoutExercise.sets.length > 1) {
                    final sets = List.of(workoutExercise.sets);
                    sets.removeAt(index);
                    onUpdate(workoutExercise.copyWith(sets: sets));
                  }
                },
              );
            }),

            const SizedBox(height: 8),
            
            // Add set button
            TextButton.icon(
              onPressed: () {
                final newSet = WorkoutSet(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  setNumber: workoutExercise.sets.length + 1,
                  weight: workoutExercise.sets.last.weight,
                  reps: workoutExercise.sets.last.reps,
                );
                onUpdate(workoutExercise.copyWith(
                  sets: [...workoutExercise.sets, newSet],
                ));
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final WorkoutSet set;
  final Function(WorkoutSet) onUpdate;
  final VoidCallback onDelete;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '$setNumber',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(
                text: set.weight > 0 ? set.weight.toString() : '',
              ),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final weight = double.tryParse(value) ?? 0;
                onUpdate(set.copyWith(weight: weight));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: TextEditingController(
                text: set.reps > 0 ? set.reps.toString() : '',
              ),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final reps = int.tryParse(value) ?? 0;
                onUpdate(set.copyWith(reps: reps));
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              set.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: set.isCompleted ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              onUpdate(set.copyWith(
                isCompleted: !set.isCompleted,
                completedAt: !set.isCompleted ? DateTime.now() : null,
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _ExercisePickerDialog extends StatefulWidget {
  final List<dynamic> exercises;

  const _ExercisePickerDialog({required this.exercises});

  @override
  State<_ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<_ExercisePickerDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises.where((ex) {
      return ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Exercise',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = filteredExercises[index];
                  return ListTile(
                    title: Text(exercise.name),
                    subtitle: Text(
                      exercise.primaryMuscle.toString().split('.').last.toUpperCase(),
                    ),
                    trailing: Icon(
                      _getEquipmentIcon(exercise.equipment),
                    ),
                    onTap: () => Navigator.pop(context, exercise),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEquipmentIcon(dynamic equipment) {
    final equipmentStr = equipment.toString().split('.').last;
    switch (equipmentStr) {
      case 'barbell':
        return Icons.fitness_center;
      case 'dumbbell':
        return Icons.fitness_center;
      case 'machine':
        return Icons.precision_manufacturing;
      case 'bodyweight':
        return Icons.accessibility_new;
      case 'cable':
        return Icons.cable;
      default:
        return Icons.fitness_center;
    }
  }
}
