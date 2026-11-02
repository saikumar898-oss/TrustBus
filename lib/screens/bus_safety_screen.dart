// lib/screens/bus_safety_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────
class SafetyCheck {
  final String docId;
  String busNumber;
  String checkType;
  String inspector;
  final DateTime date;
  String status; // 'Passed' | 'Failed' | 'Pending'
  String remarks;

  SafetyCheck({
    required this.docId,
    required this.busNumber,
    required this.checkType,
    required this.inspector,
    required this.date,
    required this.status,
    required this.remarks,
  });

  factory SafetyCheck.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Handle both Timestamp and String for date field
    DateTime parsedDate = DateTime.now();
    if (d['date'] is Timestamp) {
      parsedDate = (d['date'] as Timestamp).toDate();
    } else if (d['reportDate'] is String) {
      // fallback: parse "DD/MM/YYYY" or "YYYY-MM-DD"
      try {
        final parts = (d['reportDate'] as String).split('/');
        if (parts.length == 3) {
          parsedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
    }

    return SafetyCheck(
      docId: doc.id,
      busNumber: d['busNumber'] ?? '',
      checkType: d['checkType'] ?? d['type'] ?? '',
      inspector: d['inspector'] ?? d['reportedBy'] ?? '',
      date: parsedDate,
      status: d['status'] ?? d['reportStatus'] ?? 'Pending',
      remarks: d['remarks'] ?? d['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'busNumber': busNumber,
        'checkType': checkType,
        'inspector': inspector,
        'date': Timestamp.fromDate(date),
        'status': status,
        'remarks': remarks,
      };
}

// ─────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────
class BusSafetyScreen extends StatefulWidget {
  const BusSafetyScreen({super.key});

  @override
  State<BusSafetyScreen> createState() => _BusSafetyScreenState();
}

class _BusSafetyScreenState extends State<BusSafetyScreen> {
  final _db = FirebaseFirestore.instance;
  String _search = '';
  String _filterStatus = 'All';

  static const _statuses = ['All', 'Passed', 'Failed', 'Pending'];

  // ── Firestore stream ─────────────────────────────────────────
  // Reads from 'safetyChecks' collection.
  // If you want to read from 'safetyReports' instead, change the
  // collection name below to 'safetyReports'.
  Stream<List<SafetyCheck>> get _checkStream => _db
      .collection('safetyChecks')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(SafetyCheck.fromFirestore).toList());

  List<SafetyCheck> _applyFilter(List<SafetyCheck> checks) => checks.where((c) {
        final matchSearch =
            c.busNumber.toLowerCase().contains(_search.toLowerCase()) ||
                c.checkType.toLowerCase().contains(_search.toLowerCase()) ||
                c.inspector.toLowerCase().contains(_search.toLowerCase());
        final matchStatus = _filterStatus == 'All' || c.status == _filterStatus;
        return matchSearch && matchStatus;
      }).toList();

  Color _statusColor(String s) {
    switch (s) {
      case 'Passed':
        return Colors.greenAccent;
      case 'Failed':
        return Colors.redAccent;
      case 'Pending':
        return Colors.orangeAccent;
      default:
        return Colors.white;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Passed':
        return Icons.check_circle_outline;
      case 'Failed':
        return Icons.cancel_outlined;
      case 'Pending':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  // ── Add / Edit form ──────────────────────────────────────────
  void _openForm({SafetyCheck? check}) {
    final isEdit = check != null;
    final busCtrl = TextEditingController(text: check?.busNumber ?? '');
    final typeCtrl = TextEditingController(text: check?.checkType ?? '');
    final inspCtrl = TextEditingController(text: check?.inspector ?? '');
    final remCtrl = TextEditingController(text: check?.remarks ?? '');
    String status = check?.status ?? 'Pending';

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
                // Title row
                Row(
                  children: [
                    Text(
                      isEdit ? 'Edit Safety Check' : 'Add Safety Check',
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

                _field('Bus Number', busCtrl),
                _field('Check Type', typeCtrl),
                _field('Inspector Name', inspCtrl),
                _field('Remarks', remCtrl),
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
                  items: ['Passed', 'Failed', 'Pending']
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
                        'busNumber': busCtrl.text.trim(),
                        'checkType': typeCtrl.text.trim(),
                        'inspector': inspCtrl.text.trim(),
                        'remarks': remCtrl.text.trim(),
                        'status': status,
                      };

                      if (isEdit) {
                        await _db
                            .collection('safetyChecks')
                            .doc(check.docId)
                            .update(data);
                      } else {
                        await _db.collection('safetyChecks').add({
                          ...data,
                          'date': Timestamp.fromDate(DateTime.now()),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      isEdit ? 'Save Changes' : 'Add Check',
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

  Widget _field(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: ctrl,
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
  void _deleteCheck(SafetyCheck check) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title:
            const Text('Delete Check', style: TextStyle(color: Colors.white)),
        content: Text('Remove "${check.checkType}" for ${check.busNumber}?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _db.collection('safetyChecks').doc(check.docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Summary chips ────────────────────────────────────────────
  Widget _summaryChips(List<SafetyCheck> allChecks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['Passed', 'Failed', 'Pending'].map((s) {
          final count = allChecks.where((c) => c.status == s).length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: Icon(_statusIcon(s), size: 14, color: _statusColor(s)),
              label: Text('$s: $count',
                  style: TextStyle(color: _statusColor(s), fontSize: 12)),
              backgroundColor: const Color(0xFF1F2937),
              side: BorderSide(color: _statusColor(s).withValues(alpha: 0.4)),
            ),
          );
        }).toList(),
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
        title: const Text('Safety & Quality',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.redAccent),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<SafetyCheck>>(
        stream: _checkStream,
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
                      'Error loading safety checks:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            );
          }

          final allChecks = snapshot.data ?? [];
          final filtered = _applyFilter(allChecks);

          return Column(
            children: [
              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by bus, check type or inspector…',
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

              // ── Status Filter Tabs ──
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _statuses.map((s) {
                    final selected = _filterStatus == s;
                    return GestureDetector(
                      onTap: () => setState(() => _filterStatus = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.redAccent
                              : const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? Colors.redAccent : Colors.white24,
                          ),
                        ),
                        child: Text(s,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white54,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Summary Chips (real counts) ──
              _summaryChips(allChecks),
              const SizedBox(height: 8),

              // ── List ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_outlined,
                                color: Colors.white24, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _search.isEmpty && _filterStatus == 'All'
                                  ? 'No safety checks yet.\nTap + to add one.'
                                  : 'No checks match your filter.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final check = filtered[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _statusColor(check.status)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(check.status)
                                    .withValues(alpha: 0.15),
                                child: Icon(_statusIcon(check.status),
                                    color: _statusColor(check.status),
                                    size: 22),
                              ),
                              title: Text(check.checkType,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.directions_bus,
                                        size: 12, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text(check.busNumber,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ]),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    const Icon(Icons.person,
                                        size: 12, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text(check.inspector,
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.calendar_today,
                                        size: 12, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${check.date.day}/${check.date.month}/${check.date.year}',
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 12),
                                    ),
                                  ]),
                                  if (check.remarks.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(check.remarks,
                                        style: const TextStyle(
                                            color: Colors.white30,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(check.status)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(check.status,
                                        style: TextStyle(
                                            color: _statusColor(check.status),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _openForm(check: check),
                                        child: const Icon(Icons.edit,
                                            size: 18, color: Colors.white38),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => _deleteCheck(check),
                                        child: const Icon(Icons.delete_outline,
                                            size: 18, color: Colors.redAccent),
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
        icon: const Icon(Icons.add),
        label: const Text('Add Check'),
      ),
    );
  }
}
