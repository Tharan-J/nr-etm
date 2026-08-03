import 'app/bootstrap.dart';

/// Development entry point.
///
/// Usage: flutter run --dart-define-from-file=config/dev.json
void main() {
  bootstrap(environment: 'development');
}
