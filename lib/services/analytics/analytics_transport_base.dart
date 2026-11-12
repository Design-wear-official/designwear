/// One thing to report: a GA4 event name and its parameters.
class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.params = const {}]);

  final String name;
  final Map<String, Object> params;
}

/// Where events go. The web sends them through Google's gtag.js; every other
/// platform posts them to GA4's Measurement Protocol.
abstract class AnalyticsTransport {
  /// Starts the transport. Called once, after the person's choice is known.
  Future<void> start({
    required String measurementId,
    String? apiSecret,
    required bool granted,
  });

  /// Applies a change of choice. When [granted] is false nothing is sent.
  void setConsent(bool granted);

  void send(AnalyticsEvent event);
}
