import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';
import 'supabase_service.dart';

/// Debug logging utility - only prints in debug mode
void _log(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class WorkoutService {
  static final SupabaseClient _supabase = SupabaseService.getClient();

  // Fetch all available workout programs
  static Future<List<WorkoutProgram>> fetchWorkoutPrograms() async {
    try {
      final response = await _supabase
          .from('workout_programs')
          .select('*')
          .eq('is_active', true);

      if (response.isEmpty) {
        _log('No workout programs found');
        return [];
      }

      return List<WorkoutProgram>.from(
        (response as List).map((data) => WorkoutProgram.fromJson(data)),
      );
    } catch (error) {
      _log('Error fetching workout programs: $error');
      rethrow;
    }
  }

  // Fetch programs by difficulty level
  static Future<List<WorkoutProgram>> fetchProgramsByDifficulty(
      DifficultyLevel difficulty) async {
    try {
      final response = await _supabase
          .from('workout_programs')
          .select('*')
          .eq('difficulty', difficulty.toString().split('.').last)
          .eq('is_active', true);

      return List<WorkoutProgram>.from(
        (response as List).map((data) => WorkoutProgram.fromJson(data)),
      );
    } catch (error) {
      _log('Error fetching programs by difficulty: $error');
      rethrow;
    }
  }

  // Search workout programs
  static Future<List<WorkoutProgram>> searchPrograms(String query) async {
    try {
      final response = await _supabase
          .from('workout_programs')
          .select('*')
          .ilike('name', '%$query%')
          .eq('is_active', true);

      return List<WorkoutProgram>.from(
        (response as List).map((data) => WorkoutProgram.fromJson(data)),
      );
    } catch (error) {
      _log('Error searching programs: $error');
      rethrow;
    }
  }

  // Get single program with full details
  static Future<WorkoutProgram?> getProgram(String programId) async {
    try {
      final response = await _supabase
          .from('workout_programs')
          .select('*')
          .eq('id', programId)
          .single();

      return WorkoutProgram.fromJson(response);
    } catch (error) {
      _log('Error fetching program: $error');
      rethrow;
    }
  }

  // Save user's favorite programs
  static Future<void> saveFavoriteProgram(
      String userId, String programId) async {
    try {
      await _supabase.from('user_favorite_programs').insert({
        'user_id': userId,
        'program_id': programId,
        'saved_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      if (!error.toString().contains('duplicate')) {
        _log('Error saving favorite: $error');
        rethrow;
      }
    }
  }

  // Get user's favorite programs
  static Future<List<WorkoutProgram>> getUserFavoritePrograms(
      String userId) async {
    try {
      final response = await _supabase
          .from('user_favorite_programs')
          .select('workout_programs(*)')
          .eq('user_id', userId);

      return List<WorkoutProgram>.from(
        (response as List)
            .map((data) => WorkoutProgram.fromJson(data['workout_programs'])),
      );
    } catch (error) {
      _log('Error fetching favorite programs: $error');
      rethrow;
    }
  }

  // Remove favorite
  static Future<void> removeFavoriteProgram(
      String userId, String programId) async {
    try {
      await _supabase
          .from('user_favorite_programs')
          .delete()
          .eq('user_id', userId)
          .eq('program_id', programId);
    } catch (error) {
      _log('Error removing favorite: $error');
      rethrow;
    }
  }

  // Get user's workout history
  static Future<List<Map<String, dynamic>>> getUserWorkoutHistory(
      String userId) async {
    try {
      final response = await _supabase
          .from('user_workouts')
          .select('*')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (error) {
      _log('Error fetching workout history: $error');
      rethrow;
    }
  }

  // Save completed workout
  static Future<String?> saveCompletedWorkout({
    required String userId,
    required String programId,
    required DateTime completedAt,
    required int durationMinutes,
    required List<Map<String, dynamic>> exerciseData,
    String? notes,
  }) async {
    try {
      final response = await _supabase.from('user_workouts').insert({
        'user_id': userId,
        'program_id': programId,
        'completed_at': completedAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'exercise_data': exerciseData,
        'notes': notes,
      }).select();

      if (response.isNotEmpty) {
        return response[0]['id'];
      }
      return null;
    } catch (error) {
      _log('Error saving completed workout: $error');
      rethrow;
    }
  }

  // Get exercise with video details
  static Future<Exercise?> getExerciseWithVideo(String exerciseId) async {
    try {
      final response = await _supabase
          .from('exercises')
          .select('*')
          .eq('id', exerciseId)
          .single();

      return Exercise.fromJson(response);
    } catch (error) {
      _log('Error fetching exercise: $error');
      rethrow;
    }
  }

  // Get all exercises - for local caching
  static Future<List<Exercise>> fetchAllExercises() async {
    try {
      final response =
          await _supabase.from('exercises').select('*').eq('is_deleted', false);

      return List<Exercise>.from(
        (response as List).map((data) => Exercise.fromJson(data)),
      );
    } catch (error) {
      _log('Error fetching exercises: $error');
      rethrow;
    }
  }
}
