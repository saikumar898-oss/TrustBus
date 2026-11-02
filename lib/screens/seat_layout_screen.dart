// lib/screens/seat_layout_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/seat_model.dart';

// ─────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────
class SeatLayoutScreen extends StatefulWidget {
  final String busId;
  final String date; // "dd/MM/yyyy"
  final int totalSeats;
  final bool isSleeper;

  const SeatLayoutScreen({
    super.key,
    required this.busId,
    required this.date,
    required this.totalSeats,
    this.isSleeper = false,
  });

  @override
  State<SeatLayoutScreen> createState() => _SeatLayoutScreenState();
}

class _SeatLayoutScreenState extends State<SeatLayoutScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<SeatModel> _seats = [];
  StreamSubscription? _sub;
  bool _loading = true;
  bool _booking = false;

  SeatGender _genderFilter = SeatGender.any;

  // ── Two separate doc IDs ──────────────────────────────────────
  // seatAvailability: readable by all logged-in users (no personal data)
  // bookings:         readable only by the booking owner
  String get _availDocId =>
      '${widget.busId}_${widget.date.replaceAll('/', '-')}';

  String get _bookingDocId =>
      '${widget.busId}_${widget.date.replaceAll('/', '-')}_${_auth.currentUser?.uid ?? 'anon'}';

  // ─────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _subscribeRealTime();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────
  //  REAL-TIME LISTENER  (seatAvailability)
  // ─────────────────────────────────────────
  void _subscribeRealTime() {
    _sub = _db
        .collection('seatAvailability') // ← public seat map, no PII
        .doc(_availDocId)
        .snapshots()
        .listen(
      (snap) {
        final bookedRaw =
            snap.exists ? (snap.data()?['bookedSeats'] as List? ?? []) : [];
        final bookedNums = bookedRaw.map((e) => (e as num).toInt()).toSet();

        setState(() {
          if (_seats.isEmpty) {
            _seats = SeatModel.generateLayout(
              total: widget.totalSeats,
              isSleeper: widget.isSleeper,
              bookedNumbers: bookedNums,
            );
          } else {
            _seats = [
              for (final s in _seats)
                if (bookedNums.contains(s.number))
                  s.copyWith(isBooked: true, isSelected: false)
                else if (!s.isBooked)
                  s
                else
                  s.copyWith(isBooked: false),
            ];
          }
          _loading = false;
        });
      },
      onError: (_) => setState(() => _loading = false),
    );
  }

  // ─────────────────────────────────────────
  //  SEAT TOGGLE
  // ─────────────────────────────────────────
  void _toggleSeat(int number) {
    setState(() => _seats = _seats.toggleSeat(number));
  }

  // ─────────────────────────────────────────
  //  CONFIRM BOOKING
  // ─────────────────────────────────────────
  Future<void> _confirmBooking() async {
    final selected = _seats.selectedNumbers;
    if (selected.isEmpty) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please sign in to book seats.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _booking = true);

    try {
      final batch = _db.batch();

      // 1. Update seatAvailability (readable by all) ─────────────
      final availRef = _db.collection('seatAvailability').doc(_availDocId);
      batch.set(
        availRef,
        {
          'busId': widget.busId,
          'date': widget.date,
          'bookedSeats': FieldValue.arrayUnion(selected),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Write booking record (owner-only) ─────────────────────
      final bookingRef = _db.collection('bookings').doc(_bookingDocId);
      batch.set(
        bookingRef,
        {
          'userId': uid,
          'busId': widget.busId,
          'date': widget.date,
          'seatNumbers': FieldValue.arrayUnion(selected),
          'status': 'confirmed',
          'bookedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) return;
      _showSuccessDialog(selected);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Booking failed: $e'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _showSuccessDialog(List<int> seats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
          SizedBox(width: 10),
          Text('Booking Confirmed',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Text(
          'Seats ${seats.join(', ')} booked successfully!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final selectedSeats = _seats.selected;
    final selectedNums = _seats.selectedNumbers;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Seats',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.date,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : Column(
              children: [
                _buildLegend(),
                _buildGenderFilter(),
                _buildStatsRow(),

                // Bus front indicator
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                  child: Row(children: [
                    Expanded(
                        child: Divider(color: Colors.white12, endIndent: 8)),
                    const Icon(Icons.directions_bus,
                        color: Colors.redAccent, size: 16),
                    const Text(' Front',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Expanded(child: Divider(color: Colors.white12, indent: 8)),
                  ]),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _buildSeatGrid(),
                  ),
                ),

                if (selectedSeats.isNotEmpty) _buildBookingBar(selectedNums),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────
  //  LEGEND
  // ─────────────────────────────────────────
  Widget _buildLegend() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(Colors.white10, Colors.white24, 'Available'),
            const SizedBox(width: 20),
            _legendItem(Colors.redAccent.withValues(alpha: 0.25),
                Colors.redAccent, 'Selected'),
            const SizedBox(width: 20),
            _legendItem(
                Colors.white.withValues(alpha: 0.04), Colors.white12, 'Booked'),
          ],
        ),
      );

  Widget _legendItem(Color bg, Color border, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: border, width: 0.5),
            ),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      );

  // ─────────────────────────────────────────
  //  GENDER FILTER
  // ─────────────────────────────────────────
  Widget _buildGenderFilter() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Filter:',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(width: 10),
            _genderChip('All', SeatGender.any, Icons.people),
            const SizedBox(width: 8),
            _genderChip('Male', SeatGender.maleOnly, Icons.male),
            const SizedBox(width: 8),
            _genderChip('Female', SeatGender.femaleOnly, Icons.female),
          ],
        ),
      );

  Widget _genderChip(String label, SeatGender g, IconData icon) {
    final selected = _genderFilter == g;
    return GestureDetector(
      onTap: () => setState(() => _genderFilter = g),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blueAccent.withValues(alpha: 0.2)
              : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.blueAccent : Colors.white12,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 13, color: selected ? Colors.blueAccent : Colors.white38),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                color: selected ? Colors.blueAccent : Colors.white54,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  STATS ROW
  // ─────────────────────────────────────────
  Widget _buildStatsRow() {
    final total = widget.totalSeats;
    final bookedC = _seats.booked.length;
    final availC = _seats.available.length;
    final selectC = _seats.selectedCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stat('$total', 'Total', Colors.white38),
          _divider(),
          _stat('$availC', 'Available', Colors.greenAccent),
          _divider(),
          _stat('$bookedC', 'Booked', Colors.white24),
          _divider(),
          _stat('$selectC', 'Selected', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _stat(String n, String label, Color color) => Column(
        children: [
          Text(n,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label,
              style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      );

  Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white10,
      );

  // ─────────────────────────────────────────
  //  SEAT GRID
  // ─────────────────────────────────────────
  Widget _buildSeatGrid() {
    const seatsPerRow = 4;
    final rowCount = (widget.totalSeats / seatsPerRow).ceil();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          children: List.generate(rowCount, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('${row + 1}',
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 10)),
                  ),
                  const SizedBox(width: 4),
                  _buildSeat(row * seatsPerRow + 1),
                  const SizedBox(width: 6),
                  _buildSeat(row * seatsPerRow + 2),
                  const Expanded(child: SizedBox()),
                  _buildSeat(row * seatsPerRow + 3),
                  const SizedBox(width: 6),
                  _buildSeat(row * seatsPerRow + 4),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSeat(int seatNo) {
    if (seatNo > widget.totalSeats) {
      return SizedBox(
          width: widget.isSleeper ? 62 : 54,
          height: widget.isSleeper ? 44 : 50);
    }

    final seat = _seats.firstWhere(
      (s) => s.number == seatNo,
      orElse: () => SeatModel(number: seatNo),
    );

    final filterMatch = _genderFilter == SeatGender.any ||
        seat.gender == _genderFilter ||
        seat.gender == SeatGender.any;

    return _SeatTile(
      seat: seat,
      filterMatch: filterMatch,
      isSleeper: widget.isSleeper,
      onTap: () => _toggleSeat(seatNo),
    );
  }

  // ─────────────────────────────────────────
  //  BOOKING BAR
  // ─────────────────────────────────────────
  Widget _buildBookingBar(List<int> selectedNums) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${selectedNums.length} seat${selectedNums.length > 1 ? 's' : ''} selected',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Seats: ${selectedNums.join(', ')}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ]),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white12, size: 13),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _booking ? null : _confirmBooking,
              child: _booking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Confirm Booking · ${selectedNums.length} Seat${selectedNums.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  SEAT TILE WIDGET
// ─────────────────────────────────────────
class _SeatTile extends StatelessWidget {
  final SeatModel seat;
  final bool filterMatch;
  final bool isSleeper;
  final VoidCallback onTap;

  const _SeatTile({
    required this.seat,
    required this.filterMatch,
    required this.isSleeper,
    required this.onTap,
  });

  Color get _bgColor {
    if (!filterMatch) return Colors.white.withValues(alpha: 0.02);
    switch (seat.status) {
      case SeatStatus.booked:
        return Colors.white.withValues(alpha: 0.03);
      case SeatStatus.selected:
        return Colors.redAccent.withValues(alpha: 0.22);
      case SeatStatus.available:
        return Colors.white.withValues(alpha: 0.06);
    }
  }

  Color get _borderColor {
    if (!filterMatch) return Colors.white.withValues(alpha: 0.06);
    switch (seat.status) {
      case SeatStatus.booked:
        return Colors.white12;
      case SeatStatus.selected:
        return Colors.redAccent;
      case SeatStatus.available:
        return Colors.white24;
    }
  }

  Color get _iconColor {
    if (!filterMatch) return Colors.white.withValues(alpha: 0.1);
    switch (seat.status) {
      case SeatStatus.booked:
        return Colors.white12;
      case SeatStatus.selected:
        return Colors.redAccent;
      case SeatStatus.available:
        return Colors.white38;
    }
  }

  Color get _textColor {
    if (!filterMatch) return Colors.white.withValues(alpha: 0.1);
    switch (seat.status) {
      case SeatStatus.booked:
        return Colors.white12;
      case SeatStatus.selected:
        return Colors.redAccent;
      case SeatStatus.available:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBooked = seat.status == SeatStatus.booked;

    return GestureDetector(
      onTap: (isBooked || !filterMatch) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: isSleeper ? 62 : 54,
        height: isSleeper ? 44 : 50,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(isSleeper ? 6 : 9),
          border: Border.all(color: _borderColor, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isBooked
                  ? Icons.close
                  : isSleeper
                      ? Icons.bed_outlined
                      : Icons.event_seat,
              size: isSleeper ? 14 : 16,
              color: _iconColor,
            ),
            const SizedBox(height: 2),
            Text(
              '${seat.number}',
              style: TextStyle(
                color: _textColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (seat.isMaleOnly || seat.isFemaleOnly)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color:
                      seat.isMaleOnly ? Colors.blueAccent : Colors.pinkAccent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
