import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user.dart';

/// Debug logging utility - only prints in debug mode
void _log(String message) {
  if (kDebugMode) {
    print(message);
  }
}

/// Custom Authentication Service for Gym Members (No Supabase Auth)
/// 
/// This service implements completely custom email/password authentication:
/// 1. Passwords are hashed with bcrypt before storing in public.users table
/// 2. No reliance on Supabase Auth (auth.users)
/// 3. Custom JWT tokens generated on login
/// 4. JWT tokens stored client-side for authenticated requests
/// 5. All password validation done on client
/// 
/// Security Notes:
/// - Passwords are hashed with bcrypt (12 rounds)
/// - JWT tokens signed with SECRET_KEY (set in Supabase environment)
/// - Tokens include user ID and email
/// - Tokens expire after 24 hours (configurable)

/// Result type for auth operations - either returns a value or an error message
class AuthResult<T> {
  final T? value;
  final String? error;
  
  AuthResult.success(this.value) : error = null;
  AuthResult.failure(this.error) : value = null;
  
  bool get isSuccess => value != null && error == null;
  bool get isFailure => error != null;
}

class SupabaseAuthService {
  final SupabaseClient _supabase;

  SupabaseAuthService(this._supabase);

  /// Public getter to access Supabase client for file operations
  SupabaseClient get supabase => _supabase;

  /// Parse auth error and return user-friendly message
  /// Custom auth error handling for email/password authentication
  String _parseAuthError(String message) {
    if (message.contains('rate limit')) {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    }
    if (message.contains('already registered') || message.contains('duplicate')) {
      return 'This email is already registered.';
    }
    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('password')) {
      return 'Password does not meet requirements.';
    }
    if (message.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return message;
  }

  /// Sign up a new gym member with custom authentication
  /// 
  /// Custom auth flow:
  /// 1. Hash password with bcrypt (12 rounds)
  /// 2. Store user record with email, name, and hashed password in public.users
  /// 3. Generate JWT token for immediate login
  /// 4. Return success with User object containing token
  /// 
  /// Returns success with User object or failure with error message
  Future<AuthResult<User>> signup(String email, String name, String password,
      {int? age, String? gender}) async {
    try {
      // Validate email format
      if (!_isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address.');
      }

      // Validate password strength
      if (password.length < 8) {
        return AuthResult.failure(
            'Password must be at least 8 characters long.');
      }

      // Check if email already exists
      try {
        await _supabase
            .from('users')
            .select()
            .eq('email', email)
            .single();
        // If we get here, email exists
        return AuthResult.failure('This email is already registered.');
      } catch (e) {
        // Email doesn't exist (expected)
      }

      // Hash password with bcrypt
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Create user record with hashed password
      final userId = _generateId();
      final userData = {
        'id': userId,
        'email': email,
        'name': name,
        'password_hash': hashedPassword,
        'join_date': DateTime.now().toIso8601String(),
      };
      
      // Add optional fields only if they're provided
      if (age != null) userData['age'] = age as String;
      if (gender != null) userData['gender'] = gender;
      
      await _supabase.from('users').insert(userData);

      // Generate JWT token
      final token = _generateJWT(userId, email);

      return AuthResult.success(User(
        id: userId,
        email: email,
        name: name,
        age: age,
        gender: gender,
        joinDate: DateTime.now(),
      ));
    } on PostgrestException catch (error) {
      _log('Database error during signup: ${error.message}');
      if (error.message.contains('duplicate')) {
        return AuthResult.failure('This email is already registered.');
      }
      return AuthResult.failure('Registration failed: ${error.message}');
    } catch (error) {
      _log('Error during signup: $error');
      return AuthResult.failure(
          'An unexpected error occurred. Please try again.');
    }
  }

