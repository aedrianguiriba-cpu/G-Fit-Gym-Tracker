import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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
  bool _workoutStarted = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    
    // Create the workout but don't start it yet
    if (appState.hasActiveWorkout) {
      _currentWorkout = appState.activeWorkout!;
      _workoutStarted = true;
      _elapsedTime = DateTime.now().difference(_currentWorkout.startTime);
      _startTimer();
    } else if (widget.template != null) {
      _currentWorkout = widget.template!.copyWith(
        id: const Uuid().v4(),
        startTime: DateTime.now(),
        isTemplate: false,
      );
      // Sync to AppState for database operations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setActiveWorkout(_currentWorkout);
      });
    } else {
      _currentWorkout = Workout(
        id: const Uuid().v4(),
        userId: appState.currentUser!.id,
        name: 'Workout',
        startTime: DateTime.now(),
        exercises: [],
      );
      // Sync to AppState for database operations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setActiveWorkout(_currentWorkout);
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_currentWorkout.startTime);
      });
    });
  }

  void _beginWorkout() {
    final appState = context.read<AppState>();
    setState(() {
      _workoutStarted = true;
      _currentWorkout = _currentWorkout.copyWith(
        startTime: DateTime.now(),
      );
    });
    appState.startWorkout(_currentWorkout);
    _startTimer();
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
      // Save exercise to database
      final savedToDb = await appState.addExerciseToWorkout(
        _currentWorkout.id,
        selected.id,
        selected.suggestedSets ?? 3,
        selected.suggestedReps ?? 8,
      );

      if (savedToDb) {
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
        print('✅ Exercise added to workout');
      } else {
        print('❌ Failed to add exercise to database');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error adding exercise')),
          );
        }
      }
    }
  }

  void _saveWorkout() {
    context.read<AppState>().updateActiveWorkout(_currentWorkout);
  }

  Future<void> _saveAllSetsToDatabase() async {
    print('💾 Saving all sets to database...');
    final appState = context.read<AppState>();
    
    // Collect all save operations to run in parallel
    final saveFutures = <Future<void>>[];
    
    for (final exercise in _currentWorkout.exercises) {
      for (int setIdx = 0; setIdx < exercise.sets.length; setIdx++) {
        final set = exercise.sets[setIdx];
        saveFutures.add(
          appState.saveWorkoutSet(
            _currentWorkout.id,
            exercise.exercise.id,
            setIdx + 1,
            set.weight,
            set.reps,
          ).then((_) {
            print('📤 Saved: Exercise(${exercise.exercise.id}), Set(${setIdx + 1}), Weight(${set.weight}), Reps(${set.reps})');
          }).catchError((error) {
            print('❌ Error saving set: $error');
          }),
        );
      }
    }
    
    // Execute all saves in parallel
    if (saveFutures.isNotEmpty) {
      await Future.wait(saveFutures);
    }
    print('✅ All sets saved');
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
      // Show success notification immediately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Workout completed successfully!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Save all sets and finish workout in background
      _saveAllSetsToDatabase().then((_) async {
        await context.read<AppState>().finishWorkout();
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        }
      });
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

  bool _hasFilledSets() {
    // Check if any exercise has sets with weight and reps filled in
    for (var exercise in _currentWorkout.exercises) {
      for (var set in exercise.sets) {
        if (set.weight > 0 && set.reps > 0) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Always show the main workout screen
    final totalVolume = _currentWorkout.exercises.fold<double>(
      0,
      (sum, ex) =>
          sum +
          ex.sets.fold<double>(
              0, (setSum, set) => setSum + (set.weight * set.reps)),
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentWorkout.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
      body: Column(
        children: [
          // Stats Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Timer and Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatCard(
                      icon: Icons.schedule,
                      label: 'Duration',
                      value: _formatDuration(_elapsedTime),
                      color: Colors.blue,
                    ),
                    _StatCard(
                      icon: Icons.fitness_center,
                      label: 'Exercises',
                      value: '${_currentWorkout.exercises.length}',
                      color: Colors.orange,
                    ),
                    _StatCard(
                      icon: Icons.trending_up,
                      label: 'Volume',
                      value: '${totalVolume.toStringAsFixed(0)}kg',
                      color: Colors.green,
                    ),
                    _StatCard(
                      icon: Icons.layers,
                      label: 'Sets',
                      value: _currentWorkout.exercises
                          .fold<int>(0, (sum, ex) => sum + ex.sets.length)
                          .toString(),
                      color: Colors.purple,
                    ),
                  ],
                ),
                // Hint text when start button is disabled
                if (_currentWorkout.exercises.isNotEmpty && !_hasFilledSets() && !_workoutStarted) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '💡 Enter weight & reps to enable Start',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Exercises List or Empty State
          Expanded(
            child: _currentWorkout.exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fitness_center_outlined,
                            size: 60,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Start Your Workout',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Add exercises to begin tracking',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
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
                        workoutId: _currentWorkout.id,
                        onUpdate: (updated) {
                          setState(() {
                            final exercises = List.of(_currentWorkout.exercises);
                            exercises[index] = updated;
                            _currentWorkout =
                                _currentWorkout.copyWith(exercises: exercises);
                          });
                          _saveWorkout();
                        },
                        onDelete: () {
                          setState(() {
                            final exercises = List.of(_currentWorkout.exercises);
                            exercises.removeAt(index);
                            _currentWorkout =
                                _currentWorkout.copyWith(exercises: exercises);
                          });
                          _saveWorkout();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Start/Finish Button
            if (_currentWorkout.exercises.isNotEmpty)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_workoutStarted || _hasFilledSets()) ? (_workoutStarted ? _finishWorkout : _beginWorkout) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _workoutStarted ? Colors.green : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(_workoutStarted ? Icons.check : Icons.play_arrow),
                  label: Text(
                    _workoutStarted ? 'Finish Workout' : 'Start Workout',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (_currentWorkout.exercises.isNotEmpty) const SizedBox(width: 12),
            // Add Exercise Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Exercise',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _ExerciseCard extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final Function(WorkoutExercise) onUpdate;
  final VoidCallback onDelete;
  final String workoutId;

  const _ExerciseCard({
    required this.workoutExercise,
    required this.onUpdate,
    required this.onDelete,
    required this.workoutId,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {

  @override
  Widget build(BuildContext context) {
    final exercise = widget.workoutExercise.exercise;
    final totalVolume = widget.workoutExercise.sets
        .fold<double>(0, (sum, set) => sum + (set.weight * set.reps));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header with equipment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exercise.equipment.toString().split('.').last,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.workoutExercise.sets.length} sets',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                  color: Colors.red,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Volume display
            if (totalVolume > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up,
                        size: 16, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Volume: ${totalVolume.toStringAsFixed(0)} kg',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),

            if (totalVolume > 0) const SizedBox(height: 16),

            // Set headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      'Set',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Weight (kg)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Reps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Sets
            ...widget.workoutExercise.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return _SetRow(
                setNumber: index + 1,
                set: set,
                onUpdate: (updatedSet) {
                  print('🔄 Set updated in card:');
                  print('   Weight: ${updatedSet.weight}, Reps: ${updatedSet.reps}');
                  final sets = List.of(widget.workoutExercise.sets);
                  sets[index] = updatedSet;
                  widget.onUpdate(widget.workoutExercise.copyWith(sets: sets));
                  // Sets will be saved to database when user clicks Finish
                },
                onDelete: () {
                  if (widget.workoutExercise.sets.length > 1) {
                    final sets = List.of(widget.workoutExercise.sets);
                    sets.removeAt(index);
                    widget.onUpdate(widget.workoutExercise.copyWith(sets: sets));
                  }
                },
              );
            }),

            const SizedBox(height: 12),

            // Add set button
            Center(
              child: TextButton.icon(
                onPressed: () {
                  final lastSet = widget.workoutExercise.sets.last;
                  final newSet = WorkoutSet(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    setNumber: widget.workoutExercise.sets.length + 1,
                    weight: lastSet.weight,
                    reps: lastSet.reps,
                  );
                  widget.onUpdate(widget.workoutExercise.copyWith(
                    sets: [...widget.workoutExercise.sets, newSet],
                  ));
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _SetRow extends StatefulWidget {
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
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight > 0 ? widget.set.weight.toString() : '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps > 0 ? widget.set.reps.toString() : '',
    );
  }

  @override
  void didUpdateWidget(_SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controllers if the set object changed from outside
    if (oldWidget.set.id != widget.set.id ||
        oldWidget.set.weight != widget.set.weight) {
      _weightController.text =
          widget.set.weight > 0 ? widget.set.weight.toString() : '';
    }
    if (oldWidget.set.id != widget.set.id ||
        oldWidget.set.reps != widget.set.reps) {
      _repsController.text =
          widget.set.reps > 0 ? widget.set.reps.toString() : '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: widget.set.isCompleted
              ? Colors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.set.isCompleted
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Set number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.setNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Weight input
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Weight',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    print('📝 Weight field changed: $value');
                    final weight = double.tryParse(value) ?? 0;
                    widget.onUpdate(widget.set.copyWith(weight: weight));
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Reps input
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Reps',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    print('📝 Reps field changed: $value');
                    final reps = int.tryParse(value) ?? 0;
                    widget.onUpdate(widget.set.copyWith(reps: reps));
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Completed checkbox
              Container(
                decoration: BoxDecoration(
                  color: widget.set.isCompleted
                      ? Colors.green.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    widget.set.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: widget.set.isCompleted ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                  onPressed: () {
                    widget.onUpdate(widget.set.copyWith(
                      isCompleted: !widget.set.isCompleted,
                      completedAt: !widget.set.isCompleted ? DateTime.now() : null,
                    ));
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
            ],
          ),
        ),
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

/// Stat card widget for displaying workout statistics
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
