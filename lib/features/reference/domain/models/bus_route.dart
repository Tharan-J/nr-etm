import 'bus_stop.dart';

class BusRoute {
  final String routeId;
  final String routeName;
  final String routeCode;
  final String origin;
  final String destination;
  final List<BusStop> stops;

  const BusRoute({
    required this.routeId,
    required this.routeName,
    required this.routeCode,
    required this.origin,
    required this.destination,
    required this.stops,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final stopsList = (json['stops'] as List<dynamic>?)
            ?.map((e) => BusStop.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return BusRoute(
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String,
      routeCode: json['route_code'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      stops: stopsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'route_name': routeName,
      'route_code': routeCode,
      'origin': origin,
      'destination': destination,
      'stops': stops.map((e) => e.toJson()).toList(),
    };
  }
}
