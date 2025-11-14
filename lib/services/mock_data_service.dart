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
  final List<User> _users = [
    User(
      id: '1',
      email: 'demo@gym.com',
      name: 'Aedrian',
      password: 'password123',
      joinDate: DateTime(2024, 1, 1),
    ),
    User(
      id: '2',
      email: 'john@example.com',
      name: 'John Doe',
      password: 'john123',
      joinDate: DateTime(2024, 2, 15),
    ),
  ];

  // Mock exercises library
  final List<Exercise> _exercises = [
    // Chest exercises
    Exercise(
      id: 'ex1',
      name: 'Barbell Bench Press',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.arms],
      equipment: EquipmentType.barbell,
      instructions: 'Lie on bench, lower bar to chest, press up.',
      videoUrl: 'gRVjAtPip0Y',
    ),
    Exercise(
      id: 'ex2',
      name: 'Dumbbell Incline Press',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.arms],
      equipment: EquipmentType.dumbbell,
      instructions: 'Set bench to 30-45 degrees, press dumbbells overhead.',
      videoUrl: 'SrqOu55lrYU',
    ),
    Exercise(
      id: 'ex3',
      name: 'Cable Chest Fly',
      primaryMuscle: MuscleGroup.chest,
      equipment: EquipmentType.cable,
      instructions: 'Stand between cables, bring handles together in front.',
      videoUrl: 'taI4XduLpTk',
    ),
    Exercise(
      id: 'ex4',
      name: 'Push-ups',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.arms, MuscleGroup.core],
      equipment: EquipmentType.bodyweight,
      instructions: 'Lower body to ground, push back up.',
      videoUrl: 'IODxDxX7oi4',
    ),
    
    // Back exercises
    Exercise(
      id: 'ex5',
      name: 'Barbell Deadlift',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.legs, MuscleGroup.core],
      equipment: EquipmentType.barbell,
      instructions: 'Lift bar from ground to standing position.',
      videoUrl: 'op9kVnSso6Q',
    ),
    Exercise(
      id: 'ex6',
      name: 'Pull-ups',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.arms],
      equipment: EquipmentType.bodyweight,
      instructions: 'Hang from bar, pull chin over bar.',
      videoUrl: 'eGo4IYlbE5g',
    ),
    Exercise(
      id: 'ex7',
      name: 'Barbell Row',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.arms],
      equipment: EquipmentType.barbell,
      instructions: 'Bent over, pull bar to lower chest.',
      videoUrl: 'T3N-TO4reLQ',
    ),
    Exercise(
      id: 'ex8',
      name: 'Lat Pulldown',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.arms],
      equipment: EquipmentType.machine,
      instructions: 'Pull bar down to upper chest.',
      videoUrl: 'CAwf7n6Luuc',
    ),
    
    // Legs exercises
    Exercise(
      id: 'ex9',
      name: 'Barbell Squat',
      primaryMuscle: MuscleGroup.legs,
      secondaryMuscles: [MuscleGroup.core],
      equipment: EquipmentType.barbell,
      instructions: 'Bar on back, squat down, stand back up.',
      videoUrl: 'ultWZbUMPL8',
    ),
    Exercise(
      id: 'ex10',
      name: 'Leg Press',
      primaryMuscle: MuscleGroup.legs,
      equipment: EquipmentType.machine,
      instructions: 'Push platform away with feet.',
      videoUrl: 'IZxyjW7MPJQ',
    ),
    Exercise(
      id: 'ex11',
      name: 'Romanian Deadlift',
      primaryMuscle: MuscleGroup.legs,
      secondaryMuscles: [MuscleGroup.back],
      equipment: EquipmentType.barbell,
      instructions: 'Hinge at hips, lower bar to shins.',
      videoUrl: 'JCXUYuzwNrM',
    ),
    Exercise(
      id: 'ex12',
      name: 'Walking Lunges',
      primaryMuscle: MuscleGroup.legs,
      equipment: EquipmentType.dumbbell,
      instructions: 'Step forward, lower back knee, alternate.',
      videoUrl: 'L8fvypPrzzs',
    ),
    
    // Shoulders exercises
    Exercise(
      id: 'ex13',
      name: 'Overhead Press',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.arms],
      equipment: EquipmentType.barbell,
      instructions: 'Press bar from shoulders to overhead.',
      videoUrl: 'QAQ64hK4Cpo',
    ),
    Exercise(
      id: 'ex14',
      name: 'Dumbbell Lateral Raise',
      primaryMuscle: MuscleGroup.shoulders,
      equipment: EquipmentType.dumbbell,
      instructions: 'Raise dumbbells to sides until parallel.',
      videoUrl: '3VcKaXpzqRo',
    ),
    Exercise(
      id: 'ex15',
      name: 'Face Pulls',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.back],
      equipment: EquipmentType.cable,
      instructions: 'Pull rope to face, separate handles.',
      videoUrl: 'rep-qVOkqgk',
    ),
    
    // Arms exercises
    Exercise(
      id: 'ex16',
      name: 'Barbell Curl',
      primaryMuscle: MuscleGroup.arms,
      equipment: EquipmentType.barbell,
      instructions: 'Curl bar from thighs to shoulders.',
      videoUrl: 'kwG2ipFRgfo',
    ),
    Exercise(
      id: 'ex17',
      name: 'Tricep Dips',
      primaryMuscle: MuscleGroup.arms,
      secondaryMuscles: [MuscleGroup.chest],
      equipment: EquipmentType.bodyweight,
      instructions: 'Lower body between bars, push back up.',
      videoUrl: '2z8JmcrW-As',
    ),
    Exercise(
      id: 'ex18',
      name: 'Hammer Curls',
      primaryMuscle: MuscleGroup.arms,
      equipment: EquipmentType.dumbbell,
      instructions: 'Curl dumbbells with neutral grip.',
      videoUrl: 'TwD-YGVP4Bk',
    ),
    
    // Core exercises
    Exercise(
      id: 'ex19',
      name: 'Plank',
      primaryMuscle: MuscleGroup.core,
      equipment: EquipmentType.bodyweight,
      instructions: 'Hold push-up position on forearms.',
      videoUrl: 'ASdvN_XEl_c',
    ),
    Exercise(
      id: 'ex20',
      name: 'Russian Twists',
      primaryMuscle: MuscleGroup.core,
      equipment: EquipmentType.bodyweight,
      instructions: 'Sit with feet up, twist torso side to side.',
      videoUrl: 'wkD8rjkodUI',
    ),
  ];

  // Mock workout history
  List<Workout> _workouts = [];

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
        (u) => u.email == email && u.password == password,
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
      password: password,
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

  // Initialize with sample data
  void initializeSampleData(String userId) {
    // Add sample workout history
    final sampleWorkout1 = Workout(
      id: 'w1',
      userId: userId,
      name: 'Push Day',
      startTime: DateTime.now().subtract(const Duration(days: 2)),
      endTime: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
      isCompleted: true,
      exercises: [
        WorkoutExercise(
          id: 'we1',
          exercise: exercises[0], // Bench Press
          sets: [
            WorkoutSet(id: 's1', setNumber: 1, weight: 60, reps: 10, isCompleted: true),
            WorkoutSet(id: 's2', setNumber: 2, weight: 70, reps: 8, isCompleted: true),
            WorkoutSet(id: 's3', setNumber: 3, weight: 75, reps: 6, isCompleted: true),
          ],
        ),
        WorkoutExercise(
          id: 'we2',
          exercise: exercises[1], // Incline Press
          sets: [
            WorkoutSet(id: 's4', setNumber: 1, weight: 25, reps: 12, isCompleted: true),
            WorkoutSet(id: 's5', setNumber: 2, weight: 30, reps: 10, isCompleted: true),
            WorkoutSet(id: 's6', setNumber: 3, weight: 30, reps: 8, isCompleted: true),
          ],
        ),
      ],
    );

    final sampleWorkout2 = Workout(
      id: 'w2',
      userId: userId,
      name: 'Leg Day',
      startTime: DateTime.now().subtract(const Duration(days: 4)),
      endTime: DateTime.now().subtract(const Duration(days: 4, hours: -1, minutes: -15)),
      isCompleted: true,
      exercises: [
        WorkoutExercise(
          id: 'we3',
          exercise: exercises[8], // Squat
          sets: [
            WorkoutSet(id: 's7', setNumber: 1, weight: 80, reps: 10, isCompleted: true),
            WorkoutSet(id: 's8', setNumber: 2, weight: 90, reps: 8, isCompleted: true),
            WorkoutSet(id: 's9', setNumber: 3, weight: 100, reps: 6, isCompleted: true),
          ],
        ),
      ],
    );

    _workouts.addAll([sampleWorkout1, sampleWorkout2]);

    // Add sample template
    final template = Workout(
      id: 't1',
      userId: userId,
      name: 'Upper Body Template',
      startTime: DateTime.now(),
      isTemplate: true,
      exercises: [
        WorkoutExercise(
          id: 'wet1',
          exercise: exercises[0], // Bench Press
          sets: [
            WorkoutSet(id: 'st1', setNumber: 1, weight: 60, reps: 10),
            WorkoutSet(id: 'st2', setNumber: 2, weight: 60, reps: 10),
            WorkoutSet(id: 'st3', setNumber: 3, weight: 60, reps: 10),
          ],
        ),
        WorkoutExercise(
          id: 'wet2',
          exercise: exercises[6], // Barbell Row
          sets: [
            WorkoutSet(id: 'st4', setNumber: 1, weight: 50, reps: 10),
            WorkoutSet(id: 'st5', setNumber: 2, weight: 50, reps: 10),
            WorkoutSet(id: 'st6', setNumber: 3, weight: 50, reps: 10),
          ],
        ),
      ],
    );

    _workouts.add(template);
  }
}
