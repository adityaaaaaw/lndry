/// LNDRY App Flavor
/// Determines which environment configuration is active.
/// Set via `--dart-define=FLAVOR=staging` at build time.
enum AppFlavor {
  development,
  staging,
  production;

  static AppFlavor get current {
    const raw = String.fromEnvironment('FLAVOR', defaultValue: 'development');
    return AppFlavor.values.firstWhere(
      (f) => f.name == raw,
      orElse: () => AppFlavor.development,
    );
  }

  bool get isDev        => this == AppFlavor.development;
  bool get isStaging    => this == AppFlavor.staging;
  bool get isProduction => this == AppFlavor.production;

  String get label => switch (this) {
        AppFlavor.development => 'Dev',
        AppFlavor.staging     => 'Staging',
        AppFlavor.production  => 'Prod',
      };
}
