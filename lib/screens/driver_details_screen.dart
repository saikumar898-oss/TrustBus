// lib/screens/driver_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────
class Driver {
  final String docId;
  String name;
  String licenseNo;
  String phone;
  String assignedBus;
  String status;
  int experience;
  double rating;
  String bloodGroup;
  String joiningDate;
  String city;
  String operator_;

  Driver({
    required this.docId,
    required this.name,
    required this.licenseNo,
    required this.phone,
    required this.assignedBus,
    required this.status,
    required this.experience,
    required this.rating,
    required this.bloodGroup,
    required this.joiningDate,
    this.city = '',
    this.operator_ = '',
  });

  factory Driver.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Driver(
      docId: doc.id,
      name: d['name'] ?? '',
      licenseNo: d['licenseNo'] ?? '',
      phone: d['phone'] ?? '',
      assignedBus: d['assignedBus'] ?? '',
      status: d['status'] ?? 'Off Duty',
      experience: (d['experience'] is int)
          ? d['experience']
          : int.tryParse('${d['experience']}') ?? 0,
      rating: (d['rating'] is double)
          ? d['rating']
          : double.tryParse('${d['rating']}') ?? 0.0,
      bloodGroup: d['bloodGroup'] ?? '',
      joiningDate: d['joiningDate'] ?? '',
      city: d['city'] ?? '',
      operator_: d['operator'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'licenseNo': licenseNo,
        'phone': phone,
        'assignedBus': assignedBus,
        'status': status,
        'experience': experience,
        'rating': rating,
        'bloodGroup': bloodGroup,
        'joiningDate': joiningDate,
        'city': city,
        'operator': operator_,
      };
}

// ─────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────
class DriverDetailsScreen extends StatefulWidget {
  const DriverDetailsScreen({super.key});

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  final _db = FirebaseFirestore.instance;
  String _search = '';

  // ── Stream ───────────────────────────────────────────────────
  Stream<List<Driver>> get _driverStream => _db
      .collection('drivers')
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(Driver.fromFirestore).toList());

