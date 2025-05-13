// lib/features/map/providers/map_provider.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/bus_stop.dart';
import '../../../shared/models/map_marker.dart';
import '../../../shared/models/route.dart' as app_route;

class MapState {
  final Map<String, CustomMapMarker> markers;
  final Map<String, Polyline> polylines;
  final Set<Circle> circles;
  final LatLng? initialPosition;
  final LatLng? currentPosition;
  final bool isLoading;
  final String? error;
  final CameraPosition? lastCameraPosition;
  final List<BusStop> busStops;
  final List<app_route.Route> routes;
  final String? selectedRouteId;
  final app_route.Route? selectedRoute;
  final bool showAllStops;

  MapState({
    this.markers = const {},
    this.polylines = const {},
    this.circles = const {},
    this.initialPosition,
    this.currentPosition,
    this.isLoading = false,
    this.error,
    this.lastCameraPosition,
    this.busStops = const [],
    this.routes = const [],
    this.selectedRouteId,
    this.selectedRoute,
    this.showAllStops = true,
  });

  MapState copyWith({
    Map<String, CustomMapMarker>? markers,
    Map<String, Polyline>? polylines,
    Set<Circle>? circles,
    LatLng? initialPosition,
    LatLng? currentPosition,
    bool? isLoading,
    String? error,
    CameraPosition? lastCameraPosition,
    List<BusStop>? busStops,
    List<app_route.Route>? routes,
    String? selectedRouteId,
    app_route.Route? selectedRoute,
    bool? showAllStops,
  }) {
    return MapState(
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      circles: circles ?? this.circles,
      initialPosition: initialPosition ?? this.initialPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastCameraPosition: lastCameraPosition ?? this.lastCameraPosition,
      busStops: busStops ?? this.busStops,
      routes: routes ?? this.routes,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      showAllStops: showAllStops ?? this.showAllStops,
    );
  }

  Set<Marker> get googleMapMarkers {
    return markers.values.map((marker) => marker.toMarker()).toSet();
  }

