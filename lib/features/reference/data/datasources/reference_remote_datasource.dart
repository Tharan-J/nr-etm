import 'package:dio/dio.dart';

import '../../../../core/config/env_config.dart';
import '../../domain/models/bus_route.dart';
import '../../domain/models/bus_stop.dart';
import '../../domain/models/reference_catalog.dart';
import '../../domain/models/ticket_type.dart';

abstract class ReferenceRemoteDataSource {
  Future<ReferenceCatalog> fetchCatalog();
}

class ReferenceRemoteDataSourceImpl implements ReferenceRemoteDataSource {
  final Dio _dio;

  ReferenceRemoteDataSourceImpl({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: EnvConfig().apiBaseUrl,
              connectTimeout: EnvConfig().apiTimeout,
              receiveTimeout: EnvConfig().apiTimeout,
            ),
          );

  @override
  Future<ReferenceCatalog> fetchCatalog() async {
    try {
      final response = await _dio.get('/api/v1/reference/catalog');
      if (response.statusCode == 200 && response.data != null) {
        return ReferenceCatalog.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback to local default operational catalog snapshot on network unavailability
    }

    return _getFallbackCatalog();
  }

  ReferenceCatalog _getFallbackCatalog() {
    final now = DateTime.now();
    return ReferenceCatalog(
      catalogId: 'cat_master_v1',
      version: 'v1.0.0',
      routes: [
        const BusRoute(
          routeId: 'route_335e',
          routeName: '335E (Majestic to ITPL)',
          routeCode: '335E',
          origin: 'Majestic',
          destination: 'ITPL',
          stops: [
            BusStop(
              stopId: 'stop_majestic',
              name: 'Kempegowda Bus Station (Majestic)',
              code: 'KBS',
              latitude: 12.9778,
              longitude: 77.5714,
              stageNumber: 1,
            ),
            BusStop(
              stopId: 'stop_mg_road',
              name: 'MG Road Metro Station',
              code: 'MGR',
              latitude: 12.9756,
              longitude: 77.6067,
              stageNumber: 2,
            ),
            BusStop(
              stopId: 'stop_indiranagar',
              name: 'Indiranagar 100ft Road',
              code: 'IND',
              latitude: 12.9784,
              longitude: 77.6408,
              stageNumber: 3,
            ),
            BusStop(
              stopId: 'stop_marathahalli',
              name: 'Marathahalli Bridge',
              code: 'MAR',
              latitude: 12.9569,
              longitude: 77.7011,
              stageNumber: 4,
            ),
            BusStop(
              stopId: 'stop_itpl',
              name: 'ITPL Main Gate',
              code: 'ITPL',
              latitude: 12.9863,
              longitude: 77.7346,
              stageNumber: 5,
            ),
          ],
        ),
      ],
      ticketTypes: [
        const TicketType(
          typeId: 'tt_single',
          name: 'Single Journey',
          category: 'single',
          defaultFare: 25.0,
          isPass: false,
        ),
        const TicketType(
          typeId: 'tt_daily_pass',
          name: 'Daily Pass (Ordinary)',
          category: 'pass',
          defaultFare: 70.0,
          isPass: true,
        ),
        const TicketType(
          typeId: 'tt_senior',
          name: 'Senior Citizen Concession',
          category: 'concession',
          defaultFare: 15.0,
          isPass: false,
        ),
      ],
      fetchedAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      isStale: false,
    );
  }
}
