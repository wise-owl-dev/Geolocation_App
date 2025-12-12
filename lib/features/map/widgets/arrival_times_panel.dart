import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/bus_stop.dart';
import '../providers/bus_tracking_provider.dart';

class ArrivalTimesPanel extends ConsumerStatefulWidget {
  final String assignmentId;
  final List<BusStop> routeStops;

  const ArrivalTimesPanel({
    super.key,
    required this.assignmentId,
    required this.routeStops,
  });

  @override
  ConsumerState<ArrivalTimesPanel> createState() => _ArrivalTimesPanelState();
}

class _ArrivalTimesPanelState extends ConsumerState<ArrivalTimesPanel> {
  Map<String, Duration?> _arrivalTimes = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateArrivalTimes();
  }

  Future<void> _calculateArrivalTimes() async {
    setState(() {
      _isLoading = true;
    });

    final Map<String, Duration?> times = {};
    
    for (var stop in widget.routeStops) {
      final eta = await ref.read(busTrackingProvider.notifier)
          .calculateEstimatedArrival(widget.assignmentId, stop.id);
      times[stop.id] = eta;
    }

    if (mounted) {
      setState(() {
        _arrivalTimes = times;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Tiempos de llegada estimados',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _calculateArrivalTimes,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: widget.routeStops.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final stop = widget.routeStops[index];
                  final eta = _arrivalTimes[stop.id];
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      stop.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: eta != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getColorForETA(eta),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatETA(eta),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            'N/A',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Color _getColorForETA(Duration eta) {
    final minutes = eta.inMinutes;
    if (minutes <= 5) return Colors.green;
    if (minutes <= 15) return Colors.orange;
    return Colors.blue;
  }

  String _formatETA(Duration eta) {
    final minutes = eta.inMinutes;
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min';
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}