  Set<Polyline> get googleMapPolylines {
    return polylines.values.toSet();
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final _supabase = Supabase.instance.client;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  Timer? _locationUpdateTimer;
  
  MapNotifier() : super(MapState()) {
    _initMap();
  }

  // Initialize map with default location and load bus stops
  Future<void> _initMap() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Set default initial position (center of your city/area)
      const initialPosition = LatLng(19.4326, -99.1332); // Mexico City by default
      
      // Load bus stops and routes
      await Future.wait([
        loadBusStops(),
        loadRoutes(),
      ]);
      
      state = state.copyWith(
        initialPosition: initialPosition,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error initializing map: $e',
        isLoading: false,
      );
    }
  }

  // Get Google Maps controller when it's available
  void onMapCreated(GoogleMapController controller) {
    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.complete(controller);
    }
  }

  // Save latest camera position when map moves
  void onCameraMove(CameraPosition position) {
    state = state.copyWith(lastCameraPosition: position);
  }

  // Load all bus stops from the database
  Future<void> loadBusStops() async {
    try {
      final result = await _supabase
          .from('paradas')
          .select()
          .eq('estado', 'activo');
      
      final List<BusStop> busStops = [];
      final Map<String, CustomMapMarker> markers = {...state.markers};
      
      for (var item in result) {
        final busStop = BusStop.fromJson(item);
        busStops.add(busStop);
        
        // Create marker for each bus stop
        final marker = CustomMapMarker(
          id: 'stop_${busStop.id}',
          position: LatLng(busStop.latitude, busStop.longitude),
          title: busStop.name,
          snippet: busStop.address,
          type: MarkerType.busStop,
          busStopId: busStop.id,
        );
        
        markers[marker.id] = marker;
      }
      
      state = state.copyWith(
        busStops: busStops,
        markers: state.showAllStops ? markers : state.markers,
      );
    } catch (e) {
      print('Error loading bus stops: $e');
    }
  }

  // Load all routes from the database
  Future<void> loadRoutes() async {
    try {
      final result = await _supabase
          .from('recorridos')
          .select()
          .eq('estado', 'activo');
      
      final List<app_route.Route> routes = [];
      
      for (var item in result) {
        routes.add(app_route.Route.fromJson(item));
      }
      
      state = state.copyWith(routes: routes);
    } catch (e) {
      print('Error loading routes: $e');
    }
  }

  // Select a route and load its stops
  Future<void> selectRoute(String routeId) async {
    state = state.copyWith(isLoading: true, selectedRouteId: routeId);
    
    try {
      // Find the route
      final selectedRoute = state.routes.firstWhere(
        (route) => route.id == routeId,
        orElse: () => throw Exception('Route not found'),
      );
      
      // Get route stops
      final result = await _supabase
          .from('recorrido_paradas')
          .select('*, paradas(*)')
          .eq('recorrido_id', routeId)
          .order('orden');
      
      if (result.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          selectedRoute: selectedRoute,
        );
        return;
      }
      
      // Create markers for route stops
      final Map<String, CustomMapMarker> markers = {};
      final List<LatLng> routePoints = [];
      
      for (var item in result) {
        final stopData = item['paradas'];
        if (stopData != null) {
          final busStop = BusStop.fromJson(stopData);
          
          // Add to route points for polyline
          routePoints.add(LatLng(busStop.latitude, busStop.longitude));
          
          // Create marker
          final marker = CustomMapMarker(
            id: 'route_stop_${busStop.id}',
            position: LatLng(busStop.latitude, busStop.longitude),
            title: '${item['orden']}. ${busStop.name}',
            snippet: busStop.address,
            type: MarkerType.busStop,
            busStopId: busStop.id,
            routeId: routeId,
          );
          
          markers[marker.id] = marker;
        }
      }
      
      // Create polyline for the route
      final polylines = <String, Polyline>{};
      if (routePoints.length > 1) {
        polylines['route_$routeId'] = Polyline(
          polylineId: PolylineId('route_$routeId'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
        );
      }
      
      // Update state
      state = state.copyWith(
        markers: markers,
        polylines: polylines,
        isLoading: false,
        selectedRoute: selectedRoute,
        showAllStops: false,
      );
      
      // Zoom to show the route
      _zoomToFitPolyline(routePoints);
    } catch (e) {
      state = state.copyWith(
        error: 'Error loading route stops: $e',
        isLoading: false,
      );
    }
  }

  // Clear selected route
  void clearRoute() {
    state = state.copyWith(
      selectedRouteId: null,
      selectedRoute: null,
      polylines: {},
      markers: {},
      showAllStops: true,
    );
    
    // Reload all bus stops
    loadBusStops();
  }

  // Toggle showing all stops or only route stops
  void toggleShowAllStops() {
    if (state.showAllStops) {
      // If we're showing all stops and have a selected route,
      // switch to showing only route stops
      if (state.selectedRouteId != null) {
        selectRoute(state.selectedRouteId!);
      }
    } else {
      // Reload all stops
      Map<String, CustomMapMarker> allMarkers = {};
      
      for (var busStop in state.busStops) {
        final marker = CustomMapMarker(
          id: 'stop_${busStop.id}',
          position: LatLng(busStop.latitude, busStop.longitude),
          title: busStop.name,
          snippet: busStop.address,
          type: MarkerType.busStop,
          busStopId: busStop.id,
        );
        
        allMarkers[marker.id] = marker;
      }
      
      // Keep the polyline if we have a selected route
      state = state.copyWith(
        markers: allMarkers,
        showAllStops: true,
      );
    }
  }

  // Add a bus marker with rotation (for direction)
  Future<void> addBusMarker({
    required String id,
    required LatLng position,
    required String title,
    String? snippet,
    double rotation = 0.0,
    double? speed,
    String? busId,
    String? routeId,
    String? assignmentId,
  }) async {
    try {
      // Load custom bus icon if needed
      BitmapDescriptor icon = await _getBusIcon();
      
      final marker = CustomMapMarker(
        id: id,
        position: position,
        title: title,
        snippet: snippet ?? (speed != null ? '${speed.toStringAsFixed(1)} km/h' : null),
        icon: icon,
        type: MarkerType.bus,
        busId: busId,
        routeId: routeId,
        assignmentId: assignmentId,
        rotation: rotation,
        speed: speed,
        lastUpdated: DateTime.now(),
      );
      
      final markers = {...state.markers};
      markers[id] = marker;
      
      state = state.copyWith(markers: markers);
    } catch (e) {
      print('Error adding bus marker: $e');
    }
  }

  // Update bus marker position and rotation
  void updateBusMarker({
    required String id,
    required LatLng position,
    double? rotation,
    double? speed,
  }) {
    final markers = {...state.markers};
    final existingMarker = markers[id];
    
    if (existingMarker != null) {
      markers[id] = existingMarker.copyWith(
        position: position,
        rotation: rotation,
        speed: speed,
        lastUpdated: DateTime.now(),
        snippet: speed != null ? '${speed.toStringAsFixed(1)} km/h' : existingMarker.snippet,
      );
      
      state = state.copyWith(markers: markers);
    }
  }

  // Remove a marker
  void removeMarker(String id) {
    final markers = {...state.markers};
    markers.remove(id);
    state = state.copyWith(markers: markers);
  }

  // Add a current position marker
  Future<void> addCurrentPositionMarker(LatLng position) async {
    final marker = CustomMapMarker(
      id: 'current_position',
      position: position,
      title: 'Mi ubicación',
      type: MarkerType.currentPosition,
    );
    
    final markers = {...state.markers};
    markers[marker.id] = marker;
    
    state = state.copyWith(
      markers: markers,
      currentPosition: position,
    );
    
    // Center map on current position
    moveCamera(position);
  }

  // Update current position marker
  void updateCurrentPositionMarker(LatLng position) {
    final markers = {...state.markers};
    final existingMarker = markers['current_position'];
    
    if (existingMarker != null) {
      markers['current_position'] = existingMarker.copyWith(
        position: position,
      );
      
      state = state.copyWith(
        markers: markers,
        currentPosition: position,
      );
    } else {
      addCurrentPositionMarker(position);
    }
  }

  // Move camera to a specific position
  Future<void> moveCamera(LatLng position, {double zoom = 15.0}) async {
    final controller = await _mapControllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: zoom,
        ),
      ),
    );
  }

  // Zoom to fit a polyline
  Future<void> _zoomToFitPolyline(List<LatLng> points) async {
    if (points.isEmpty) return;
    
    // Calculate bounds
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;
    
    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    // Add padding
    final padding = 0.01; // Approximately 1km padding
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;
    
    // Create bounds and update camera
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    final controller = await _mapControllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0), // 50 pixels padding
    );
  }
  
  // Get a custom icon for bus markers
  Future<BitmapDescriptor> _getBusIcon() async {
    try {
      // Try to load custom bus icon from assets (you'll need to add this)
      final Uint8List markerIcon = await _getBytesFromAsset('assets/images/bus_marker.png', 120);
      return BitmapDescriptor.fromBytes(markerIcon);
    } catch (e) {
      // If custom icon fails, use default blue marker
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }
  
  // Helper method to load asset as bytes
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  // Simulate bus movement for development (useful for testing)
  void simulateBusMovement(String busId, String busNumber, LatLng startPosition, LatLng endPosition) {
    const totalSteps = 20;
    const intervalMs = 1000; // 1 second between updates
    
    final latStep = (endPosition.latitude - startPosition.latitude) / totalSteps;
    final lngStep = (endPosition.longitude - startPosition.longitude) / totalSteps;
    
    int currentStep = 0;
    
    // Calculate initial rotation (bearing)
    final initialRotation = _calculateBearing(startPosition, endPosition);
    
    // Create initial marker
    addBusMarker(
      id: 'bus_$busId',
      position: startPosition,
      title: 'Unidad $busNumber',
      rotation: initialRotation,
      speed: 30.0, // Arbitrary speed for simulation
      busId: busId,
    );
    
    // Start movement timer
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      currentStep++;
      
      if (currentStep > totalSteps) {
        timer.cancel();
        return;
      }
      
      final newPosition = LatLng(
        startPosition.latitude + (latStep * currentStep),
        startPosition.longitude + (lngStep * currentStep),
      );
      
      // Update marker with new position and rotation
      updateBusMarker(
        id: 'bus_$busId',
        position: newPosition,
        rotation: initialRotation,
        speed: 30.0 + (currentStep % 5), // Vary speed slightly for realism
      );
    });
  }
  
  // Calculate bearing (rotation) between two points
  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * (pi / 180);
    final double lng1 = start.longitude * (pi / 180);
    final double lat2 = end.latitude * (pi / 180);
    final double lng2 = end.longitude * (pi / 180);
    
    final double y = sin(lng2 - lng1) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lng2 - lng1);
    
    final double bearing = atan2(y, x);
    return (bearing * (180 / pi) + 360) % 360; // Convert to degrees
  }
  
  // Add or update a polyline
  void updatePolyline(String id, Polyline polyline) {
    final polylines = {...state.polylines};
    polylines[id] = polyline;
    state = state.copyWith(polylines: polylines);
  }
  
  // Remove a polyline
  void removePolyline(String id) {
    final polylines = {...state.polylines};
    polylines.remove(id);
    state = state.copyWith(polylines: polylines);
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}