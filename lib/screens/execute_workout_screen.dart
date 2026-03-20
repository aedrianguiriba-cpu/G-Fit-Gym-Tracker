import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/workout_program.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import '../widgets/exercise_video_viewer.dart';
import 'dart:async';

class ExecuteWorkoutScreen extends StatefulWidget {
  final WorkoutProgram program;

  const ExecuteWorkoutScreen({super.key, required this.program});

  @override
  State<ExecuteWorkoutScreen> createState() => _ExecuteWorkoutScreenState();
}

class _ExecuteWorkoutScreenState extends State<ExecuteWorkoutScreen> {
  late Workout _currentWorkout;
  late PageController _exercisePageController;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  int _currentExerciseIndex = 0;
  final Map<int, List<bool>> _completedSets = {}; // Track completed sets per exercise

  @override
  void initState() {
    super.initState();
    _exercisePageController = PageController();
    _initializeWorkout();
  }

  void _initializeWorkout() {
    final appState = context.read<AppState>();

    // Convert program to workout
    final programExercises = widget.program.exercises
        .map((pEx) => WorkoutExercise(
              id: pEx.id,
              exercise: pEx.exercise,
              sets: List.generate(
                pEx.sets,
                (idx) => WorkoutSet(
                  id: '$idx-${pEx.id}',
                  setNumber: idx + 1,
                  weight: pEx.weight ?? 0,
                  reps: pEx.reps,
                ),
              ),
              notes: pEx.notes,
              restSeconds: pEx.restSeconds,
            ))
        .toList();

    _currentWorkout = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: appState.currentUser!.id,
      name: widget.program.name,
      startTime: DateTime.now(),
      exercises: programExercises,
    );

    // Initialize completed sets map
    for (int i = 0; i < programExercises.length; i++) {
      _completedSets[i] = List.filled(programExercises[i].sets.length, false);
    }

    appState.startWorkout(_currentWorkout);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_currentWorkout.startTime);
      });
    });
  }

  void _toggleSetCompletion(int exerciseIdx, int setIdx) {
    setState(() {
      _completedSets[exerciseIdx]![setIdx] =
          !_completedSets[exerciseIdx]![setIdx];

      // Update workout exercise
      final exercise = _currentWorkout.exercises[exerciseIdx];
      final updatedSets = List<WorkoutSet>.from(exercise.sets);
      updatedSets[setIdx] =
          updatedSets[setIdx].copyWith(isCompleted: _completedSets[exerciseIdx]![setIdx]);

      final updatedExercise = exercise.copyWith(sets: updatedSets);
      final updatedExercises = List<WorkoutExercise>.from(_currentWorkout.exercises);
      updatedExercises[exerciseIdx] = updatedExercise;

      _currentWorkout = _currentWorkout.copyWith(exercises: updatedExercises);
    });

    context.read<AppState>().updateActiveWorkout(_currentWorkout);
  }

  void _viewExerciseVideo(int exerciseIdx) {
    final exercise = _currentWorkout.exercises[exerciseIdx].exercise;

    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ExerciseVideoViewer(
            videoUrl: exercise.videoUrl,
            exerciseName: exercise.name,
            instructions: exercise.instructions,
          ),
        ),
      ),
    );
  }

  void _finishWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to finish this workout?'),
            const SizedBox(height: 16),
            Text('Total Time: ${_formatDuration(_elapsedTime)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _exercisePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _cancelWorkout();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.program.name),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  _formatDuration(_elapsedTime),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exercise ${_currentExerciseIndex + 1} of ${_currentWorkout.exercises.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${((_currentExerciseIndex + 1) / _currentWorkout.exercises.length * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentExerciseIndex + 1) /
                          _currentWorkout.exercises.length,
                      minHeight: 6,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            // Exercise Card
            Expanded(
              child: PageView.builder(
                controller: _exercisePageController,
                onPageChanged: (index) {
                  setState(() => _currentExerciseIndex = index);
                },
                itemCount: _currentWorkout.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _currentWorkout.exercises[index];
                  final completedSets =
                      _completedSets[index] ?? List.filled(exercise.sets.length, false);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.exercise.name,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Difficulty: ${exercise.exercise.difficulty.name[0].toUpperCase()}${exercise.exercise.difficulty.name.substring(1)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (exercise.exercise.videoUrl != null &&
                                      exercise.exercise.videoUrl!.isNotEmpty)
                                    IconButton(
                                      onPressed: () => _viewExerciseVideo(index),
                                      icon: Icon(Icons.video_library,
                                          color: Colors.blue[400]),
                                      tooltip: 'Watch video',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sets List
                        const Text(
                          'Sets',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: List.generate(
                            exercise.sets.length,
                            (setIdx) {
                              final set = exercise.sets[setIdx];
                              final isCompleted = completedSets[setIdx];

                              return Card(
                                color: isCompleted
                                    ? Colors.green[900]?.withOpacity(0.3)
                                    : const Color(0xFF1A1A1A),
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  onTap: () =>
                                      _toggleSetCompletion(index, setIdx),
                                  leading: Checkbox(
                                    value: isCompleted,
                                    onChanged: (value) =>
                                        _toggleSetCompletion(index, setIdx),
                                  ),
                                  title: Text(
                                    'Set ${set.setNumber}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${set.reps} reps${set.weight > 0 ? ' @ ${set.weight}lbs' : ''}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  trailing: isCompleted
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.green)
                                      : Icon(Icons.radio_button_unchecked,
                                          color: Colors.grey[600]),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Instructions
                        if (exercise.exercise.instructions != null &&
                            exercise.exercise.instructions!.isNotEmpty) ...[
                          const Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: Text(
                              exercise.exercise.instructions!,
                              style: TextStyle(
                                color: Colors.grey[300],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],

                        // Rest timer info
                        if (exercise.restSeconds > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[900]?.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.orange[800] ??
                                        Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule,
                                      color: Colors.orange[400],
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rest: ${exercise.restSeconds}s between sets',
                                    style: TextStyle(
                                      color: Colors.orange[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _cancelWorkout,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _finishWorkout,
                      icon: const Icon(Icons.done),
                      label: const Text('Finish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
