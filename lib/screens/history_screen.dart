import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/workout.dart';
import '../widgets/branded_app_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final workouts = appState.getWorkoutHistory();

    return Scaffold(
      appBar: const BrandedAppBar(
        title: 'Workout History',
        showLogo: true,
      ),
      body: workouts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined,
                      size: 80, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No workout history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your first workout to see it here!',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return _WorkoutHistoryCard(
                  workout: workout,
                  onTap: () => _showWorkoutDetail(context, workout),
                  onDelete: () => _deleteWorkout(context, workout),
                );
              },
            ),
    );
  }

  void _showWorkoutDetail(BuildContext context, Workout workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      workout.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, MMMM d, y').format(workout.startTime),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              
              // Statistics
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: _formatDuration(workout.duration),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.fitness_center,
                      label: 'Exercises',
                      value: '${workout.exercises.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.repeat,
                      label: 'Total Sets',
                      value: '${workout.totalSets}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.trending_up,
                      label: 'Volume',
                      value: '${workout.totalVolume.toStringAsFixed(0)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Exercises
              const Text(
                'Exercises',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              ...workout.exercises.map((workoutEx) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workoutEx.exercise.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...workoutEx.sets.map((set) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    'Set ${set.setNumber}:',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                Text(
                                  '${set.weight} kg × ${set.reps} reps',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (set.isCompleted)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteWorkout(BuildContext context, Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AppState>().deleteWorkout(workout.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkoutHistoryCard({
    required this.workout,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMM d').format(workout.startTime),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
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
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: Colors.white.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(workout.duration),
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.fitness_center, size: 16, color: Colors.white.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.exercises.length} exercises',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.repeat, size: 16, color: Colors.white.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.totalSets} sets',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