  List<Driver> _applyFilter(List<Driver> drivers) => drivers
      .where((d) =>
          d.name.toLowerCase().contains(_search.toLowerCase()) ||
          d.assignedBus.toLowerCase().contains(_search.toLowerCase()) ||
          d.licenseNo.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  Color _statusColor(String s) {
    switch (s) {
      case 'On Duty':
        return Colors.greenAccent;
      case 'Off Duty':
        return Colors.grey;
      case 'On Leave':
        return Colors.orangeAccent;
      default:
        return Colors.white;
    }
  }

  // ── Driver detail bottom sheet ───────────────────────────────
  void _viewDriver(Driver d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + name
              Row(children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  child: Text(
                    d.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(d.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(d.status,
                            style: TextStyle(
                                color: _statusColor(d.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // Star rating
              Row(children: [
                ...List.generate(
                    5,
                    (i) => Icon(
                          i < d.rating.floor() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        )),
                const SizedBox(width: 8),
                Text(d.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.amber, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),

              // Details
              _detailRow(Icons.badge, 'License No', d.licenseNo),
              _detailRow(Icons.phone, 'Phone', d.phone),
              _detailRow(Icons.directions_bus, 'Assigned Bus', d.assignedBus),
              _detailRow(
                  Icons.work_history, 'Experience', '${d.experience} years'),
              _detailRow(Icons.bloodtype, 'Blood Group', d.bloodGroup),
              _detailRow(Icons.calendar_today, 'Joined', d.joiningDate),
              if (d.city.isNotEmpty)
                _detailRow(Icons.location_city, 'City', d.city),
              if (d.operator_.isNotEmpty)
                _detailRow(Icons.business, 'Operator', d.operator_),

              const SizedBox(height: 24),

              // Action buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call,
                        color: Colors.greenAccent, size: 16),
                    label: const Text('Call',
                        style: TextStyle(color: Colors.greenAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.greenAccent, width: 0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openForm(driver: d);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Icon(icon, color: Colors.redAccent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ]),
      );

  // ── Add / Edit form ──────────────────────────────────────────
  void _openForm({Driver? driver}) {
    final isEdit = driver != null;
    final nameCtrl = TextEditingController(text: driver?.name ?? '');
    final licCtrl = TextEditingController(text: driver?.licenseNo ?? '');
    final phCtrl = TextEditingController(text: driver?.phone ?? '');
    final busCtrl = TextEditingController(text: driver?.assignedBus ?? '');
    final expCtrl =
        TextEditingController(text: driver?.experience.toString() ?? '');
    final ratCtrl =
        TextEditingController(text: driver?.rating.toString() ?? '');
    final blCtrl = TextEditingController(text: driver?.bloodGroup ?? '');
    final joinCtrl = TextEditingController(text: driver?.joiningDate ?? '');
    final cityCtrl = TextEditingController(text: driver?.city ?? '');
    final opCtrl = TextEditingController(text: driver?.operator_ ?? '');
    String status = driver?.status ?? 'Off Duty';

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
                      isEdit ? 'Edit Driver' : 'Add New Driver',
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
                _formField('Full Name', nameCtrl),
                _formField('License No', licCtrl),
                _formField('Phone', phCtrl, keyboard: TextInputType.phone),
                _formField('Assigned Bus', busCtrl),
                _formField('Experience (years)', expCtrl,
                    keyboard: TextInputType.number),
                _formField('Rating (1–5)', ratCtrl,
                    keyboard:
                        const TextInputType.numberWithOptions(decimal: true)),
                _formField('Blood Group', blCtrl),
                _formField('Joining Date (DD/MM/YYYY)', joinCtrl),
                _formField('City', cityCtrl),
                _formField('Operator', opCtrl),
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
                  items: ['On Duty', 'Off Duty', 'On Leave']
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
                        'name': nameCtrl.text.trim(),
                        'licenseNo': licCtrl.text.trim(),
                        'phone': phCtrl.text.trim(),
                        'assignedBus': busCtrl.text.trim(),
                        'status': status,
                        'experience': int.tryParse(expCtrl.text.trim()) ?? 0,
                        'rating': double.tryParse(ratCtrl.text.trim()) ?? 0.0,
                        'bloodGroup': blCtrl.text.trim(),
                        'joiningDate': joinCtrl.text.trim(),
                        'city': cityCtrl.text.trim(),
                        'operator': opCtrl.text.trim(),
                      };

                      if (isEdit) {
                        await _db
                            .collection('drivers')
                            .doc(driver.docId)
                            .update(data);
                      } else {
                        await _db.collection('drivers').add({
                          ...data,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      isEdit ? 'Save Changes' : 'Add Driver',
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

  Widget _formField(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
  }) =>
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

  // ── Delete confirm ───────────────────────────────────────────
  void _deleteDriver(Driver driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title:
            const Text('Delete Driver', style: TextStyle(color: Colors.white)),
        content: Text('Remove ${driver.name}?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _db.collection('drivers').doc(driver.docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Driver Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.redAccent),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<Driver>>(
        stream: _driverStream,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            );
          }

          // Error
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
                      'Error loading drivers:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            );
          }

          final allDrivers = snapshot.data ?? [];
          final filtered = _applyFilter(allDrivers);

          return Column(
            children: [
              // ── Search ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search drivers…',
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

              // ── Status chips (real counts) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['On Duty', 'Off Duty', 'On Leave'].map((s) {
                    final count = allDrivers.where((d) => d.status == s).length;
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

              // ── Driver cards ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_off_outlined,
                                color: Colors.white24, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _search.isEmpty
                                  ? 'No drivers found.\nTap + to add one.'
                                  : 'No drivers match "$_search".',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final d = filtered[i];
                          return GestureDetector(
                            onTap: () => _viewDriver(d),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor:
                                        Colors.redAccent.withOpacity(0.15),
                                    child: Text(
                                      d.name
                                          .split(' ')
                                          .map((e) => e[0])
                                          .take(2)
                                          .join(),
                                      style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(d.name,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15)),
                                        const SizedBox(height: 3),
                                        Text(d.assignedBus,
                                            style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 12)),
                                        const SizedBox(height: 5),
                                        Row(children: [
                                          const Icon(Icons.star,
                                              color: Colors.amber, size: 13),
                                          const SizedBox(width: 4),
                                          Text(d.rating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.work,
                                              color: Colors.white38, size: 13),
                                          const SizedBox(width: 4),
                                          Text('${d.experience} yrs',
                                              style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 12)),
                                        ]),
                                      ],
                                    ),
                                  ),

                                  // Status + actions
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _statusColor(d.status)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(d.status,
                                            style: TextStyle(
                                                color: _statusColor(d.status),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _openForm(driver: d),
                                            child: const Icon(Icons.edit,
                                                size: 16,
                                                color: Colors.white38),
                                          ),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: () => _deleteDriver(d),
                                            child: const Icon(
                                                Icons.delete_outline,
                                                size: 16,
                                                color: Colors.redAccent),
                                          ),
                                        ],
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver'),
      ),
    );
  }
}
