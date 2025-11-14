import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/notification.dart';
import '../services/mock_data_service.dart';

class AppState extends ChangeNotifier {
  final MockDataService _dataService = MockDataService();
  
  User? _currentUser;
  Workout? _activeWorkout;
  final List<AppNotification> _notifications = [];
  
  User? get currentUser => _currentUser;
  Workout? get activeWorkout => _activeWorkout;
  bool get isLoggedIn => _currentUser != null;
  bool get hasActiveWorkout => _activeWorkout != null;

  // Authentication
  Future<bool> login(String email, String password) async {
    final user = await _dataService.login(email, password);
    if (user != null) {
      _currentUser = user;
      _dataService.initializeSampleData(user.id);
      _initializeMockNotifications();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signup(String email, String name, String password) async {
    final user = await _dataService.signup(email, name, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    _activeWorkout = null;
    _dataService.logout();
    notifyListeners();
  }

  // Exercises
  List<Exercise> get exercises => _dataService.exercises;
  
  List<Exercise> searchExercises(String query) {
    return _dataService.searchExercises(query);
  }

  List<Exercise> getExercisesByMuscleGroup(MuscleGroup muscle) {
    return _dataService.getExercisesByMuscleGroup(muscle);
  }

  // Workouts
  List<Workout> getWorkoutHistory() {
    if (_currentUser == null) return [];
    return _dataService.getWorkoutHistory(_currentUser!.id);
  }

  List<Workout> getWorkoutTemplates() {
    if (_currentUser == null) return [];
    return _dataService.getWorkoutTemplates(_currentUser!.id);
  }

  Future<void> startWorkout(Workout workout) async {
    _activeWorkout = workout;
    if (!workout.isTemplate) {
      await _dataService.createWorkout(workout);
    }
    notifyListeners();
  }

  Future<void> updateActiveWorkout(Workout workout) async {
    _activeWorkout = workout;
    await _dataService.updateWorkout(workout);
    notifyListeners();
  }

  Future<void> finishWorkout() async {
    if (_activeWorkout != null) {
      final completedWorkout = _activeWorkout!.copyWith(
        endTime: DateTime.now(),
        isCompleted: true,
      );
      await _dataService.updateWorkout(completedWorkout);
      
      // Add completion notification
      final duration = completedWorkout.endTime!.difference(completedWorkout.startTime);
      final minutes = duration.inMinutes;
      addNotification(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Workout Completed! 🎉',
          message: 'Great job! You completed ${completedWorkout.name} in $minutes minutes.',
          type: NotificationType.workout,
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
      
      _activeWorkout = null;
      notifyListeners();
    }
  }

  Future<void> cancelWorkout() async {
    if (_activeWorkout != null) {
      await _dataService.deleteWorkout(_activeWorkout!.id);
      _activeWorkout = null;
      notifyListeners();
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _dataService.deleteWorkout(workoutId);
    notifyListeners();
  }

  // Statistics
  Map<String, dynamic> getUserStats({int days = 30}) {
    if (_currentUser == null) return {};
    return _dataService.getUserStats(_currentUser!.id, days: days);
  }

  // Notifications
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  
  int get unreadNotificationCount => 
      _notifications.where((n) => !n.isRead).length;

  void _initializeMockNotifications() {
    _notifications.clear();
    _notifications.addAll([
      AppNotification(
        id: '1',
        title: 'Workout Completed! 🎉',
        message: 'Great job! You completed your Push Day workout in 45 minutes.',
        type: NotificationType.workout,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AppNotification(
        id: '2',
        title: 'New Achievement Unlocked! 🏆',
        message: 'You\'ve completed 10 workouts this month. Keep it up!',
        type: NotificationType.achievement,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
      ),
      AppNotification(
        id: '3',
        title: 'Time to Work Out! 💪',
        message: 'It\'s leg day! Don\'t skip it.',
        type: NotificationType.reminder,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: '4',
        title: 'Personal Record! 🔥',
        message: 'You lifted 225 lbs on Bench Press - that\'s a new PR!',
        type: NotificationType.achievement,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AppNotification(
        id: '5',
        title: 'Rest Day Reminder',
        message: 'Your body needs recovery. Take it easy today!',
        type: NotificationType.reminder,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ]);
  }

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
}
