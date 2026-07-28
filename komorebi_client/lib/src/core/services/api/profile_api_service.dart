import 'package:dio/dio.dart';
import 'package:komorebi/src/core/utils/constants.dart';
import 'package:komorebi/src/core/utils/dio.dart';
import 'package:komorebi/src/core/utils/talker.dart';
import 'package:komorebi/src/models/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_api_service.g.dart';

@Riverpod(keepAlive: true)
ProfileApiService profileApiService(Ref ref) {
  return ProfileApiService();
}

class ProfileApiService {
  final Dio _dio = getDioWithLogger(BaseOptions(baseUrl: API_BASE_URL));

  ProfileApiService();

  Dio get dio => _dio;

  /// Fetch all profiles from server
  Future<List<Profile>> getAllProfiles() async {
    try {
      final response = await _dio.get("/getAllProfiles");
      if (response.statusCode == 200 && response.data != null) {
        final dataMap = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};

        final listData = dataMap['data'];
        if (listData is List) {
          return listData
              .map((item) => Profile.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e, t) {
      talker.error("Error in getAllProfiles: ", e, t);
      rethrow;
    }
  }

  /// Fetch profile by id
  Future<Profile?> getProfile(int id) async {
    final profiles = await getAllProfiles();
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Fetch latest created profile
  Future<Profile?> getLatestProfile() async {
    final profiles = await getAllProfiles();
    if (profiles.isEmpty) return null;
    profiles.sort((a, b) => b.connectedOn.compareTo(a.connectedOn));
    return profiles.first;
  }

  /// Add or update profile on server
  Future<Profile> addNewProfile(Profile profile) async {
    try {
      final response = await _dio.post(
        "/addNewProfile",
        data: profile.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dataMap = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};

        final itemData = dataMap['data'];
        if (itemData is Map<String, dynamic>) {
          return Profile.fromJson(itemData);
        }
      }
      throw Exception(
        "Failed to add profile. Server returned: ${response.data}",
      );
    } catch (e, t) {
      talker.error("Error in addNewProfile: ", e, t);
      rethrow;
    }
  }

  /// Delete profile on server by id
  Future<void> deleteProfile(int id) async {
    try {
      final response = await _dio.delete(
        "/deleteProfile",
        queryParameters: {'id': id},
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to delete profile: ${response.data}");
      }
    } catch (e, t) {
      talker.error("Error in deleteProfile: ", e, t);
      rethrow;
    }
  }
}
