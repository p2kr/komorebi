import 'dart:async';

import 'package:quiver/async.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'oauth_timer_provider.g.dart';

@Riverpod(keepAlive: true)
class OauthCountdownNotifier extends _$OauthCountdownNotifier {
  CountdownTimer? _timer;
  StreamSubscription<CountdownTimer>? _sub;

  @override
  Duration? build() => null;

  void startCountdown(Duration duration) {
    stopCountdown();

    final timer = CountdownTimer(duration, const Duration(seconds: 1));
    _timer = timer;
    state = timer.remaining;

    _sub = timer.listen(
      (t) {
        if (ref.mounted) state = t.remaining;
      },
      onDone: () {
        if (ref.mounted) state = null;
      },
    );
  }

  void stopCountdown() {
    _sub?.cancel();
    _timer?.cancel();
    _sub = null;
    _timer = null;
    if (ref.mounted && state != null) {
      state = null;
    }
  }
}
