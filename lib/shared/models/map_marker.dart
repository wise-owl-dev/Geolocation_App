// lib/shared/models/map_marker.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MarkerType { bus, busStop, currentPosition }

class CustomMapMarker {
  final String id;
  final LatLng position;
  final String title;
  final String? snippet;
  final BitmapDescriptor? icon;
  final MarkerType type;
  final String? routeId;
  final String? busId;
  final String? busStopId;
  final String? assignmentId;
  final double? rotation; // For bus direction
  final double? speed;
  final DateTime? lastUpdated;

  CustomMapMarker({
    required this.id,
    required this.position,
    required this.title,
    this.snippet,
    this.icon,
    required this.type,
    this.routeId,
    this.busId,
    this.busStopId,
    this.assignmentId,
    this.rotation,
    this.speed,
    this.lastUpdated,
  });

  // Convert to a Google Maps marker
  Marker toMarker({
    VoidCallback? onTap,
    bool draggable = false,
    Function(LatLng)? onDragEnd,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: icon ?? _getDefaultIcon(),
      onTap: onTap,
      draggable: draggable,
      rotation: rotation ?? 0,
      onDragEnd: onDragEnd != null ? (value) => onDragEnd(value) : null,
    );
  }

  // Get default icon based on marker type
  BitmapDescriptor _getDefaultIcon() {
    switch (type) {
      case MarkerType.bus:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case MarkerType.busStop:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case MarkerType.currentPosition:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  // Create a copy with new values
  CustomMapMarker copyWith({
    String? id,
    LatLng? position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    MarkerType? type,
    String? routeId,
    String? busId,
    String? busStopId,
    String? assignmentId,
    double? rotation,
    double? speed,
    DateTime? lastUpdated,
  }) {
    return CustomMapMarker(
      id: id ?? this.id,
      position: position ?? this.position,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      busStopId: busStopId ?? this.busStopId,
      assignmentId: assignmentId ?? this.assignmentId,
      rotation: rotation ?? this.rotation,
      speed: speed ?? this.speed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}