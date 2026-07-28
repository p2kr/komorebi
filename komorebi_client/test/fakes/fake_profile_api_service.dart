import 'package:dio/dio.dart';
import 'package:komorebi/src/core/services/api/profile_api_service.dart';
import 'package:komorebi/src/features/profile/profile.dart';

class FakeProfileApiService implements ProfileApiService {
  final List<Profile> profiles = [];

  @override
  Dio get dio => throw UnimplementedError();

  String get baseUrl => "http://fake-server/api/v1";

  @override
  Future<List<Profile>> getAllProfiles() async {
    return List.unmodifiable(profiles);
  }

  @override
  Future<Profile?> getProfile(int id) async {
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<Profile?> getLatestProfile() async {
    if (profiles.isEmpty) return null;
    final sorted = List<Profile>.from(profiles)
      ..sort((a, b) => b.connectedOn.compareTo(a.connectedOn));
    return sorted.first;
  }

  @override
  Future<Profile> addNewProfile(Profile profile) async {
    final newId = profiles.length + 1;
    final created = profile.copyWith(id: newId);
    profiles.removeWhere((p) => p.id == newId);
    profiles.add(created);
    return created;
  }

  @override
  Future<void> deleteProfile(int id) async {
    profiles.removeWhere((p) => p.id == id);
  }

  @override
  Future<Profile> exchangeOAuthToken({
    required String provider,
    required String authCode,
    String? codeVerifier,
    String? redirectUri,
    String? clientId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Profile> verifySandboxProfile(String username) async {
    throw UnimplementedError();
  }
}
