// lib/screens/bus_condition_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────
enum ConditionLevel { good, warning, critical }

extension ConditionLevelX on ConditionLevel {
  String get name {
    switch (this) {
      case ConditionLevel.good:
        return 'good';
      case ConditionLevel.warning:
        return 'warning';
      case ConditionLevel.critical:
        return 'critical';
    }
  }

  static ConditionLevel fromString(String s) {
    switch (s) {
      case 'warning':
        return ConditionLevel.warning;
      case 'critical':
        return ConditionLevel.critical;
      default:
        return ConditionLevel.good;
    }
  }
}

class BusConditionItem {
  String part;
  ConditionLevel level;
  String note;
  DateTime lastChecked;

  BusConditionItem({
    required this.part,
    required this.level,
    required this.note,
    required this.lastChecked,
  });

  factory BusConditionItem.fromMap(Map<String, dynamic> m) {
    DateTime checked = DateTime.now();
    if (m['lastChecked'] is Timestamp) {
      checked = (m['lastChecked'] as Timestamp).toDate();
    }
    return BusConditionItem(
      part: m['part'] ?? '',
      level: ConditionLevelX.fromString(m['level'] ?? 'good'),
      note: m['note'] ?? '',
      lastChecked: checked,
    );
  }

  Map<String, dynamic> toMap() => {
        'part': part,
        'level': level.name,
        'note': note,
        'lastChecked': Timestamp.fromDate(lastChecked),
      };
}

class BusConditionRecord {
  final String docId; // Firestore document ID in 'busConditions'
  final String busDocId; // Reference to fleet_buses doc
  final String busNumber;
  List<BusConditionItem> items;
  int overallScore;

  BusConditionRecord({
    required this.docId,
    required this.busDocId,
    required this.busNumber,
    required this.items,
    required this.overallScore,
  });

  factory BusConditionRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawItems = d['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => BusConditionItem.fromMap(e as Map<String, dynamic>))
        .toList();

    // Recalculate score from items if not stored
    int score = d['overallScore'] is int ? d['overallScore'] : 0;
    if (score == 0 && items.isNotEmpty) {
      final good = items.where((i) => i.level == ConditionLevel.good).length;
      score = ((good / items.length) * 100).round();
    }

    return BusConditionRecord(
      docId: doc.id,
      busDocId: d['busDocId'] ?? '',
      busNumber: d['busNumber'] ?? '',
      items: items,
      overallScore: score,
    );
  }

