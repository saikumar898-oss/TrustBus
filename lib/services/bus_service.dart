// lib/services/bus_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_models.dart';

class BusService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Streams buses filtered by from, to, and operating day.
  /// [day] should be short format e.g. "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
  Stream<List<BusModel>> getBuses(String from, String to, String day) {
    Query<Map<String, dynamic>> query = _db
        .collection('buses')
        .where('from', isEqualTo: from)
        .where('to', isEqualTo: to);

    if (day.isNotEmpty) {
      query = query.where('days', arrayContains: day);
    }

    return query.snapshots().map(
          (snap) => snap.docs
              .map((doc) => BusModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Fetch a single bus by document ID — used in SeatLayoutScreen.
  Future<BusModel?> getBusById(String busId) async {
    final doc = await _db.collection('buses').doc(busId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BusModel.fromMap(doc.id, doc.data()!);
  }
}
