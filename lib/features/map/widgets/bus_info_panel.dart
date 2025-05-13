// lib/features/map/widgets/bus_info_panel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/bus.dart';
import '../../../shared/models/assignment.dart';
import '../../../shared/models/location.dart' as custom_location;

class BusInfoPanel extends StatelessWidget {
  final Bus bus;
  final Assignment assignment;
  final custom_location.Location? lastLocation;
  final VoidCallback onClose;

  const BusInfoPanel({
    Key? key,
    required this.bus,
    required this.assignment,
    this.lastLocation,
    required this.onClose,
  }) : super(key: key);

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
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with bus number and close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.directions_bus, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unidad ${bus.busNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (assignment.routeName != null)
                        Text(
                          'Ruta: ${assignment.routeName}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: 'Cerrar panel',
                ),
              ],
            ),
          ),
          // Bus details
          Padding(
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
                      value: bus.licensePlate,
                    ),
                    _buildInfoRow(
                      icon: Icons.people,
                      label: 'Capacidad',
                      value: '${bus.capacity} pasajeros',
                    ),
                    _buildInfoRow(
                      icon: Icons.directions_car,
                      label: 'Vehículo',
                      value: '${bus.brand} ${bus.model} ${bus.year}',
                    ),
                    _buildInfoRow(
                      icon: Icons.offline_bolt,
                      label: 'Estado',
                      value: _formatStatus(bus.status),
                      valueColor: _getStatusColor(bus.status),
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
                      value: _formatTimeRange(assignment),
                    ),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Fecha',
                      value: _formatDateRange(assignment),
                    ),
                    if (assignment.operatorName != null)
                      _buildInfoRow(
                        icon: Icons.person,
                        label: 'Conductor',
                        value: assignment.operatorName!,
                      ),
                    _buildInfoRow(
                      icon: Icons.flag,
                      label: 'Estado',
                      value: _formatAssignmentStatus(assignment.status),
                      valueColor: assignment.status.color,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Location info if available
                if (lastLocation != null)
                  _buildInfoSection(
                    title: 'Información de Ubicación',
                    children: [
                      _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'Última actualización',
                        value: _formatLastUpdate(lastLocation!.timestamp),
                      ),
                      if (lastLocation!.speed != null)
                        _buildInfoRow(
                          icon: Icons.speed,
                          label: 'Velocidad',
                          value: '${lastLocation!.speed!.toStringAsFixed(1)} km/h',
                        ),
                      _buildInfoRow(
                        icon: Icons.location_on,
                        label: 'Coordenadas',
                        value: '${lastLocation!.latitude.toStringAsFixed(6)}, ${lastLocation!.longitude.toStringAsFixed(6)}',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
      return 'Hace ${difference.inSeconds} segundos';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    }
  }
}