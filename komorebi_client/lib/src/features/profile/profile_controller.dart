import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/src/core/services/api/profile_api_service.dart';
import 'package:komorebi/src/core/utils/talker.dart';
import 'package:komorebi/src/features/profile/oauth_timer_provider.dart';
import 'package:komorebi/src/features/profile/profile_management_provider.dart';

const desktopOauthTimeout = Duration(minutes: 5);

/// Delete a profile by ID
Future<void> handleProfileDeletion(WidgetRef ref, int id) async {
  final api = ref.read(profileApiServiceProvider);
  await api.deleteProfile(id);
  ref.invalidate(allProfilesProvider);
  ref.invalidate(currentProfileProvider);
}

/// Sandbox sign-in flow
Future<bool> doSandboxSignIn(WidgetRef ref, String userName) async {
  final profileService = ref.read(profileApiServiceProvider);

  try {
    final newProfile = await profileService.verifySandboxProfile(userName);
    await ref
        .read(currentProfileProvider.notifier)
        .updateCurrentProfile(newProfile);
    ref.invalidate(allProfilesProvider);
    return true;
  } catch (e, t) {
    talker.warning("Sandbox sign-in failed or user not found", e, t);
    return false;
  }
}

/// Main OAuth entrypoint for Desktop platforms (server-driven OAuth flow)
Future<void> signInWithOAuth(WidgetRef ref) async {
  ref.read(oauthCountdownProvider.notifier).startCountdown(desktopOauthTimeout);

  try {
    talker.debug("Initiating server-managed OAuth login flow...");
    final profileService = ref.read(profileApiServiceProvider);
    final newProfile = await profileService.startOAuthLogin(provider: 'mal');

    await ref
        .read(currentProfileProvider.notifier)
        .updateCurrentProfile(newProfile);
    ref.invalidate(allProfilesProvider);

    talker.info(
      "Successfully synced profile via sidecar: ${newProfile.username}",
    );
  } catch (e, t) {
    talker.error("Server-managed OAuth flow failed: ", e, t);
    rethrow;
  } finally {
    ref.read(oauthCountdownProvider.notifier).stopCountdown();
  }
}
