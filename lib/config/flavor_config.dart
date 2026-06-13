import '../main.dart';

/// Singleton that holds the active build flavor.
/// Call [FlavorConfig.init] once in [mainCommon] before [runApp].
/// Any widget or service can then read [FlavorConfig.isInternal] statically.
class FlavorConfig {
  FlavorConfig._();

  static Flavor _flavor = Flavor.external;

  static void init(Flavor flavor) => _flavor = flavor;

  static Flavor get current => _flavor;
  static bool get isInternal => _flavor == Flavor.internal;
  static bool get isExternal => _flavor == Flavor.external;

  static String get label => _flavor == Flavor.internal ? 'INTERNAL' : 'EXTERNAL';
}
