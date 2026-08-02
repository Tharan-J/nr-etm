import 'bus_route.dart';
import 'ticket_type.dart';

class ReferenceCatalog {
  final String catalogId;
  final String version;
  final List<BusRoute> routes;
  final List<TicketType> ticketTypes;
  final DateTime fetchedAt;
  final DateTime expiresAt;
  final bool isStale;

  const ReferenceCatalog({
    required this.catalogId,
    required this.version,
    required this.routes,
    required this.ticketTypes,
    required this.fetchedAt,
    required this.expiresAt,
    this.isStale = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory ReferenceCatalog.fromJson(Map<String, dynamic> json) {
    final routesList =
        (json['routes'] as List<dynamic>?)
            ?.map((e) => BusRoute.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final ticketTypesList =
        (json['ticket_types'] as List<dynamic>?)
            ?.map((e) => TicketType.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ReferenceCatalog(
      catalogId: json['catalog_id'] as String? ?? 'cat_default',
      version: json['version'] as String? ?? 'v1.0.0',
      routes: routesList,
      ticketTypes: ticketTypesList,
      fetchedAt:
          DateTime.tryParse(json['fetched_at'] as String? ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expires_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 24)),
      isStale: json['is_stale'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catalog_id': catalogId,
      'version': version,
      'routes': routes.map((e) => e.toJson()).toList(),
      'ticket_types': ticketTypes.map((e) => e.toJson()).toList(),
      'fetched_at': fetchedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_stale': isStale,
    };
  }
}
