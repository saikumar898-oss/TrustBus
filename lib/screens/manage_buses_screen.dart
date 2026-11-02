// lib/screens/manage_buses_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────
class Bus {
  final String docId;
  String busNumber;
  String route;
  String status;
  int capacity;
  String driverName;
  String operator_;
  String city;

  Bus({
    required this.docId,
    required this.busNumber,
    required this.route,
    required this.status,
    required this.capacity,
    required this.driverName,
    this.operator_ = '',
    this.city = '',
  });

  factory Bus.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Bus(
      docId: doc.id,
      busNumber: d['busNumber'] ?? '',
      route: d['route'] ?? '',
      status: d['status'] ?? 'Inactive',
      capacity: (d['capacity'] is int)
          ? d['capacity']
          : int.tryParse('${d['capacity']}') ?? 0,
      driverName: d['driverName'] ?? '',
      operator_: d['operator'] ?? '',
      city: d['city'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'busNumber': busNumber,
        'route': route,
        'status': status,
        'capacity': capacity,
        'driverName': driverName,
        'operator': operator_,
        'city': city,
      };
}

// ─────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────
class ManageBusesScreen extends StatefulWidget {
  const ManageBusesScreen({super.key});

  @override
  State<ManageBusesScreen> createState() => _ManageBusesScreenState();
}

class _ManageBusesScreenState extends State<ManageBusesScreen> {
  final _db = FirebaseFirestore.instance;
  String _search = '';

  Stream<List<Bus>> get _busStream => _db
      .collection('fleet_buses')
      .orderBy('busNumber')
      .snapshots()
      .map((snap) => snap.docs.map(Bus.fromFirestore).toList());

  List<Bus> _applyFilter(List<Bus> buses) => buses
      .where((b) =>
          b.busNumber.toLowerCase().contains(_search.toLowerCase()) ||
          b.route.toLowerCase().contains(_search.toLowerCase()) ||
          b.driverName.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  Color _statusColor(String s) {
    switch (s) {
      case 'Active':
        return Colors.greenAccent;
      case 'Inactive':
        return Colors.grey;
      case 'Maintenance':
        return Colors.orangeAccent;
      default:
        return Colors.white;
    }
  }

  // ── Add / Edit form ──────────────────────────────────────────
  void _openForm({Bus? bus}) {
    final isEdit = bus != null;
    final numCtrl = TextEditingController(text: bus?.busNumber ?? '');
    final routeCtrl = TextEditingController(text: bus?.route ?? '');
    final capCtrl = TextEditingController(text: bus?.capacity.toString() ?? '');
    final drvCtrl = TextEditingController(text: bus?.driverName ?? '');
    final opCtrl = TextEditingController(text: bus?.operator_ ?? '');
    final cityCtrl = TextEditingController(text: bus?.city ?? '');
    String status = bus?.status ?? 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(builder: (ctx, setModal) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isEdit ? 'Edit Bus' : 'Add New Bus',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.white38),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _field('Bus Number', numCtrl),
                _field('Route', routeCtrl),
                _field('Capacity', capCtrl, keyboard: TextInputType.number),
                _field('Driver Name', drvCtrl),
                _field('Operator', opCtrl),
                _field('City', cityCtrl),
                const SizedBox(height: 12),
                const Text('Status',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: const Color(0xFF374151),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF374151),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                  items: ['Active', 'Inactive', 'Maintenance']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModal(() => status = v!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final data = {
                        'busNumber': numCtrl.text.trim(),
                        'route': routeCtrl.text.trim(),
                        'capacity': int.tryParse(capCtrl.text.trim()) ?? 0,
                        'driverName': drvCtrl.text.trim(),
                        'operator': opCtrl.text.trim(),
                        'city': cityCtrl.text.trim(),
                        'status': status,
                      };
                      if (isEdit) {
                        await _db
                            .collection('fleet_buses')
                            .doc(bus.docId)
                            .update(data);
                      } else {
                        await _db.collection('fleet_buses').add({
                          ...data,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      isEdit ? 'Save Changes' : 'Add Bus',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
          {TextInputType keyboard = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: ctrl,
              keyboardType: keyboard,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF374151),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
      );

  void _deleteBus(Bus bus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Delete Bus', style: TextStyle(color: Colors.white)),
        content: Text('Remove ${bus.busNumber}?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _db.collection('fleet_buses').doc(bus.docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Manage Buses',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.redAccent),
            onPressed: () => _openForm(),
          )
        ],
      ),
      body: StreamBuilder<List<Bus>>(
        stream: _busStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.redAccent));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading buses:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            );
          }

          final allBuses = snapshot.data ?? [];
          final filtered = _applyFilter(allBuses);

          return Column(
            children: [
              // ── Search ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by bus number, route or driver…',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1F2937),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),

              // ── Status chips — scrollable so they never overflow ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['Active', 'Inactive', 'Maintenance'].map((s) {
                    final count = allBuses.where((b) => b.status == s).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('$s: $count',
                            style: TextStyle(
                                color: _statusColor(s), fontSize: 12)),
                        backgroundColor: const Color(0xFF1F2937),
                        side:
                            BorderSide(color: _statusColor(s).withOpacity(0.4)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // ── List ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_bus_outlined,
                                color: Colors.white24, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _search.isEmpty
                                  ? 'No buses in fleet yet.\nTap + to add one.'
                                  : 'No buses match "$_search".',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        // Extra bottom padding so FAB doesn't cover last item
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _BusCard(
                          bus: filtered[i],
                          statusColor: _statusColor(filtered[i].status),
                          onEdit: () => _openForm(bus: filtered[i]),
                          onDelete: () => _deleteBus(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add),
        label: const Text('Add Bus'),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  BUS CARD
//  Custom layout — NO ListTile — so we
//  have full control and zero overflow.
// ─────────────────────────────────────────
class _BusCard extends StatelessWidget {
  final Bus bus;
  final Color statusColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BusCard({
    required this.bus,
    required this.statusColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon ─────────────────────────────────────────────
          CircleAvatar(
            backgroundColor: const Color(0xFF374151),
            radius: 20,
            child: const Icon(Icons.directions_bus,
                color: Colors.redAccent, size: 18),
          ),
          const SizedBox(width: 12),

          // ── Text info (fills remaining width) ────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bus.busNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  bus.route,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                // Wrap prevents overflow when all three chips are wide
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    _chip(Icons.person, bus.driverName),
                    _chip(Icons.event_seat, '${bus.capacity} seats'),
                    if (bus.city.isNotEmpty) _chip(Icons.location_on, bus.city),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Status badge + actions ────────────────────────────
          // Fixed-width column so it never pushes into the text area
          SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    bus.status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      child: const Icon(Icons.edit_outlined,
                          size: 17, color: Colors.white38),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline,
                          size: 17, color: Colors.redAccent),
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

  Widget _chip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white38),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
}
