import 'app/bootstrap.dart';

/// Production entry point.
///
/// Usage: flutter run --release --dart-define-from-file=config/prod.json
///        flutter build apk --release --dart-define-from-file=config/prod.json
void main() {
  bootstrap(environment: 'production');
}
