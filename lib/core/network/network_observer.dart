import 'dart:async';

enum NetworkStatus { online, offline, poor, recovering }

class NetworkObserver {
  NetworkStatus _status = NetworkStatus.online;
  final _controller = StreamController<NetworkStatus>.broadcast();

  NetworkStatus get status => _status;
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void setStatus(NetworkStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _controller.add(_status);
    }
  }

  void dispose() {
    _controller.close();
  }
}
