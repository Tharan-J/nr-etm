import 'app/bootstrap.dart';

/// Staging entry point.
///
/// Usage: flutter run --dart-define-from-file=config/staging.json
void main() {
  bootstrap(environment: 'staging');
}
