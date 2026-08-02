import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/duty/presentation/providers/operational_state_provider.dart';
import '../../features/reference/presentation/providers/reference_provider.dart';
import '../../features/ticketing/domain/models/ticket_receipt.dart';
import '../../features/ticketing/presentation/providers/ticket_provider.dart';

class TicketingScreen extends ConsumerStatefulWidget {
  const TicketingScreen({super.key});

  @override
  ConsumerState<TicketingScreen> createState() => _TicketingScreenState();
}

class _TicketingScreenState extends ConsumerState<TicketingScreen> {
  int _sourceStopIndex = 0;
  int _destStopIndex = 1;
  String _passengerCategory = 'adult';
  bool _isIssuing = false;
  TicketReceipt? _lastReceipt;

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(referenceCatalogNotifierProvider);
    final opState = ref.watch(operationalStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          opState.activeTrip != null
              ? 'Route ${opState.activeTrip!.routeName}'
              : 'E-Ticketing',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'OFFLINE READY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading catalog: $err')),
        data: (catalog) {
          if (catalog.routes.isEmpty) {
            return const Center(child: Text('No routes available'));
          }

          final route = catalog.routes.first;
          final stops = route.stops;

          if (stops.isEmpty) {
            return const Center(child: Text('No stops found for route'));
          }

          if (_destStopIndex >= stops.length) {
            _destStopIndex = stops.length - 1;
          }
          if (_sourceStopIndex >= _destStopIndex) {
            _sourceStopIndex = 0;
          }

          final sourceStop = stops[_sourceStopIndex];
          final destStop = stops[_destStopIndex];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Rush-Hour Quick Stop Advance Bar
                Card(
                  color: Colors.amber.shade100,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENT BUS STOP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              'Quick Stage Control',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          key: const Key('next_stop_button'),
                          onPressed: () {
                            setState(() {
                              if (_sourceStopIndex < stops.length - 2) {
                                _sourceStopIndex++;
                                _destStopIndex = _sourceStopIndex + 1;
                              }
                            });
                          },
                          icon: const Icon(Icons.forward, color: Colors.white),
                          label: const Text(
                            'NEXT STOP +',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Source Stop Selector
                const Text(
                  'FROM (Boarding Stop)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                DropdownButton<int>(
                  key: const Key('source_stop_dropdown'),
                  value: _sourceStopIndex,
                  isExpanded: true,
                  items: List.generate(stops.length - 1, (index) {
                    return DropdownMenuItem(
                      value: index,
                      child: Text(
                        '${stops[index].name} (Stage ${stops[index].stageNumber})',
                      ),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _sourceStopIndex = val;
                        if (_destStopIndex <= _sourceStopIndex) {
                          _destStopIndex = _sourceStopIndex + 1;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Destination Stop Selector
                const Text(
                  'TO (Alighting Stop)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                DropdownButton<int>(
                  key: const Key('dest_stop_dropdown'),
                  value: _destStopIndex,
                  isExpanded: true,
                  items: List.generate(stops.length, (index) {
                    return DropdownMenuItem(
                      value: index,
                      enabled: index > _sourceStopIndex,
                      child: Text(
                        '${stops[index].name} (Stage ${stops[index].stageNumber})',
                      ),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null && val > _sourceStopIndex) {
                      setState(() {
                        _destStopIndex = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Category Buttons
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'ADULT',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        selected: _passengerCategory == 'adult',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _passengerCategory = 'adult');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'CHILD',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        selected: _passengerCategory == 'child',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _passengerCategory = 'child');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'SENIOR',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        selected: _passengerCategory == 'senior',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _passengerCategory = 'senior');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Last Issued Ticket Banner
                if (_lastReceipt != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ISSUED: TICKET #${_lastReceipt!.ticketNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        Text(
                          '${_lastReceipt!.sourceStopName} -> ${_lastReceipt!.destStopName} | Rs. ${_lastReceipt!.fareAmount}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Issue Ticket Button
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    key: const Key('issue_ticket_button'),
                    onPressed:
                        _isIssuing
                            ? null
                            : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _isIssuing = true);
                              try {
                                final engine = ref.read(
                                  ticketIssuanceEngineProvider,
                                );
                                final res = await engine.issueTicket(
                                  activeDuty: opState.activeDuty,
                                  activeTrip: opState.activeTrip,
                                  sourceStopId: sourceStop.stopId,
                                  destStopId: destStop.stopId,
                                  sourceStopName: sourceStop.name,
                                  destStopName: destStop.name,
                                  sourceStage: sourceStop.stageNumber,
                                  destStage: destStop.stageNumber,
                                  passengerCategory: _passengerCategory,
                                );

                                if (res.isSuccess) {
                                  setState(() {
                                    _lastReceipt = res.receipt;
                                    _isIssuing = false;
                                  });
                                } else {
                                  setState(() => _isIssuing = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Issuance failed: ${res.errorMessage}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => _isIssuing = false);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Issuance error: $e')),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        _isIssuing
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'PRINT & ISSUE TICKET',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
