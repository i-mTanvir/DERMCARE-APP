import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<AuthState>? _authSubscription;
  String? _cachedName;
  String? _cachedProfileImage;
  String _cachedRole = 'patient';

  AuthService() {
    _hydrateProfileCache();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((_) {
      _hydrateProfileCache();
    });
  }

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isDoctor => role == 'doctor';
  String get userId => currentUser?.id ?? '';

  String get displayName {
    final meta = currentUser?.userMetadata;
    final value = (meta?['name'] ?? _cachedName ?? '').toString().trim();
    return value.isEmpty ? 'User' : value;
  }

  String get email => currentUser?.email ?? '';

  String get role {
    final meta = currentUser?.userMetadata;
    final value = (meta?['role'] ?? _cachedRole).toString().trim().toLowerCase();
    return value == 'doctor' ? 'doctor' : 'patient';
  }

  String get profileImage {
    final meta = currentUser?.userMetadata;
    return (meta?['profile_image'] ?? _cachedProfileImage ?? '').toString();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _hydrateProfileCache() async {
    if (userId.isEmpty) {
      _cachedName = null;
      _cachedProfileImage = null;
      _cachedRole = 'patient';
      notifyListeners();
      return;
    }

    final profile = await getUserProfile(userId);
    if (profile != null) {
      _cachedName = (profile['name'] ?? '').toString();
      _cachedProfileImage = (profile['profile_image'] ?? '').toString();
      _cachedRole = (profile['role'] ?? 'patient').toString();
    }

    await _ensureUserProfileRow();
    notifyListeners();
  }

  Future<void> _ensureUserProfileRow() async {
    if (userId.isEmpty) return;

    final profile = await getUserProfile(userId);
    if (profile != null) return;

    await _supabase.from('users').upsert({
      'id': userId,
      'name': displayName,
      'email': email,
      'phone': '',
      'profile_image': profileImage,
      'role': role,
    }, onConflict: 'id');
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'patient',
    String licenseNumber = '',
    String designation = '',
    String specialist = '',
    String gender = 'male',
    int age = 0,
    String description = '',
  }) async {
    try {
      final trimmedName = name.trim();
      final trimmedEmail = email.trim();
      final normalizedRole = role.toLowerCase() == 'doctor' ? 'doctor' : 'patient';

      final response = await _supabase.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          'name': trimmedName,
          'profile_image': '',
          'role': normalizedRole,
        },
      );

      final user = response.user;
      if (user == null) return 'Sign up failed';

      await _supabase.from('users').upsert({
        'id': user.id,
        'name': trimmedName,
        'email': trimmedEmail,
        'phone': '',
        'profile_image': '',
        'role': normalizedRole,
      }, onConflict: 'id');

      if (normalizedRole == 'doctor') {
        await _supabase.from('doctors').upsert({
          'id': user.id,
          'user_id': user.id,
          'name': trimmedName,
          'specialty': specialist.trim(),
          'designation': designation.trim(),
          'license_number': licenseNumber.trim(),
          'gender': gender.trim().toLowerCase(),
          'age': age,
          'about': description.trim(),
          'image_url': '',
          'rating': 0,
          'experience': 0,
          'available_days': <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        }, onConflict: 'id');
      }

      _cachedName = trimmedName;
      _cachedProfileImage = '';
      _cachedRole = normalizedRole;
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit')) {
        final loginError = await login(email: email, password: password);
        if (loginError == null) {
          final normalizedRole = role.toLowerCase() == 'doctor' ? 'doctor' : 'patient';
          await _supabase.from('users').upsert({
            'id': userId,
            'name': name.trim(),
            'email': email.trim(),
            'phone': '',
            'profile_image': profileImage,
            'role': normalizedRole,
          }, onConflict: 'id');

          if (normalizedRole == 'doctor') {
            await _supabase.from('doctors').upsert({
              'id': userId,
              'user_id': userId,
              'name': name.trim(),
              'specialty': specialist.trim(),
              'designation': designation.trim(),
              'license_number': licenseNumber.trim(),
              'gender': gender.trim().toLowerCase(),
              'age': age,
              'about': description.trim(),
              'image_url': profileImage,
            }, onConflict: 'id');
          }
          return null;
        }
      }
      return e.message;
    } catch (_) {
      return 'Sign up failed';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await _ensureUserProfileRow();
      await _hydrateProfileCache();
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Login failed';
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _cachedName = null;
    _cachedProfileImage = null;
    _cachedRole = 'patient';
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final row = await _supabase.from('users').select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> getDoctorProfile() async {
    if (userId.isEmpty) return null;
    final row = await _supabase.from('doctors').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<void> updateDoctorProfile({
    required String designation,
    required String specialist,
    required String gender,
    required int age,
    required String description,
    required String licenseNumber,
  }) async {
    if (userId.isEmpty) throw StateError('Not logged in');

    await _supabase.from('doctors').upsert({
      'id': userId,
      'user_id': userId,
      'name': displayName,
      'specialty': specialist.trim(),
      'designation': designation.trim(),
      'license_number': licenseNumber.trim(),
      'gender': gender.trim().toLowerCase(),
      'age': age,
      'about': description.trim(),
      'image_url': profileImage,
    }, onConflict: 'id');
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    String? profileImageUrl,
  }) async {
    if (userId.isEmpty) throw StateError('Not logged in');

    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    final mergedProfileImage = (profileImageUrl ?? profileImage).trim();

    final currentData = Map<String, dynamic>.from(currentUser?.userMetadata ?? <String, dynamic>{});
    currentData['name'] = trimmedName;
    currentData['profile_image'] = mergedProfileImage;
    currentData['role'] = role;

    await _supabase.auth.updateUser(UserAttributes(data: currentData));
    await _supabase.from('users').upsert({
      'id': userId,
      'name': trimmedName,
      'email': email,
      'phone': trimmedPhone,
      'profile_image': mergedProfileImage,
      'role': role,
    }, onConflict: 'id');

    if (role == 'doctor') {
      await _supabase.from('doctors').update({
        'name': trimmedName,
        'image_url': mergedProfileImage,
      }).eq('id', userId);
    }

    _cachedName = trimmedName;
    _cachedProfileImage = mergedProfileImage;
    notifyListeners();
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String fileExt,
  }) async {
    if (userId.isEmpty) throw StateError('Not logged in');

    final extension = fileExt.trim().toLowerCase().replaceAll('.', '');
    final safeExt = extension.isEmpty ? 'jpg' : extension;
    final objectPath = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    await _supabase.storage.from('profile-images').uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final imageUrl = _supabase.storage.from('profile-images').getPublicUrl(objectPath);

    await updateProfile(
      name: displayName,
      phone: ((await getUserProfile(userId))?['phone'] ?? '').toString(),
      profileImageUrl: imageUrl,
    );

    return imageUrl;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw StateError('No logged-in user');
    }

    await _supabase.auth.signInWithPassword(
      email: user.email!,
      password: currentPassword,
    );
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
