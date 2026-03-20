import '../models/user.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Mock users database
  final List<User> _users = [];

  // Mock exercises library
  final List<Exercise> _exercises = [];

  // Mock workout history
  final List<Workout> _workouts = [];

  // Current user
  User? _currentUser;

  // Getters
  User? get currentUser => _currentUser;
  List<Exercise> get exercises => List.unmodifiable(_exercises);
  
  List<Workout> getWorkoutHistory(String userId) {
    return _workouts
        .where((w) => w.userId == userId && w.isCompleted)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  List<Workout> getWorkoutTemplates(String userId) {
    return _workouts.where((w) => w.userId == userId && w.isTemplate).toList();
  }

  // Authentication
  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    
    try {
      final user = _users.firstWhere(
        (u) => u.email == email,
      );
      _currentUser = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> signup(String email, String name, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    
    // Check if email already exists
    if (_users.any((u) => u.email == email)) {
      return null;
    }

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      joinDate: DateTime.now(),
    );

    _users.add(newUser);
    _currentUser = newUser;
    return newUser;
  }

  void logout() {
    _currentUser = null;
  }

  // Exercises
  List<Exercise> searchExercises(String query) {
    if (query.isEmpty) return exercises;
    
    return exercises.where((e) {
      return e.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Exercise> getExercisesByMuscleGroup(MuscleGroup muscle) {
    return exercises.where((e) => e.primaryMuscle == muscle).toList();
  }

  Exercise? getExerciseById(String id) {
    try {
      return exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Workouts
  Future<String> createWorkout(Workout workout) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _workouts.add(workout);
    return workout.id;
  }

  Future<void> updateWorkout(Workout workout) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout;
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _workouts.removeWhere((w) => w.id == workoutId);
  }

  Workout? getWorkoutById(String id) {
    try {
      return _workouts.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  // Statistics
  Map<String, dynamic> getUserStats(String userId, {int days = 30}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final recentWorkouts = _workouts.where((w) =>
      w.userId == userId &&
      w.isCompleted &&
      w.startTime.isAfter(startDate)
    ).toList();

    final totalWorkouts = recentWorkouts.length;
    final totalVolume = recentWorkouts.fold<double>(
      0.0,
      (sum, w) => sum + w.totalVolume,
    );
    final totalSets = recentWorkouts.fold(0, (sum, w) => sum + w.totalSets);
    final totalDuration = recentWorkouts.fold(
      Duration.zero,
      (sum, w) => sum + w.duration,
    );

    // Calculate workout frequency
    final workoutsByDate = <String, int>{};
    for (var workout in recentWorkouts) {
      final dateKey = workout.startTime.toIso8601String().split('T')[0];
      workoutsByDate[dateKey] = (workoutsByDate[dateKey] ?? 0) + 1;
    }

    return {
      'totalWorkouts': totalWorkouts,
      'totalVolume': totalVolume,
      'totalSets': totalSets,
      'totalDuration': totalDuration,
      'averageWorkoutDuration': totalWorkouts > 0
          ? totalDuration ~/ totalWorkouts
          : Duration.zero,
      'workoutsByDate': workoutsByDate,
    };
  }
}
