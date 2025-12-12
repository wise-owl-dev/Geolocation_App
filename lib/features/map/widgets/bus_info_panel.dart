// lib/features/map/widgets/bus_info_panel.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/bus.dart';
import '../../../shared/models/assignment.dart';
import '../../../shared/models/location.dart' as custom_location;
import '../../../shared/models/bus_stop.dart';

class BusInfoPanel extends StatefulWidget {
  final Bus bus;
  final Assignment assignment;
  final custom_location.Location? lastLocation;
  final VoidCallback onClose;

  const BusInfoPanel({
    super.key,
    required this.bus,
    required this.assignment,
    this.lastLocation,
    required this.onClose,
  });

  @override
  State<BusInfoPanel> createState() => _BusInfoPanelState();
}

class _BusInfoPanelState extends State<BusInfoPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle for dragging
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? 'Contraer' : 'Expandir',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Header with bus number and close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF191970),
                  child: Icon(
                    Icons.directions_bus,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unidad ${widget.bus.busNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (widget.assignment.routeName != null)
                        Text(
                          'Ruta: ${widget.assignment.routeName}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  tooltip: 'Cerrar panel',
                ),
              ],
            ),
          ),
          
          // Bus location info (always visible)
          if (widget.lastLocation != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildQuickInfoItem(
                    icon: Icons.speed,
                    label: 'Velocidad',
                    value: widget.lastLocation!.speed != null 
                        ? '${widget.lastLocation!.speed!.toStringAsFixed(1)} km/h'
                        : 'N/A',
                  ),
                  const SizedBox(width: 16),
                  _buildQuickInfoItem(
                    icon: Icons.access_time,
                    label: 'Última actualización',
                    value: _formatLastUpdate(widget.lastLocation!.timestamp),
                  ),
                ],
              ),
            ),
          
          // Expandable details
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? _buildExpandedDetails()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF191970),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color.fromARGB(255, 255, 255, 255)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bus info
          _buildInfoSection(
            title: 'Información del Autobús',
            children: [
              _buildInfoRow(
                icon: Icons.directions_bus,
                label: 'Placa',
                value: widget.bus.licensePlate,
              ),
              _buildInfoRow(
                icon: Icons.people,
                label: 'Capacidad',
                value: '${widget.bus.capacity} pasajeros',
              ),
              _buildInfoRow(
                icon: Icons.directions_car,
                label: 'Vehículo',
                value: '${widget.bus.brand} ${widget.bus.model} ${widget.bus.year}',
              ),
              _buildInfoRow(
                icon: Icons.offline_bolt,
                label: 'Estado',
                value: _formatStatus(widget.bus.status),
                valueColor: _getStatusColor(widget.bus.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Assignment info
          _buildInfoSection(
            title: 'Información del Servicio',
            children: [
              _buildInfoRow(
                icon: Icons.schedule,
                label: 'Horario',
                value: _formatTimeRange(widget.assignment),
              ),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: _formatDateRange(widget.assignment),
              ),
              if (widget.assignment.operatorName != null)
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Conductor',
                  value: widget.assignment.operatorName!,
                ),
              _buildInfoRow(
                icon: Icons.flag,
                label: 'Estado',
                value: _formatAssignmentStatus(widget.assignment.status),
                valueColor: widget.assignment.status.color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Detailed Location info if available
          if (widget.lastLocation != null)
            _buildInfoSection(
              title: 'Información de Ubicación',
              children: [
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Coordenadas',
                  value: '${widget.lastLocation!.latitude.toStringAsFixed(6)}, ${widget.lastLocation!.longitude.toStringAsFixed(6)}',
                ),
              ],
            ),

          if (widget.assignment.routeId != null)
            FutureBuilder<List<BusStop>>(
              future: _loadRouteStops(widget.assignment.routeId!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      ArrivalTimesPanel(
                        assignmentId: widget.assignment.id,
                        routeStops: snapshot.data!,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
  ),
        ],
      ),
    );
  }

  Future<List<BusStop>> _loadRouteStops(String routeId) async {
  try {
    final supabase = Supabase.instance.client;
    final result = await supabase
        .from('recorrido_paradas')
        .select('*, paradas(*)')
        .eq('recorrido_id', routeId)
        .order('orden');
    
    return result.map((item) => BusStop.fromJson(item['paradas'])).toList();
  } catch (e) {
    print('Error loading route stops: $e');
    return [];
  }
}


double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371;
  
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

double _toRadians(double degrees) {
  return degrees * pi / 180;
}

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
        return 'ACTIVO';
      case 'inactivo':
        return 'INACTIVO';
      case 'mantenimiento':
        return 'EN MANTENIMIENTO';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
        return Colors.green;
      case 'inactivo':
        return Colors.red;
      case 'mantenimiento':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeRange(Assignment assignment) {
    final startTime = '${assignment.startTime.hour.toString().padLeft(2, '0')}:${assignment.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = '${assignment.endTime.hour.toString().padLeft(2, '0')}:${assignment.endTime.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }

  String _formatDateRange(Assignment assignment) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDate = dateFormat.format(assignment.startDate);
    
    if (assignment.endDate != null) {
      final endDate = dateFormat.format(assignment.endDate!);
      if (startDate == endDate) {
        return startDate;
      }
      return '$startDate - $endDate';
    }
    
    return '$startDate - Indefinido';
  }

  String _formatAssignmentStatus(AssignmentStatus status) {
    return status.displayName.toUpperCase();
  }

  String _formatLastUpdate(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Hace ${difference.inSeconds} seg';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} hrs';
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }
}

class ArrivalTimesPanel extends StatelessWidget {
  final String assignmentId;
  final List<BusStop> routeStops;

  const ArrivalTimesPanel({
    Key? key,
    required this.assignmentId,
    required this.routeStops,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Minimal implementation: show header and a simple list of stops.
    // Avoid accessing unknown BusStop fields to keep this file self-contained.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Llegadas (${routeStops.length})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: List.generate(
              routeStops.length,
              (index) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF191970),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text('Parada ${index + 1}'),
                subtitle: const Text('Tiempo estimado: --'), // Placeholder
                dense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}