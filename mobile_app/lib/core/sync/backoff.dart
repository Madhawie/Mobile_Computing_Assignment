import 'dart:math' as math;

/// How long to wait before retry number n (1, 2, 3 …): exponential backoff
/// with "equal jitter" (api.md §10 retry rule).
///
/// Base delays 1 s, 2 s, 4 s, 8 s … capped at [max]. The real wait is a random
/// value between half and all of that delay, so phones that lost signal at
/// the same moment do not all hit the server again at the same moment.
class Backoff {
  const Backoff({
    this.base = const Duration(seconds: 1),
    this.max = const Duration(seconds: 60),
    this.maxRetries = 5,
    this.jitter = true,
  });

  final Duration base;
  final Duration max;

  /// Retries per batch before the run stops (rows stay in the outbox and the
  /// next sync, e.g. on reconnect, starts again).
  final int maxRetries;
  final bool jitter;

  /// No waiting at all; for tests and the experiment runner's own pacing.
  static const none = Backoff(base: Duration.zero, max: Duration.zero, jitter: false);

  Duration delay(int retry, [math.Random? random]) {
    final exp = base.inMilliseconds * math.pow(2, retry - 1);
    final capped = math.min(exp, max.inMilliseconds).toInt();
    if (!jitter || capped == 0) return Duration(milliseconds: capped);
    final half = capped ~/ 2;
    return Duration(milliseconds: half + (random ?? math.Random()).nextInt(capped - half + 1));
  }
}