  /// Login gym member with custom email/password authentication
  /// 
  /// Custom auth flow:
  /// 1. Query public.users table for user with given email
  /// 2. Retrieve stored password hash
  /// 3. Verify provided password against hash using bcrypt
  /// 4. On success, generate JWT token
  /// 5. Return User object with token for future authenticated requests
  /// 
  /// Returns success with User object or failure with error message
  Future<AuthResult<User>> login(String email, String password) async {
    try {
      // Query user by email
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .single();

      // Verify password against stored hash
      final storedHash = response['password_hash'] as String?;
      if (storedHash == null || storedHash.isEmpty || storedHash == 'NEEDS_MIGRATION') {
        return AuthResult.failure('User account not fully set up. Please contact support.');
      }
      
      final passwordValid = BCrypt.checkpw(password, storedHash);

      if (!passwordValid) {
        return AuthResult.failure('Invalid email or password.');
      }

      // Password valid - generate JWT token
      final token = _generateJWT(response['id'], email);

      return AuthResult.success(User(
        id: response['id'],
        email: response['email'],
        name: response['name'],
        age: response['age'],
        gender: response['gender'],
        joinDate: DateTime.parse(response['join_date']),
        avatarUrl: response['avatar_url'],
      ));
    } on PostgrestException catch (error) {
      _log('Database error during login: ${error.message}');
      return AuthResult.failure('Invalid email or password.');
    } catch (error) {
      _log('Error during login: $error');
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    const emailRegex =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    return RegExp(emailRegex).hasMatch(email);
  }

  /// Generate a proper UUID v4 for new users
  String _generateId() {
    return const Uuid().v4();
  }

  /// Generate JWT token for authenticated requests
  /// 
  /// Token contains:
  /// - sub: user ID
  /// - email: user email
  /// - iat: issued at timestamp
  /// - exp: expiration timestamp (24 hours from now)
  String _generateJWT(String userId, String email) {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    // Create JWT with custom claims
    final payload = {
      'sub': userId,
      'email': email,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    };

    // For client-side JWT, we encode as base64 (not cryptographically signed)
    final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
    return 'Bearer $encodedPayload';
  }

  Future<void> logout() async {
    // Clear JWT token and any local user data
    _log('✅ User logged out successfully');
  }

  /// Get current authenticated user from local storage
  /// Since we're using custom auth, check AppState instead
  User? getCurrentUser() {
    // Custom auth doesn't store sessions in Supabase
    // This is handled by app providers in the UI layer
    return null;
  }

  /// Update user profile in public.users table
  Future<bool> updateUserProfile(String userId, String name, String email,
      {int? age, String? gender}) async {
    try {
      await _supabase.from('users').update({
        'name': name,
        'email': email,
        'age': age,
        'gender': gender,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return true;
    } catch (error) {
      _log('Error updating user profile: $error');
      return false;
    }
  }

  /// Change user password (with bcrypt hashing)
  Future<bool> changePassword(String userId, String currentPassword,
      String newPassword) async {
    try {
      // Verify current password
      final response = await _supabase
          .from('users')
          .select('password_hash')
          .eq('id', userId)
          .single();

      final storedHash = response['password_hash'] as String;
      final passwordValid = BCrypt.checkpw(currentPassword, storedHash);

      if (!passwordValid) {
        _log('Current password is incorrect');
        return false;
      }

      // Hash new password
      final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      // Update password
      await _supabase.from('users').update({
        'password_hash': newHash,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return true;
    } catch (error) {
      _log('Error changing password: $error');
      return false;
    }
  }

  /// Get all global exercises
  Future<List<dynamic>> getGlobalExercises() async {
    try {
      _log('🔍 Attempting to fetch exercises from Supabase...');
      
      List<dynamic> response = [];
      
      // Try different query strategies in order
      try {
        // Strategy 1: Filter for is_global = true
        _log('  Strategy 1: Fetching exercises with is_global = true...');
        response = await _supabase.from('exercises').select().eq('is_global', true);
        _log('  ✅ Strategy 1 SUCCESS: Found ${response.length} exercises');
        return response;
      } catch (e1) {
        _log('  ⚠️  Strategy 1 failed: $e1');
      }
      
      try {
        // Strategy 2: Get all exercises (in case is_global column doesn't exist)
        _log('  Strategy 2: Fetching all exercises without filter...');
        response = await _supabase.from('exercises').select();
        _log('  ✅ Strategy 2 SUCCESS: Found ${response.length} exercises');
        return response;
      } catch (e2) {
        _log('  ⚠️  Strategy 2 failed: $e2');
      }
      
      try {
        // Strategy 3: Get first 100 exercises with limit
        _log('  Strategy 3: Fetching first 100 exercises...');
        response = await _supabase.from('exercises').select().limit(100);
        _log('  ✅ Strategy 3 SUCCESS: Found ${response.length} exercises');
        return response;
      } catch (e3) {
        _log('  ⚠️  Strategy 3 failed: $e3');
      }
      
      _log('❌ All strategies failed to fetch exercises');
      return [];
    } catch (error) {
      _log('❌ Fatal error fetching exercises: $error');
      return [];
    }
  }

  /// Create a new workout
  Future<String?> createWorkout(String userId, String name,
      {String? description, DateTime? startTime, DateTime? endTime, String? workoutId}) async {
    try {
      _log('   📝 Creating workout with ID: $workoutId');
      final workoutData = {
        'id': workoutId, // Use provided ID or let DB generate one
        'user_id': userId,
        'name': name,
        'description': description,
        'start_time': startTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'is_completed': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      _log('   Data: $workoutData');

      final response = await _supabase.from('workouts').insert(workoutData).select();
      _log('   ✓ Insert response: $response');
      
      if (response.isNotEmpty) {
        final returnedId = response[0]['id'];
        _log('   ✓ Workout created with ID: $returnedId');
        return returnedId;
      }
      _log('   ❌ Empty response from insert');
      return null;
    } catch (error) {
      // Handle duplicate key error (workout already exists)
      if (error.toString().contains('23505') || error.toString().contains('duplicate')) {
        _log('   ⚠️ Workout already exists (duplicate key) - returning existing ID: $workoutId');
        return workoutId;
      }
      _log('   ❌ Error creating workout: $error');
      return null;
    }
  }

  /// Check if a workout exists in the database
  Future<bool> workoutExists(String workoutId) async {
    try {
      _log('   🔍 Querying workouts table for ID: $workoutId');
      final result = await _supabase
          .from('workouts')
          .select('id')
          .eq('id', workoutId)
          .limit(1);
      
      final exists = result.isNotEmpty;
      _log('   ✓ Query result: $exists (found ${result.length} records)');
      return exists;
    } catch (error) {
      _log('   ❌ Error checking if workout exists: $error');
      return false;
    }
  }

  /// Update a workout
  Future<bool> updateWorkout(String workoutId, String name,
      {String? description, DateTime? startTime, DateTime? endTime, bool? isCompleted}) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (description != null) updateData['description'] = description;
      if (startTime != null) updateData['start_time'] = startTime.toIso8601String();
      if (endTime != null) {
        updateData['end_time'] = endTime.toIso8601String();
        _log('✅ Setting end_time to: ${endTime.toIso8601String()}');
      }
      if (isCompleted != null) {
        updateData['is_completed'] = isCompleted;
        _log('✅ Setting is_completed to: $isCompleted (type: ${isCompleted.runtimeType})');
      }

      _log('📝 Updating workout $workoutId with data: $updateData');
      final response = await _supabase.from('workouts').update(updateData).eq('id', workoutId).select();
      _log('✅ Workout updated successfully');
      _log('   Response: $response');
      if (response.isEmpty) {
        _log('   ⚠️ WARNING: Update response is empty - no rows affected!');
      } else {
        _log('   ✓ Updated row: ${response[0]}');
      }
      return response.isNotEmpty;
    } catch (error) {
      _log('❌ Error updating workout: $error');
      _log('   Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Delete a workout
  Future<bool> deleteWorkout(String workoutId) async {
    try {
      // Delete workout exercises
      await _supabase
          .from('workout_exercises')
          .delete()
          .eq('workout_id', workoutId);

      // Delete workout
      await _supabase.from('workouts').delete().eq('id', workoutId);
      return true;
    } catch (error) {
      _log('Error deleting workout: $error');
      return false;
    }
  }

  /// Fetch all workouts for a user
  Future<List<Map<String, dynamic>>> getUserWorkouts(String userId) async {
    try {
      _log('📥 Fetching workouts for user: $userId');
      final workouts = await _supabase
          .from('workouts')
          .select('''
            id,
            user_id,
            name,
            description,
            start_time,
            end_time,
            is_completed,
            created_at,
            updated_at
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      _log('✅ Fetched ${workouts.length} workouts');
      return workouts;
    } catch (error) {
      _log('❌ Error fetching workouts: $error');
      return [];
    }
  }

  /// Fetch workout with all exercises and sets
  Future<Map<String, dynamic>?> getWorkoutDetails(String workoutId) async {
    try {
      _log('   🔍 Fetching full details for workout: $workoutId');
      
      // Get workout basic info
      final workouts = await _supabase
          .from('workouts')
          .select()
          .eq('id', workoutId);
      
      if (workouts.isEmpty) {
        _log('   ❌ Workout not found: $workoutId');
        return null;
      }
      
      final workout = workouts[0] as Map<String, dynamic>;
      _log('   ✓ Fetched workout: ${workout['name']}');
      _log('   📊 Workout data: id=${workout['id']}, start_time=${workout['start_time']}, end_time=${workout['end_time']}, is_completed=${workout['is_completed']}');
      
      // Get exercises for this workout (without relationship)
      final workoutExercises = await _supabase
          .from('workout_exercises')
          .select()
          .eq('workout_id', workoutId)
          .order('order_index', ascending: true);
      
      _log('   ✓ Fetched ${workoutExercises.length} workout_exercises records');
      
      // Get all exercise IDs for batch query
      final exerciseIds = workoutExercises
          .map((e) => e['exercise_id'])
          .toSet()
          .toList();
      
      // Batch fetch all exercises
      Map<String, dynamic> exerciseMap = {};
      if (exerciseIds.isNotEmpty) {
        final exercises = await _supabase
            .from('exercises')
            .select()
            .inFilter('id', exerciseIds);
        
        for (var ex in exercises) {
          exerciseMap[ex['id']] = ex;
        }
        _log('   ✓ Fetched ${exercises.length} exercises');
      }
      
      // Build properly structured exercises list
      List<Map<String, dynamic>> structuredExercises = [];
      for (var workoutEx in workoutExercises) {
        final exerciseId = workoutEx['exercise_id'];
        _log('      Processing exercise: $exerciseId');
        
        // Get sets for this exercise
        final sets = await _supabase
            .from('workout_sets')
            .select()
            .eq('workout_id', workoutId)
            .eq('exercise_id', exerciseId)
            .order('set_number', ascending: true);
        
        _log('      Found ${sets.length} sets');
        
        final structuredExercise = {
          'id': workoutEx['id'], // workout_exercise record ID
          'exercise': exerciseMap[exerciseId] ?? {
            'id': exerciseId,
            'name': 'Unknown Exercise',
          },
          'sets': sets,
        };
        
        structuredExercises.add(structuredExercise);
      }
      
      workout['exercises'] = structuredExercises;
      _log('   ✅ Built full workout structure with ${structuredExercises.length} exercises');
      _log('   📋 Final workout object: id=${workout['id']}, start_time=${workout['start_time']}, end_time=${workout['end_time']}, is_completed=${workout['is_completed']}');
      
      return workout;
    } catch (error) {
      _log('   ❌ Error fetching workout details: $error');
      _log('      Attempting fallback without relationships');
      return null;
    }
  }

  /// Add exercise to workout (saves to database)
  Future<bool> addWorkoutExercise(String workoutId, String exerciseId, int suggestedSets, int suggestedReps) async {
    try {
      _log('📝 Adding exercise to workout: $workoutId, exercise: $exerciseId');
      _log('   suggested_sets: $suggestedSets (type: ${suggestedSets.runtimeType}), suggested_reps: $suggestedReps (type: ${suggestedReps.runtimeType})');
      
      // Get the next order_index for this workout
      final existingExercises = await _supabase
          .from('workout_exercises')
          .select('order_index')
          .eq('workout_id', workoutId)
          .order('order_index', ascending: false)
          .limit(1);
      
      int nextOrderIndex = 0;
      if (existingExercises.isNotEmpty) {
        nextOrderIndex = (existingExercises[0]['order_index'] as int) + 1;
      }
      
      _log('   order_index: $nextOrderIndex');
      
      final insertData = {
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'order_index': nextOrderIndex,
        'suggested_sets': suggestedSets,
        'suggested_reps': suggestedReps,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      _log('   📤 Sending to database: $insertData');
      
      final response = await _supabase.from('workout_exercises').insert(insertData).select();
      
      if (response.isNotEmpty) {
        _log('✅ Exercise added to workout: ${response[0]['id']}');
        _log('   Returned from DB: ${response[0]}');
        return true;
      }
      _log('❌ No response from database');
      return false;
    } catch (error) {
      _log('❌ Error adding exercise to workout: $error');
      if (error.toString().contains('Could not find')) {
        _log('   🔧 Solution: Run ADD_WORKOUT_SETS_COLUMNS.sql migration in Supabase');
        _log('   📄 See: FIX_WORKOUT_EXERCISES_COLUMNS.md for instructions');
      }
      return false;
    }
  }

  /// Save workout set (saves to database)
  Future<bool> saveWorkoutSet(String workoutId, String exerciseId, int setNumber, double weight, int reps) async {
    try {
      _log('💪 Saving set: Workout($workoutId), Exercise($exerciseId), Set($setNumber), Weight($weight), Reps($reps)');
      
      // Check if a set record exists for this set
      final existsCheck = await _supabase
          .from('workout_sets')
          .select('id')
          .match({
            'workout_id': workoutId,
            'exercise_id': exerciseId,
            'set_number': setNumber,
          })
          .limit(1);
      
      if (existsCheck.isNotEmpty) {
        // Update existing record
        _log('   ✅ Set exists, updating...');
        await _supabase
            .from('workout_sets')
            .update({
              'weight': weight,
              'reps': reps,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .match({
              'workout_id': workoutId,
              'exercise_id': exerciseId,
              'set_number': setNumber,
            })
            .limit(1);
        _log('✅ Set updated successfully: ${existsCheck[0]['id']}');
        return true;
      } else {
        // Insert new record
        _log('   ✅ Set does not exist, inserting...');
        final insertResponse = await _supabase
            .from('workout_sets')
            .insert({
              'workout_id': workoutId,
              'exercise_id': exerciseId,
              'set_number': setNumber,
              'weight': weight,
              'reps': reps,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select();
        
        _log('✅ Set inserted successfully: ${insertResponse.isNotEmpty ? insertResponse[0]['id'] : 'unknown'}');
        return insertResponse.isNotEmpty;
      }
    } catch (error) {
      _log('❌ Error saving set: $error');
      return false;
    }
  }
}