  Map<String, dynamic> toMap() {
    final good = items.where((i) => i.level == ConditionLevel.good).length;
    final score = items.isEmpty ? 0 : ((good / items.length) * 100).round();
    return {
      'busDocId': busDocId,
      'busNumber': busNumber,
      'items': items.map((i) => i.toMap()).toList(),
      'overallScore': score,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  int get recalcScore {
    if (items.isEmpty) return 0;
    final good = items.where((i) => i.level == ConditionLevel.good).length;
    return ((good / items.length) * 100).round();
  }
}

// ─────────────────────────────────────────
//  DEFAULT PARTS TEMPLATE
// ─────────────────────────────────────────
List<BusConditionItem> _defaultItems() => [
      BusConditionItem(
          part: 'Engine',
          level: ConditionLevel.good,
          note: '',
          lastChecked: DateTime.now()),
      BusConditionItem(
          part: 'Brakes',
          level: ConditionLevel.good,
          note: '',
          lastChecked: DateTime.now()),
      BusConditionItem(
          part: 'Tyres',
          level: ConditionLevel.good,
          note: '',
          lastChecked: DateTime.now()),
      BusConditionItem(
          part: 'Lights',
          level: ConditionLevel.good,
          note: '',
          lastChecked: DateTime.now()),
      BusConditionItem(
          part: 'AC System',
          level: ConditionLevel.good,
          note: '',
          lastChecked: DateTime.now()),
      BusConditionItem(
          part: 'Windshield',
          level: ConditionLevel.good,
          note: '',
          lastChecked: DateTime.now()),
      BusConditionItem(
          part: 'Seats',
          level: ConditionLevel.good,
          note: '',
          lastChecked: DateTime.now()),
      BusConditionItem(
          part: 'Doors',
          level: ConditionLevel.good,
          note: '',
          lastChecked: DateTime.now()),
    ];

// ─────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────
class BusConditionScreen extends StatefulWidget {
  const BusConditionScreen({super.key});

  @override
  State<BusConditionScreen> createState() => _BusConditionScreenState();
}

class _BusConditionScreenState extends State<BusConditionScreen> {
  final _db = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  bool _saving = false;

  // ── Stream from 'busConditions' collection ───────────────────
  Stream<List<BusConditionRecord>> get _recordStream => _db
      .collection('busConditions')
      .orderBy('busNumber')
      .snapshots()
      .map((snap) => snap.docs.map(BusConditionRecord.fromFirestore).toList());

  Color _levelColor(ConditionLevel l) {
    switch (l) {
      case ConditionLevel.good:
        return Colors.greenAccent;
      case ConditionLevel.warning:
        return Colors.orangeAccent;
      case ConditionLevel.critical:
        return Colors.redAccent;
    }
  }

  IconData _levelIcon(ConditionLevel l) {
    switch (l) {
      case ConditionLevel.good:
        return Icons.check_circle;
      case ConditionLevel.warning:
        return Icons.warning_amber_rounded;
      case ConditionLevel.critical:
        return Icons.cancel;
    }
  }

  String _levelLabel(ConditionLevel l) {
    switch (l) {
      case ConditionLevel.good:
        return 'Good';
      case ConditionLevel.warning:
        return 'Warning';
      case ConditionLevel.critical:
        return 'Critical';
    }
  }

  Color _scoreColor(int score) {
    if (score >= 75) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  // ── Save updated record to Firestore ────────────────────────
  Future<void> _saveRecord(BusConditionRecord record) async {
    await _db
        .collection('busConditions')
        .doc(record.docId)
        .update(record.toMap());
  }

  // ── Add a new condition record for a bus ────────────────────
  Future<void> _addRecord(String busNumber, String busDocId) async {
    final newRecord = {
      'busNumber': busNumber,
      'busDocId': busDocId,
      'items': _defaultItems().map((i) => i.toMap()).toList(),
      'overallScore': 100,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _db.collection('busConditions').add(newRecord);
  }

  // ── Update one condition item and persist ────────────────────
  void _updateCondition(BusConditionRecord record, BusConditionItem item) {
    ConditionLevel newLevel = item.level;
    final noteCtrl = TextEditingController(text: item.note);

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
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Update: ${item.part}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Condition Level',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: ConditionLevel.values.map((l) {
                  final selected = newLevel == l;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModal(() => newLevel = l),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? _levelColor(l).withOpacity(0.2)
                              : const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: _levelColor(l))
                              : null,
                        ),
                        child: Column(children: [
                          Icon(_levelIcon(l), color: _levelColor(l), size: 20),
                          const SizedBox(height: 4),
                          Text(_levelLabel(l),
                              style: TextStyle(
                                  color: _levelColor(l),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Notes',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  hintText: 'Add observation notes…',
                  hintStyle: const TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving
                      ? null
                      : () async {
                          // Mutate local item
                          item.level = newLevel;
                          item.note = noteCtrl.text.trim();
                          item.lastChecked = DateTime.now();

                          // Persist to Firestore
                          setState(() => _saving = true);
                          try {
                            await _saveRecord(record);
                          } finally {
                            setState(() => _saving = false);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Update',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Add new record dialog ────────────────────────────────────
  void _showAddDialog() {
    final busCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Add Condition Record',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the bus number to create a health record:',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextFormField(
              controller: busCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF374151),
                hintText: 'e.g. AP 09 Z 1234',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final busNumber = busCtrl.text.trim();
              if (busNumber.isEmpty) return;
              await _addRecord(busNumber, '');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.redAccent)),
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
        title: const Text('Bus Condition',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.redAccent),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<BusConditionRecord>>(
        stream: _recordStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.redAccent));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.build_circle_outlined,
                      color: Colors.white24, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'No condition records yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Record'),
                  ),
                ],
              ),
            );
          }

          // Clamp selected index in case records shrink
          final safeIndex = _selectedIndex.clamp(0, records.length - 1);
          final current = records[safeIndex];

          return Column(
            children: [
              // ── Bus Selector ─────────────────────────────
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: records.length,
                  itemBuilder: (_, i) {
                    final selected = i == safeIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.redAccent
                              : const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(records[i].busNumber,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white54,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                      ),
                    );
                  },
                ),
              ),

              // ── Score Card ───────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: current.recalcScore / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation(
                                  _scoreColor(current.recalcScore)),
                            ),
                            Center(
                              child: Text(
                                '${current.recalcScore}',
                                style: TextStyle(
                                  color: _scoreColor(current.recalcScore),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(current.busNumber,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 4),
                            const Text('Overall Health Score',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(children: [
                              _miniStat(Colors.greenAccent,
                                  '${current.items.where((i) => i.level == ConditionLevel.good).length} Good'),
                              const SizedBox(width: 10),
                              _miniStat(Colors.orangeAccent,
                                  '${current.items.where((i) => i.level == ConditionLevel.warning).length} Warn'),
                              const SizedBox(width: 10),
                              _miniStat(Colors.redAccent,
                                  '${current.items.where((i) => i.level == ConditionLevel.critical).length} Crit'),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Component List ───────────────────────────
              Expanded(
                child: current.items.isEmpty
                    ? const Center(
                        child: Text('No parts tracked yet.',
                            style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: current.items.length,
                        itemBuilder: (_, i) {
                          final item = current.items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(12),
                              border: item.level == ConditionLevel.critical
                                  ? Border.all(
                                      color: Colors.redAccent.withOpacity(0.4))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(_levelIcon(item.level),
                                    color: _levelColor(item.level), size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.part,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      if (item.note.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(item.note,
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12)),
                                      ],
                                      const SizedBox(height: 3),
                                      Text(
                                          'Last checked: ${_fmt(item.lastChecked)}',
                                          style: const TextStyle(
                                              color: Colors.white24,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note,
                                      color: Colors.white38),
                                  onPressed: () =>
                                      _updateCondition(current, item),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniStat(Color color, String label) => Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]);

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
