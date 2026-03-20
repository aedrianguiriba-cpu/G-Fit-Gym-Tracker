import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user.dart';
import '../models/workout.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';
import '../models/notification.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_service.dart';
import '../services/workout_service.dart';

/// Debug logging utility - only prints in debug mode
void _log(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class AppState extends ChangeNotifier {
  late final SupabaseAuthService _authService;
  
  User? _currentUser;
  Workout? _activeWorkout;
  final List<AppNotification> _notifications = [];
  final List<Exercise> _cachedExercises = [];
  final List<WorkoutProgram> _workoutPrograms = [];
  final List<Workout> _workoutHistory = [];
  String? _lastError;
  bool _isLoadingPrograms = false;
  bool _isLoadingWorkouts = false;
  
  AppState() {
    _authService = SupabaseAuthService(SupabaseService.getClient());
  }
  
  User? get currentUser => _currentUser;
  Workout? get activeWorkout => _activeWorkout;
  bool get isLoggedIn => _currentUser != null;
  bool get hasActiveWorkout => _activeWorkout != null;
  String? get lastError => _lastError;
  List<WorkoutProgram> get workoutPrograms => List.unmodifiable(_workoutPrograms);
  bool get isLoadingPrograms => _isLoadingPrograms;
  bool get isLoadingWorkouts => _isLoadingWorkouts;

  // Authentication
  Future<bool> login(String email, String password) async {
    final result = await _authService.login(email, password);
    if (result.isSuccess) {
      _currentUser = result.value;
      _lastError = null;
      
      // Load exercises and workouts
      await refreshExercises();
      await refreshWorkouts();
      
      notifyListeners();
      return true;
    } else {
      _lastError = result.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String email, String name, String password) async {
    final result = await _authService.signup(email, name, password);
    if (result.isSuccess) {
      _currentUser = result.value;
      _lastError = null;
      
      // Load exercises
      await refreshExercises();
      
      notifyListeners();
      return true;
    } else {
      _lastError = result.error;
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    await _authService.logout();
    _currentUser = null;
    _activeWorkout = null;
    _lastError = null;
    notifyListeners();
  }

  // Exercises
  List<Exercise> get exercises => List.unmodifiable(_cachedExercises);
  
  Future<void> refreshExercises() async {
    try {
      final exercises = await _authService.getGlobalExercises();
      _log('✅ Fetched ${exercises.length} exercises from Supabase');
      _cachedExercises.clear();
      for (var ex in exercises) {
        try {
          _cachedExercises.add(Exercise.fromJson(ex));
        } catch (parseError) {
          _log('⚠️ Error parsing exercise: $parseError');
          _log('   Raw data: $ex');
        }
      }
      _log('✅ Cached ${_cachedExercises.length} exercises');
      notifyListeners();
    } catch (error) {
      _log('❌ Error refreshing exercises: $error');
    }
  }

  // Workout Programs
  Future<void> loadWorkoutPrograms() async {
    try {
      _isLoadingPrograms = true;
      notifyListeners();
      
      final programs = await WorkoutService.fetchWorkoutPrograms();
      _workoutPrograms.clear();
      _workoutPrograms.addAll(programs);
      
      notifyListeners();
    } catch (error) {
      _log('Error loading workout programs: $error');
      _lastError = error.toString();
      notifyListeners();
    } finally {
      _isLoadingPrograms = false;
      notifyListeners();
    }
  }

  Future<List<WorkoutProgram>> getWorkoutsByDifficulty(
      DifficultyLevel difficulty) async {
    try {
      return await WorkoutService.fetchProgramsByDifficulty(difficulty);
    } catch (error) {
      _log('Error fetching programs by difficulty: $error');
      return [];
    }
  }

  Future<List<WorkoutProgram>> searchWorkouts(String query) async {
    try {
      return await WorkoutService.searchPrograms(query);
    } catch (error) {
      _log('Error searching programs: $error');
      return [];
    }
  }
  
  List<Exercise> searchExercises(String query) {
    return _cachedExercises
        .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<Exercise> getExercisesByMuscleGroup(MuscleGroup muscle) {
    return _cachedExercises.where((e) => e.primaryMuscle == muscle).toList();
  }

  // Workouts
  Future<void> refreshWorkouts() async {
    if (_currentUser == null) {
      _log('❌ Cannot refresh workouts: currentUser is null');
      return;
    }
    
    try {
      _isLoadingWorkouts = true;
      notifyListeners();
      
      _log('📥 Refreshing workouts for user: ${_currentUser!.id}');
      final workoutMaps = await _authService.getUserWorkouts(_currentUser!.id);
      
      _log('   📊 Received ${workoutMaps.length} raw workout records from database');
      
      _workoutHistory.clear();
      for (var workoutMap in workoutMaps) {
        try {
          _log('   🔄 Processing workout: ${workoutMap['id']}');
          
          // Fetch full details including exercises and sets
          final fullDetails = await _authService.getWorkoutDetails(workoutMap['id']);
          
          if (fullDetails != null) {
            // Parse the full workout with exercises
            final workout = Workout.fromJson(fullDetails);
            _workoutHistory.add(workout);
            _log('      ✅ Added to history with ${workout.exercises.length} exercises');
          } else {
            _log('      ⚠️ Could not fetch full details');
          }
        } catch (parseError) {
          _log('   ⚠️ Error processing workout: $parseError');
          _log('      Raw data: $workoutMap');
        }
      }
      
      _log('✅ Refreshed ${_workoutHistory.length} workouts successfully');
      _isLoadingWorkouts = false;
      notifyListeners();
    } catch (error) {
      _log('❌ Error refreshing workouts: $error');
      _isLoadingWorkouts = false;
      notifyListeners();
    }
  }

  List<Workout> getWorkoutHistory() {
    return List.unmodifiable(_workoutHistory);
  }

  List<Workout> getWorkoutTemplates() {
    return [];
  }

  /// Set active workout without creating in database yet
  /// Used when preparing a workout before user clicks Start
  void setActiveWorkout(Workout workout) {
    _activeWorkout = workout;
    notifyListeners();
  }

  Future<void> startWorkout(Workout workout) async {
    try {
      _activeWorkout = workout;
      if (_currentUser != null) {
        // Create workout in Supabase with the client-generated ID
        final workoutId = await _authService.createWorkout(
          _currentUser!.id,
          workout.name,
          description: workout.name,
          startTime: workout.startTime,
          workoutId: workout.id, // Pass the client-generated UUID
        );
        if (workoutId != null) {
          _activeWorkout = workout.copyWith(id: workoutId);
        }
      }
      notifyListeners();
    } catch (error) {
      _log('Error starting workout: $error');
      _activeWorkout = workout;
      notifyListeners();
    }
  }

  Future<void> updateActiveWorkout(Workout workout) async {
    try {
      _activeWorkout = workout;
      // Update workout in Supabase
      await _authService.updateWorkout(
        workout.id,
        workout.name,
        description: workout.name,
        startTime: workout.startTime,
        endTime: workout.endTime,
        isCompleted: workout.isCompleted,
      );
      notifyListeners();
    } catch (error) {
      _log('Error updating workout: $error');
      notifyListeners();
    }
  }

  Future<void> finishWorkout() async {
    if (_activeWorkout == null) return;
    try {
      final workout = _activeWorkout!;
      final now = DateTime.now();
      
      _log('⏱️ Finishing workout: ${workout.id}');
      _log('   Start time: ${workout.startTime}');
      _log('   End time: $now');
      
      // Update workout in Supabase as completed
      final updated = await _authService.updateWorkout(
        workout.id,
        workout.name,
        description: workout.name,
        startTime: workout.startTime,
        endTime: now,
        isCompleted: true,
      );
      
      if (updated) {
        _log('✅ Workout marked as completed in database');
      } else {
        _log('❌ Failed to update workout in database');
      }
      
      // Add completion notification
      final duration = now.difference(workout.startTime);
      final minutes = duration.inMinutes;
      addNotification(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Workout Completed! 🎉',
          message: 'Great job! You completed ${workout.name} in $minutes minutes.',
          type: NotificationType.workout,
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
      
      _activeWorkout = null;
      
      // Refresh workout history to show the completed workout
      await refreshWorkouts();
      
      notifyListeners();
    } catch (error) {
      _log('Error finishing workout: $error');
      _activeWorkout = null;
      notifyListeners();
    }
  }

  Future<void> cancelWorkout() async {
    if (_activeWorkout == null) return;
    try {
      // Delete workout from Supabase
      await _authService.deleteWorkout(_activeWorkout!.id);
      _activeWorkout = null;
      notifyListeners();
    } catch (error) {
      _log('Error canceling workout: $error');
      _activeWorkout = null;
      notifyListeners();
    }
  }

  /// Add exercise to active workout and save to database
  Future<bool> addExerciseToWorkout(String workoutId, String exerciseId, int suggestedSets, int suggestedReps) async {
    try {
      _log('🔍 Checking if workout exists: $workoutId');
      
      // Check if workout exists in database
      final workoutExists = await _authService.workoutExists(workoutId);
      _log('   Workout exists: $workoutExists');
      
      if (!workoutExists) {
        _log('📝Workout not in database, creating it now...');
        _log('   User ID: ${_currentUser?.id}');
        _log('   Workout name: ${_activeWorkout?.name}');
        _log('   Start time: ${_activeWorkout?.startTime}');
        
        if (_currentUser == null || _activeWorkout == null) {
          _log('❌ Cannot create workout: currentUser or activeWorkout is null');
          return false;
        }
        
        final createdId = await _authService.createWorkout(
          _currentUser!.id,
          _activeWorkout!.name,
          description: _activeWorkout!.name,
          startTime: _activeWorkout!.startTime,
          workoutId: workoutId,
        );
        
        if (createdId == null) {
          _log('❌ Failed to create workout in database');
          return false;
        }
        
        _log('✅ Workout created successfully: $createdId');
        
        // Wait a moment to ensure database is updated
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Verify it was created
        final verifyExists = await _authService.workoutExists(workoutId);
        _log('   Verification - workout now exists: $verifyExists');
      }
      
      final saved = await _authService.addWorkoutExercise(
        workoutId,
        exerciseId,
        suggestedSets,
        suggestedReps,
      );
      if (saved) {
        _log('✅ Exercise added to workout in database');
      }
      return saved;
    } catch (error) {
      _log('❌ Error in addExerciseToWorkout: $error');
      return false;
    }
  }

  /// Save a workout set to database
  Future<bool> saveWorkoutSet(String workoutId, String exerciseId, int setNumber, double weight, int reps) async {
    try {
      final saved = await _authService.saveWorkoutSet(
        workoutId,
        exerciseId,
        setNumber,
        weight,
        reps,
      );
      if (saved) {
        _log('💪 Set saved to database');
      }
      return saved;
    } catch (error) {
      _log('Error saving set: $error');
      return false;
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _authService.deleteWorkout(workoutId);
      notifyListeners();
    } catch (error) {
      _log('Error deleting workout: $error');
      notifyListeners();
    }
  }

  // Statistics
  Map<String, dynamic> getUserStats({int days = 30}) {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      _log('📊 getUserStats - Filtering workouts:');
      _log('   Now: $now');
      _log('   Start date (${days}d ago): $startDate');
      _log('   Total workouts in history: ${_workoutHistory.length}');
      
      // Filter workouts within date range
      final filteredWorkouts = _workoutHistory
          .where((w) {
            final isAfter = w.startTime.isAfter(startDate);
            final isBefore = w.startTime.isBefore(now.add(const Duration(days: 1)));
            _log('   Workout "${w.name}" on ${w.startTime}:');
            _log('      endTime: ${w.endTime}');
            _log('      duration: ${w.duration}');
            _log('      after=$isAfter, before=$isBefore');
            return isAfter && isBefore;
          })
          .toList();
      
      _log('   Filtered workouts (within ${days}d): ${filteredWorkouts.length}');
      
      int totalWorkouts = filteredWorkouts.length;
      int completedWorkouts = filteredWorkouts.where((w) => w.isCompleted).length;
      int totalExercises = filteredWorkouts.fold<int>(0, (sum, w) => sum + w.exercises.length);
      int totalSets = filteredWorkouts.fold<int>(0, (sum, w) => sum + w.totalSets);
      double totalVolume = filteredWorkouts.fold<double>(0, (sum, w) => sum + w.totalVolume);
      
      // Calculate total duration
      Duration totalDuration = Duration.zero;
      for (var workout in filteredWorkouts) {
        totalDuration += workout.duration;
      }
      
      _log('   📈 Final stats:');
      _log('      Workouts: $totalWorkouts');
      _log('      Completed: $completedWorkouts');
      _log('      Total duration: $totalDuration');
      _log('      Total volume: $totalVolume kg');
      _log('      Total sets: $totalSets');
      
      return {
        'totalWorkouts': totalWorkouts,
        'workoutCount': totalWorkouts,
        'completedWorkouts': completedWorkouts,
        'exerciseCount': totalExercises,
        'totalSets': totalSets,
        'setCount': totalSets,
        'totalVolume': totalVolume,
        'totalDuration': totalDuration,
        'averageVolume': totalWorkouts > 0 ? totalVolume / totalWorkouts : 0,
      };
    } catch (error) {
      _log('❌ Error calculating stats: $error');
      return {
        'totalWorkouts': 0,
        'workoutCount': 0,
        'completedWorkouts': 0,
        'exerciseCount': 0,
        'totalSets': 0,
        'setCount': 0,
        'totalVolume': 0,
        'totalDuration': Duration.zero,
        'averageVolume': 0,
      };
    }
  }

  // Notifications
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  
  int get unreadNotificationCount => 
      _notifications.where((n) => !n.isRead).length;



  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  Future<void> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      _log('📸 Uploading profile picture for user: $userId');
      _log('   File size: ${imageFile.lengthSync()} bytes');
      _log('   File path: ${imageFile.path}');
      
      // Debug: Check Supabase session
      final session = _authService.supabase.auth.currentSession;
      _log('   Session exists: ${session != null}');
      _log('   Session user: ${session?.user.id}');
      
      // Upload image to Supabase storage
      final fileName = 'profile_$userId.jpg';
      
      _log('   Attempting upload to bucket: avatars/$fileName');
      
      await _authService.supabase.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      
      // Get public URL
      final publicUrl = _authService.supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);
      
      _log('🖼️ Image uploaded. Public URL: $publicUrl');
      
      // Update user profile with avatar URL
      await _authService.supabase
          .from('users')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);
      
      // Update local state
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(avatarUrl: publicUrl);
        notifyListeners();
      }
      
      _log('✅ Profile picture updated successfully');
    } catch (error) {
      _log('❌ Error uploading profile picture: $error');
      _log('   Error type: ${error.runtimeType}');
      rethrow;
    }
  }

  // Settings Management
  /// Get user preferences from local storage
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'notificationsEnabled': prefs.getBool('notificationsEnabled') ?? true,
        'workoutReminders': prefs.getBool('workoutReminders') ?? true,
        'achievementNotifications': prefs.getBool('achievementNotifications') ?? true,
      };
    } catch (error) {
      _log('❌ Error loading preferences: $error');
      return {
        'notificationsEnabled': true,
        'workoutReminders': true,
        'achievementNotifications': true,
      };
    }
  }

  /// Save user preferences to local storage
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (preferences.containsKey('notificationsEnabled')) {
        await prefs.setBool('notificationsEnabled', preferences['notificationsEnabled']);
      }
      if (preferences.containsKey('workoutReminders')) {
        await prefs.setBool('workoutReminders', preferences['workoutReminders']);
      }
      if (preferences.containsKey('achievementNotifications')) {
        await prefs.setBool('achievementNotifications', preferences['achievementNotifications']);
      }
      
      _log('✅ Preferences saved');
    } catch (error) {
      _log('❌ Error saving preferences: $error');
    }
  }

  /// Update user profile (name, age, gender)
  Future<void> updateUserProfile({
    String? name,
    int? age,
    String? gender,
  }) async {
    try {
      if (_currentUser == null) throw Exception('User not logged in');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;

      await _authService.supabase
          .from('users')
          .update(updates)
          .eq('id', _currentUser!.id);

      // Update local user
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          name: name ?? _currentUser!.name,
          age: age ?? _currentUser!.age,
          gender: gender ?? _currentUser!.gender,
        );
        notifyListeners();
      }

      _log('✅ Profile updated successfully');
    } catch (error) {
      _log('❌ Error updating profile: $error');
      rethrow;
    }
  }

  /// Update user password
  Future<void> updateUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) throw Exception('User not logged in');

      // Verify current password by attempting to re-authenticate
      final loginResult = await _authService.login(
        _currentUser!.email,
        currentPassword,
      );

      if (!loginResult.isSuccess) {
        throw Exception('Current password is incorrect');
      }

      // Hash the new password (same as signup)
      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      // Update password in database
      await _authService.supabase
          .from('users')
          .update({'password_hash': hashedPassword})
          .eq('id', _currentUser!.id);

      _log('✅ Password updated successfully');
    } catch (error) {
      _log('❌ Error updating password: $error');
      rethrow;
    }
  }
}

