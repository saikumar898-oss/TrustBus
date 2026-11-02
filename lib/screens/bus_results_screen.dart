// lib/screens/bus_results_screen.dart

import 'package:flutter/material.dart';
import '../models/bus_models.dart';
import '../services/bus_service.dart';
import 'seat_layout_screen.dart';

class BusResultsScreen extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final String date;

  const BusResultsScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.date,
  });

  @override
  State<BusResultsScreen> createState() => _BusResultsScreenState();
}

class _BusResultsScreenState extends State<BusResultsScreen> {
  String selectedBusType = "All";
  String sortBy = "None";
  bool womenSafetyFilter = false;

  late final BusService _busService;
  late final String _day;

  @override
  void initState() {
    super.initState();
    _busService = BusService();
    _day = _getDay(widget.date);
  }

  String _getDay(String date) {
    try {
      final parts = date.split("/");
      if (parts.length != 3) return '';
      final parsed = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      return days[parsed.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Available Buses",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "${widget.fromCity} → ${widget.toCity} | ${widget.date}",
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: "Women Safety Filter",
            child: IconButton(
              icon: Icon(
                Icons.female_rounded,
                color: womenSafetyFilter
                    ? const Color(0xFFEC4899)
                    : Colors.white38,
                size: 26,
              ),
              onPressed: () =>
                  setState(() => womenSafetyFilter = !womenSafetyFilter),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<BusModel>>(
        stream: _busService.getBuses(widget.fromCity, widget.toCity, _day),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      "Couldn't load buses",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_bus_outlined,
                      color: Colors.white24, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    "No buses found",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No buses run on $_day between\n"
                    "${widget.fromCity} and ${widget.toCity}.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          List<BusModel> buses = snapshot.data!;

          // ── Filter by type ──
          List<BusModel> filteredBuses = buses.where((bus) {
            if (selectedBusType != "All" &&
                !bus.busType
                    .toLowerCase()
                    .contains(selectedBusType.toLowerCase())) {
              return false;
            }
            if (womenSafetyFilter && !(bus.hasWomenSeats ?? false)) {
              return false;
            }
            return true;
          }).toList();

          // ── Sort ──
          if (sortBy == "price_low") {
            filteredBuses.sort((a, b) => a.price.compareTo(b.price));
          } else if (sortBy == "price_high") {
            filteredBuses.sort((a, b) => b.price.compareTo(a.price));
          } else if (sortBy == "rating") {
            filteredBuses.sort((a, b) => b.rating.compareTo(a.rating));
          } else if (sortBy == "departure") {
            filteredBuses
                .sort((a, b) => a.departureTime.compareTo(b.departureTime));
          }

          return Column(
            children: [
              // Women Safety Banner
              if (womenSafetyFilter)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFFEC4899).withOpacity(0.12),
                  child: Row(
                    children: [
                      const Icon(Icons.female_rounded,
                          color: Color(0xFFEC4899), size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Showing buses with dedicated women-only seats & female co-driver",
                          style:
                              TextStyle(color: Color(0xFFEC4899), fontSize: 12),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => womenSafetyFilter = false),
                        child: const Icon(Icons.close,
                            color: Color(0xFFEC4899), size: 16),
                      ),
                    ],
                  ),
                ),

              // ── Filter + Sort bar ──
              Container(
                color: const Color(0xFF111111),
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      _filterChip("All"),
                      _filterChip("AC"),
                      _filterChip("Sleeper"),
                      _filterChip("Seater"),
                      const SizedBox(width: 6),
                      _divider(),
                      const SizedBox(width: 6),
                      _sortChip("₹ Low", "price_low"),
                      _sortChip("₹ High", "price_high"),
                      _sortChip("⭐ Rating", "rating"),
                      _sortChip("🕐 Early", "departure"),
                    ],
                  ),
                ),
              ),

              // ── Result count ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "${filteredBuses.length} bus${filteredBuses.length == 1 ? '' : 'es'} found",
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const Spacer(),
                    if (filteredBuses.isEmpty && selectedBusType != 'All')
                      GestureDetector(
                        onTap: () => setState(() => selectedBusType = 'All'),
                        child: const Text(
                          "Clear filter",
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              // ── List ──
              Expanded(
                child: filteredBuses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.filter_alt_off_outlined,
                                color: Colors.white24, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              womenSafetyFilter
                                  ? 'No buses with women-only seats on this route.'
                                  : 'No "$selectedBusType" buses on this route.',
                              style: const TextStyle(color: Colors.white38),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: filteredBuses.length,
                        itemBuilder: (context, index) {
                          final bus = filteredBuses[index];
                          return _BusCard(bus: bus, date: widget.date);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: Colors.white12,
        margin: const EdgeInsets.symmetric(vertical: 2),
      );

  Widget _filterChip(String label) {
    final selected = selectedBusType == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.redAccent.withOpacity(0.85),
        backgroundColor: const Color(0xFF1F1F1F),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.white54,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(color: selected ? Colors.redAccent : Colors.white12),
        onSelected: (_) => setState(() => selectedBusType = label),
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    final selected = sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.blueAccent.withOpacity(0.75),
        backgroundColor: const Color(0xFF1F1F1F),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.white54,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(color: selected ? Colors.blueAccent : Colors.white12),
        onSelected: (_) =>
            setState(() => sortBy = (sortBy == value) ? 'None' : value),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  BUS CARD
// ─────────────────────────────────────────
class _BusCard extends StatefulWidget {
  final BusModel bus;
  final String date;

  const _BusCard({required this.bus, required this.date});

  @override
  State<_BusCard> createState() => _BusCardState();
}

class _BusCardState extends State<_BusCard> {
  bool _expanded = false;

  String _getDuration(String start, String end) {
    try {
      final s = start.split(":");
      final e = end.split(":");
      DateTime startTime = DateTime(0, 0, 0, int.parse(s[0]), int.parse(s[1]));
      DateTime endTime = DateTime(0, 0, 0, int.parse(e[0]), int.parse(e[1]));
      if (endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }
      final diff = endTime.difference(startTime);
      return "${diff.inHours}h ${diff.inMinutes % 60}m";
    } catch (_) {
      return '--';
    }
  }

  Color get _typeColor {
    switch (widget.bus.busType) {
      case "AC Sleeper":
        return const Color(0xFF1565C0);
      case "AC Seater":
        return const Color(0xFF2E7D32);
      case "Sleeper":
        return const Color(0xFF6A1B9A);
      case "Non AC Sleeper":
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF37474F);
    }
  }

  Color _seatColor(int seats) {
    if (seats > 20) return Colors.green;
    if (seats > 10) return Colors.orange;
    return Colors.red;
  }

  Map<String, dynamic> _amenityData(String a) {
    switch (a) {
      case "wifi":
        return {"icon": Icons.wifi, "label": "WiFi"};
      case "charging":
        return {"icon": Icons.bolt, "label": "Charging"};
      case "water":
        return {"icon": Icons.opacity, "label": "Water"};
      case "blanket":
        return {"icon": Icons.airline_seat_flat, "label": "Blanket"};
      case "cctv":
        return {"icon": Icons.videocam_outlined, "label": "CCTV"};
      case "sos":
        return {"icon": Icons.emergency_outlined, "label": "SOS Button"};
      default:
        return {"icon": Icons.check_circle_outline, "label": a};
    }
  }

  String _cancellationPolicy(int price) {
    if (price > 800) return "Free cancellation up to 24h before";
    if (price > 400) return "50% refund up to 12h before";
    return "Non-refundable";
  }

  Color _cancellationColor(int price) {
    if (price > 800) return Colors.greenAccent;
    if (price > 400) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final bus = widget.bus;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFF111111),
      elevation: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(height: 3, color: _typeColor),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name + Rating ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                bus.busName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (bus.hasWomenSeats ?? false) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFEC4899).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: const Color(0xFFEC4899)
                                          .withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.female_rounded,
                                        color: Color(0xFFEC4899), size: 12),
                                    SizedBox(width: 2),
                                    Text(
                                      "Women Safe",
                                      style: TextStyle(
                                          color: Color(0xFFEC4899),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              bus.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    "${bus.from} → ${bus.to}",
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // ── Time + Duration ──
                  Row(
                    children: [
                      _timeChip(Icons.departure_board, bus.departureTime,
                          isDepart: true),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Expanded(
                                child: Divider(
                                    color: Colors.white12,
                                    endIndent: 6,
                                    indent: 6)),
                            Text(
                              _getDuration(bus.departureTime, bus.arrivalTime),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white38),
                            ),
                            const Expanded(
                                child: Divider(
                                    color: Colors.white12,
                                    endIndent: 6,
                                    indent: 6)),
                          ],
                        ),
                      ),
                      _timeChip(Icons.flag_outlined, bus.arrivalTime,
                          isDepart: false),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Live tracking status ──
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: (bus.isLive ?? false)
                                ? Colors.greenAccent
                                : Colors.white24,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (bus.isLive ?? false)
                              ? "Live • ${bus.currentLocation ?? 'En route'}"
                              : "Tracking starts at departure",
                          style: TextStyle(
                            fontSize: 11,
                            color: (bus.isLive ?? false)
                                ? Colors.greenAccent
                                : Colors.white38,
                          ),
                        ),
                        const Spacer(),
                        if (bus.isLive ?? false)
                          const Icon(Icons.my_location_outlined,
                              size: 13, color: Colors.greenAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Seats bar ──
                  Row(
                    children: [
                      const Icon(Icons.event_seat_outlined,
                          size: 13, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        "${bus.seats} seats",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white38),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1 - (bus.seats / 45).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor:
                                AlwaysStoppedAnimation(_seatColor(bus.seats)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bus.seats > 20
                            ? "Available"
                            : bus.seats > 10
                                ? "Filling fast"
                                : "Almost full",
                        style: TextStyle(
                          fontSize: 10,
                          color: _seatColor(bus.seats),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Bus type + Amenities ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: _typeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          bus.busType,
                          style: TextStyle(
                            color: _typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ...bus.amenities.map((a) {
                        final data = _amenityData(a);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: data["label"] as String,
                            child: Icon(
                              data["icon"] as IconData,
                              size: 16,
                              color: (a == "cctv" || a == "sos")
                                  ? const Color(0xFFEC4899).withOpacity(0.8)
                                  : Colors.white38,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Cancellation policy ──
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 13, color: _cancellationColor(bus.price)),
                      const SizedBox(width: 5),
                      Text(
                        _cancellationPolicy(bus.price),
                        style: TextStyle(
                          fontSize: 11,
                          color: _cancellationColor(bus.price),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Price + Buttons ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₹${bus.price}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4ADE80),
                            ),
                          ),
                          const Text(
                            "per seat",
                            style:
                                TextStyle(fontSize: 10, color: Colors.white38),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.white54,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            height: 42,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SeatLayoutScreen(
                                      busId: bus.id,
                                      date: widget.date,
                                      totalSeats: bus.seats,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Select Seat",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── Expandable section ──
                  if (_expanded) ...[
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 10),

                    // Women Safety Details
                    if (bus.hasWomenSeats ?? false) ...[
                      _sectionTitle(
                          Icons.female_rounded, "Women Safety Features",
                          color: const Color(0xFFEC4899)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _safetyChip(Icons.videocam_outlined, "CCTV Cameras"),
                          _safetyChip(Icons.emergency_outlined, "SOS Button"),
                          _safetyChip(
                              Icons.person_2_outlined, "Female Co-Driver"),
                          _safetyChip(Icons.airline_seat_recline_normal,
                              "Women-Only Rows"),
                          _safetyChip(
                              Icons.gps_fixed_outlined, "Live Location Shared"),
                          _safetyChip(Icons.shield_outlined, "Verified Crew"),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Boarding Points
                    if ((bus.boardingPoints ?? []).isNotEmpty) ...[
                      _sectionTitle(
                          Icons.location_on_outlined, "Boarding Points"),
                      const SizedBox(height: 8),
                      ...(bus.boardingPoints ?? [])
                          .map((p) => _stopRow(p, isBoarding: true)),
                      const SizedBox(height: 12),
                    ],

                    // Dropping Points
                    if ((bus.droppingPoints ?? []).isNotEmpty) ...[
                      _sectionTitle(
                          Icons.location_off_outlined, "Dropping Points"),
                      const SizedBox(height: 8),
                      ...(bus.droppingPoints ?? [])
                          .map((p) => _stopRow(p, isBoarding: false)),
                      const SizedBox(height: 12),
                    ],

                    // Passenger Reviews
                    if ((bus.reviews ?? []).isNotEmpty) ...[
                      _sectionTitle(
                          Icons.rate_review_outlined, "Passenger Reviews"),
                      const SizedBox(height: 8),
                      ...(bus.reviews ?? []).take(3).map(_reviewTile),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title,
      {Color color = Colors.white54}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _safetyChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFFEC4899)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFFEC4899),
                fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _stopRow(BusStop stop, {required bool isBoarding}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isBoarding ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 13,
            color: isBoarding ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stop.name,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            stop.time,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _reviewTile(BusReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: Colors.white12,
                child: Text(
                  review.name.isNotEmpty ? review.name[0].toUpperCase() : "?",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.name,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.stars ? Icons.star : Icons.star_border,
                    size: 12,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeChip(IconData icon, String time, {required bool isDepart}) {
    return Column(
      crossAxisAlignment:
          isDepart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          time,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white38),
            const SizedBox(width: 3),
            Text(
              isDepart ? "Departure" : "Arrival",
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
