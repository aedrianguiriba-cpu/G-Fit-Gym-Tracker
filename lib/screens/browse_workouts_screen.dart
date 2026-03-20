import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';
import '../widgets/exercise_video_viewer.dart';

class BrowseWorkoutsScreen extends StatefulWidget {
  const BrowseWorkoutsScreen({super.key});

  @override
  State<BrowseWorkoutsScreen> createState() => _BrowseWorkoutsScreenState();
}

class _BrowseWorkoutsScreenState extends State<BrowseWorkoutsScreen> {
  DifficultyLevel? _selectedDifficulty;
  String _searchQuery = '';
  final List<WorkoutProgram> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    // TODO: Load workouts from Supabase through app state
    setState(() {
      _isLoading = false;
    });
  }

  List<WorkoutProgram> _getFilteredWorkouts() {
    var filtered = _workouts;

    if (_selectedDifficulty != null) {
      filtered = filtered
          .where((w) => w.difficulty == _selectedDifficulty)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((w) =>
              w.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              w.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  void _startWorkout(WorkoutProgram program) {
    // TODO: Convert program to workout and start it
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting workout: ${program.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredWorkouts = _getFilteredWorkouts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Programs'),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      backgroundColor: const Color(0xFF0F0F0F),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Search and Filter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search workouts...',
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.grey[800] ?? Colors.grey),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Difficulty Filter
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: _selectedDifficulty == null,
                                onSelected: (selected) {
                                  setState(() =>
                                      _selectedDifficulty = null);
                                },
                              ),
                              const SizedBox(width: 8),
                              ...DifficultyLevel.values.map((difficulty) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text('${difficulty.name[0].toUpperCase()}${difficulty.name.substring(1)}'),
                                    selected:
                                        _selectedDifficulty == difficulty,
                                    onSelected: (selected) {
                                      setState(() => _selectedDifficulty =
                                          selected ? difficulty : null);
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Workouts List
                if (filteredWorkouts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center,
                              size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          const Text(
                            'No workouts found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final workout = filteredWorkouts[index];
                        return _WorkoutCard(
                          workout: workout,
                          onStartPressed: () => _startWorkout(workout),
                        );
                      },
                      childCount: filteredWorkouts.length,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _WorkoutCard extends StatefulWidget {
  final WorkoutProgram workout;
  final VoidCallback onStartPressed;

  const _WorkoutCard({
    required this.workout,
    required this.onStartPressed,
  });

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.workout.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              widget.workout.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.blue,
              ),
              onPressed: () {
                setState(() => _isExpanded = !_isExpanded);
              },
            ),
          ),
          // Metadata
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _MetadataChip(
                  icon: Icons.fitness_center,
                  label: '${widget.workout.exercises.length} exercises',
                ),
                const SizedBox(width: 12),
                _MetadataChip(
                  icon: Icons.schedule,
                  label: '~${widget.workout.estimatedDurationMinutes} min',
                ),
                const SizedBox(width: 12),
                _MetadataChip(
                  icon: Icons.trending_up,
                  label: '${widget.workout.difficulty.name[0].toUpperCase()}${widget.workout.difficulty.name.substring(1)}',
                  backgroundColor: _getDifficultyColor(
                      widget.workout.difficulty),
                ),
              ],
            ),
          ),
          // Expanded Content
          if (_isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Muscles
                  if (widget.workout.targetMuscles.isNotEmpty) ...[
                    const Text(
                      'Target Muscles:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.workout.targetMuscles
                          .map((muscle) => Chip(
                                label: Text(muscle),
                                backgroundColor: Colors.blue[900],
                                labelStyle: const TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Exercises List
                  const Text(
                    'Exercises:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: widget.workout.exercises
                        .map((ex) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex.exercise.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${ex.sets}x${ex.reps}${ex.weight != null ? ' @ ${ex.weight}lbs' : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (ex.exercise.videoUrl != null &&
                                      ex.exercise.videoUrl!.isNotEmpty)
                                    Tooltip(
                                      message: 'Video available',
                                      child: Icon(Icons.video_library,
                                          size: 18,
                                          color: Colors.blue[400]),
                                    ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onStartPressed,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start This Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return Colors.green[800]!;
      case DifficultyLevel.intermediate:
        return Colors.orange[800]!;
      case DifficultyLevel.advanced:
        return Colors.red[800]!;
    }
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? backgroundColor;

  const _MetadataChip({
    required this.icon,
    required this.label,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
