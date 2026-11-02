// lib/screens/live_tracking_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────
class TrackedBus {
  final String docId;
  final String busNumber;
  final String route;
  final LatLng position;
  final double speed;
  final String status;
  final int nextStop;
  final String driverName;

  const TrackedBus({
    required this.docId,
    required this.busNumber,
    required this.route,
    required this.position,
    required this.speed,
    required this.status,
    required this.nextStop,
    required this.driverName,
  });

  factory TrackedBus.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final lat =
        (d['latitude'] is num) ? (d['latitude'] as num).toDouble() : 17.3850;
    final lng =
        (d['longitude'] is num) ? (d['longitude'] as num).toDouble() : 78.4867;

    return TrackedBus(
      docId: doc.id,
      busNumber: d['busNumber'] ?? '',
      route: d['route'] ?? '',
      position: LatLng(lat, lng),
      speed: (d['speed'] is num) ? (d['speed'] as num).toDouble() : 0.0,
      status: d['trackStatus'] ?? d['status'] ?? 'On Time',
      nextStop: (d['nextStop'] is int) ? d['nextStop'] : 0,
      driverName: d['driverName'] ?? '',
    );
  }
}

// ─────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _db = FirebaseFirestore.instance;

  GoogleMapController? _mapController;
  String? _selectedBusId;

  late final Stream<List<TrackedBus>> _busStream = _db
      .collection('fleet_buses')
      .snapshots()
      .map((snap) => snap.docs
          .map(TrackedBus.fromFirestore)
          .where((b) => b.busNumber.isNotEmpty)
          .toList());

  List<TrackedBus> _lastBuses = [];
  Set<Marker> _cachedMarkers = {};

  Set<Marker> _buildMarkers(List<TrackedBus> buses) {
    if (!identical(buses, _lastBuses)) {
      _lastBuses = buses;
      _cachedMarkers = buses.map((bus) {
        final isSelected = bus.docId == _selectedBusId;
        return Marker(
          markerId: MarkerId(bus.docId),
          position: bus.position,
          infoWindow: InfoWindow(
            title: bus.busNumber,
            snippet: '${bus.route}  •  ${bus.speed.toStringAsFixed(0)} km/h',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
          ),
          onTap: () => setState(() => _selectedBusId = bus.docId),
        );
      }).toSet();
    }
    return _cachedMarkers;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'On Time':
      case 'Active':
        return Colors.greenAccent;
      case 'Delayed':
      case 'Maintenance':
        return Colors.orangeAccent;
      case 'Stopped':
      case 'Inactive':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  String _displayStatus(String s) {
    switch (s) {
      case 'Active':
        return 'On Time';
      case 'Inactive':
        return 'Stopped';
      default:
        return s;
    }
  }

  Future<void> _updatePosition(
      String docId, double lat, double lng, double speed) async {
    await _db.collection('fleet_buses').doc(docId).update({
      'latitude': lat,
      'longitude': lng,
      'speed': speed,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Row(
          children: [
            const Text(
              'Live Tracking',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Live',
              style: TextStyle(color: Colors.greenAccent, fontSize: 13),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white70),
            onPressed: () => _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(const LatLng(17.3850, 78.4867), 13),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<TrackedBus>>(
        stream: _busStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load buses\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final buses = snapshot.data ?? [];

          final matchingBuses =
              buses.where((b) => b.docId == _selectedBusId).toList();
          final selectedBus =
              matchingBuses.isEmpty ? null : matchingBuses.first;

          if (selectedBus == null && _selectedBusId != null) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedBusId = null);
            });
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              buses.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            );
          }

          return Column(
            children: [
              // ── Google Map ──────────────────────────────────
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(17.3850, 78.4867),
                        zoom: 12,
                      ),
                      markers: _buildMarkers(buses),
                      mapType: MapType.normal,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      onMapCreated: (c) => _mapController = c,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF111827).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${buses.length} buses',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bus List Panel ──────────────────────────────
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color(0xFF111827),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active Buses',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${buses.length} tracked',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: buses.isEmpty
                            ? const Center(
                                child: Text(
                                  'No buses in fleet yet.',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: buses.length,
                                itemBuilder: (_, i) {
                                  final bus = buses[i];
                                  final isSelected =
                                      bus.docId == _selectedBusId;
                                  final statusLabel =
                                      _displayStatus(bus.status);

                                  return GestureDetector(
                                    onTap: () {
                                      setState(
                                          () => _selectedBusId = bus.docId);
                                      _mapController?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                            bus.position, 15),
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.redAccent
                                                .withValues(alpha: 0.15)
                                            : const Color(0xFF1F2937),
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSelected
                                            ? Border.all(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.5))
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.directions_bus,
                                              color: Colors.redAccent,
                                              size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  bus.busNumber,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  bus.route,
                                                  style: const TextStyle(
                                                      color: Colors.white38,
                                                      fontSize: 11),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color:
                                                      _statusColor(bus.status)
                                                          .withValues(
                                                              alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: TextStyle(
                                                    color: _statusColor(
                                                        bus.status),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                bus.speed > 0
                                                    ? '${bus.speed.toStringAsFixed(0)} km/h'
                                                    : 'Parked',
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Selected Bus Detail Card ────────────────────
              if (selectedBus != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF0E1420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedBus.busNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (selectedBus.driverName.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 13, color: Colors.white38),
                                const SizedBox(width: 4),
                                Text(
                                  selectedBus.driverName,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _detailChip(
                            Icons.speed,
                            '${selectedBus.speed.toStringAsFixed(0)} km/h',
                          ),
                          _detailChip(
                            Icons.location_on,
                            '${selectedBus.position.latitude.toStringAsFixed(4)}, '
                            '${selectedBus.position.longitude.toStringAsFixed(4)}',
                          ),
                          _detailChip(
                            Icons.access_time,
                            selectedBus.nextStop > 0
                                ? 'ETA ${selectedBus.nextStop} min'
                                : 'At stop',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.redAccent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}
