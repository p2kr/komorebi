import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/src/core/services/api/profile_api_service.dart';
import 'package:komorebi/src/core/utils/constants.dart';
import 'package:komorebi/src/core/utils/dio.dart';
import 'package:komorebi/src/core/utils/init.dart';
import 'package:komorebi/src/core/utils/mal_api.dart';
import 'package:komorebi/src/core/utils/talker.dart';
import 'package:komorebi/src/models/api/mal_models.dart';
import 'package:komorebi/src/models/env.dart';
import 'package:komorebi/src/models/profile.dart';
import 'package:komorebi/src/providers/oauth_timer_provider.dart';
import 'package:komorebi/src/providers/profile_management_provider.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:url_launcher/url_launcher.dart';

const authUrl = "https://myanimelist.net/v1/oauth2/authorize";
const tokenUrl = "https://myanimelist.net/v1/oauth2/token";
final clientId = Env.malClientId;
const desktopOauthTimeout = Duration(minutes: 5);

String _generateCodeVerifier() {
  final random = Random.secure();
  final values = List<int>.generate(32, (i) => random.nextInt(256));
  return base64UrlEncode(values).replaceAll('=', '');
}

String? _extractOAuthCode(Uri uri) {
  if (uri.queryParameters.containsKey('code')) {
    return uri.queryParameters['code'];
  }
  if (uri.fragment.isNotEmpty) {
    try {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      if (fragmentParams.containsKey('code')) {
        return fragmentParams['code'];
      }
    } catch (_) {}
  }
  return null;
}

/// Delete a profile by ID
Future<void> handleProfileDeletion(WidgetRef ref, int id) async {
  final api = ref.read(profileApiServiceProvider);
  await api.deleteProfile(id);
  ref.invalidate(allProfilesProvider);
  ref.invalidate(currentProfileProvider);
}

/// Sandbox sign-in flow
Future<bool> doSandboxSignIn(WidgetRef ref, String userName) async {
  final api = MalApi(defaultClientId: Env.malClientId);

  try {
    await api.getUserAnimeList(username: userName);
  } catch (e, t) {
    talker.warning("User not found", e, t);
    return false;
  }

  final profileService = ref.read(profileApiServiceProvider);
  final newProfile = await profileService.addNewProfile(
    Profile(
      username: userName,
      syncType: SyncType.sandbox,
      createdAt: DateTime.now(),
    ),
  );

  await ref
      .read(currentProfileProvider.notifier)
      .updateCurrentProfile(newProfile);
  ref.invalidate(allProfilesProvider);
  return true;
}

/// Main OAuth entrypoint for Desktop platforms
Future<void> signInWithOAuth(WidgetRef ref) async {
  final codeVerifier = _generateCodeVerifier();
  const redirectUrl = MAL_OAUTH_REDIRECT_URL;

  final loginUri = Uri.parse(authUrl).replace(
    queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUrl,
      'response_type': 'code',
      'code_challenge': codeVerifier,
      'code_challenge_method': 'plain',
    },
  );

  ref.read(oauthCountdownProvider.notifier).startCountdown(desktopOauthTimeout);

  try {
    talker.debug(
      "Starting Desktop OAuth login flow via default browser with deep link: $redirectUrl",
    );

    try {
      await protocolHandler.register(KOMOREBI);
    } catch (e, t) {
      talker.warning("Could not register custom schemes: ", e, t);
    }

    final callbackFuture = deepLinkController.stream
        .firstWhere(
          (uri) => (uri.scheme == KOMOREBI) && _extractOAuthCode(uri) != null,
        )
        .timeout(
          desktopOauthTimeout,
          onTimeout: () => throw TimeoutException(
            "OAuth authentication timed out waiting for browser callback.",
          ),
        );

    final launched = await launchUrl(
      loginUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception("Could not launch default browser for URL: $loginUri");
    }

    talker.debug("Browser launched. Waiting for MAL authorization callback...");
    final returnedUri = await callbackFuture;
    final authCode = _extractOAuthCode(returnedUri);

    if (authCode != null) {
      talker.debug(
        "Authorization Code successfully retrieved on Desktop via deep link: $authCode",
      );
      await _exchangeCodeAndSaveProfile(
        ref,
        authCode,
        codeVerifier,
        redirectUrl,
      );
    } else {
      talker.error(
        "Authorization Code was null in Desktop callback URI: $returnedUri",
      );
    }
  } catch (e, t) {
    talker.error("Desktop authentication flow encountered an error: ", e, t);
    rethrow;
  } finally {
    ref.read(oauthCountdownProvider.notifier).stopCountdown();
  }
}

Future<void> _exchangeCodeAndSaveProfile(
  WidgetRef ref,
  String authCode,
  String codeVerifier,
  String redirectUrl,
) async {
  try {
    talker.debug("Exchanging authorization code for access token...");
    final dio = getDioWithLogger();

    final data = <String, dynamic>{
      'client_id': clientId,
      if (Env.malClientSecret.isNotEmpty) 'client_secret': Env.malClientSecret,
      'code': authCode,
      'code_verifier': codeVerifier,
      'grant_type': 'authorization_code',
      'redirect_uri': redirectUrl,
    };

    final response = await dio.post(
      tokenUrl,
      data: data,
      options: Options(
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ),
    );

    final tokenMap = asMap(response.data);
    final accessToken = tokenMap['access_token']?.toString();

    if (accessToken == null || accessToken.isEmpty) {
      throw MalApiException(
        statusCode: response.statusCode ?? 500,
        message:
            "Failed to retrieve access token from response: ${response.data}",
      );
    }

    talker.debug("Access token retrieved. Fetching MAL user info...");
    final api = MalApi(defaultAccessToken: accessToken);
    final userInfo = await api.getMyUserInfo();
    api.dispose();

    talker.debug("Fetched MAL user: ${userInfo.name} [ID: ${userInfo.id}]");

    final profileService = ref.read(profileApiServiceProvider);
    final newProfile = await profileService.addNewProfile(
      Profile(
        username: userInfo.name,
        avatarUrl: userInfo.picture,
        syncType: SyncType.mal,
        accessToken: accessToken,
        createdAt: DateTime.now(),
      ),
    );

    await ref
        .read(currentProfileProvider.notifier)
        .updateCurrentProfile(newProfile);
    ref.invalidate(allProfilesProvider);
    talker.info("Successfully synced MAL profile: ${userInfo.name}");
  } catch (e, t) {
    talker.error("Error exchanging OAuth token or saving profile: ", e, t);
    rethrow;
  }
}
