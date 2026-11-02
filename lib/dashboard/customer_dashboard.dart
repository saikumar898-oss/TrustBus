import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/profile_screen.dart';
import '../screens/bus_results_screen.dart';
import '../screens/live_tracking_screen.dart';
import '../data/cities.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String fromCity = "";
  String toCity = "";
  DateTime? selectedDate;
  String userName = "";
  String userEmail = "";
  String profilePic = "";
  int activeBookings = 0;
  int totalTrips = 0;

  final ScrollController offerController = ScrollController();
  Timer? offerTimer;

  final List<Map<String, dynamic>> offers = [
    {
      "title": "Flat ₹100 OFF",
      "code": "FIRST100",
      "gradient": [Color(0xFFEF4444), Color(0xFFF97316)],
      "icon": Icons.local_offer,
    },
    {
      "title": "20% Weekend Discount",
      "code": "WEEKEND20",
      "gradient": [Color(0xFF7C3AED), Color(0xFFEC4899)],
      "icon": Icons.weekend,
    },
    {
      "title": "Student Offer",
      "code": "STUDENT15",
      "gradient": [Color(0xFF0EA5E9), Color(0xFF6366F1)],
      "icon": Icons.school,
    },
    {
      "title": "Festival Special",
      "code": "FEST50",
      "gradient": [Color(0xFFF59E0B), Color(0xFFEF4444)],
      "icon": Icons.celebration,
    },
    {
      "title": "₹200 Cashback",
      "code": "CASH200",
      "gradient": [Color(0xFF10B981), Color(0xFF0EA5E9)],
      "icon": Icons.account_balance_wallet,
    },
  ];

  final List<Map<String, dynamic>> quickActions = [
    {
      "label": "Live Track",
      "icon": Icons.location_on,
      "color": Color(0xFF22C55E),
    },
    {
      "label": "My Bookings",
      "icon": Icons.confirmation_num,
      "color": Color(0xFF3B82F6),
    },
    {
      "label": "Cancel Ticket",
      "icon": Icons.cancel,
      "color": Color(0xFFEF4444),
    },
    {
      "label": "Support",
      "icon": Icons.headset_mic,
      "color": Color(0xFFF59E0B),
    },
  ];

  List<Map<String, dynamic>> recentBookings = [];
  bool loadingBookings = true;

  @override
  void initState() {
    super.initState();
    loadUser();
    loadRecentBookings();

    offerTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (offerController.hasClients) {
        offerController.jumpTo(offerController.offset + 1);
        if (offerController.offset >=
            offerController.position.maxScrollExtent) {
          offerController.jumpTo(0);
        }
      }
    });
  }

  @override
  void dispose() {
    offerController.dispose();
    offerTimer?.cancel();
    super.dispose();
  }

  Future<void> loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        userName = doc.data()?["name"] ?? "";
        userEmail = doc.data()?["email"] ?? "";
        profilePic = doc.data()?["profilePic"] ?? "";
      });
    }
  }

  Future<void> loadRecentBookings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection("bookings")
          .where("userId", isEqualTo: uid)
          .orderBy("createdAt", descending: true)
          .limit(3)
          .get();

      if (mounted) {
        setState(() {
          recentBookings =
              snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          activeBookings = recentBookings
              .where(
                  (b) => b['status'] == 'confirmed' || b['status'] == 'pending')
              .length;
          totalTrips = snap.docs.length;
          loadingBookings = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingBookings = false);
    }
  }

  String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  void swapCities() {
    setState(() {
      final temp = fromCity;
      fromCity = toCity;
      toCity = temp;
    });
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.redAccent,
              surface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => selectedDate = date);
  }

  String formattedDate() {
    if (selectedDate == null) return "";
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return "${selectedDate!.day} ${months[selectedDate!.month - 1]} ${selectedDate!.year}";
  }

  String formattedDateForQuery() {
    if (selectedDate == null) return "";
    return "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";
  }

  Color _bookingStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.greenAccent;
      case 'pending':
        return Colors.orangeAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white38;
    }
  }

  IconData _bookingStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _header(),
              const SizedBox(height: 20),
              _statsRow(),
              const SizedBox(height: 24),
              _hero(),
              const SizedBox(height: 20),
              _searchCard(),
              const SizedBox(height: 28),
              _quickActionsRow(),
              const SizedBox(height: 28),
              _specialOffers(),
              const SizedBox(height: 28),
              _recentBookingsSection(),
              const SizedBox(height: 28),
              _popularRoutes(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────
  Widget _header() {
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

    return Row(
      children: [
        // Logo
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_bus,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              "TrustBus",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        const Spacer(),
        // Notification bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white70),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        // Avatar
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: profilePic.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: NetworkImage(profilePic),
                  radius: 18,
                )
              : CircleAvatar(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.3),
                  radius: 18,
                  child: Text(firstLetter,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
        ),
        IconButton(
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // STATS ROW
  // ─────────────────────────────────────────
  Widget _statsRow() {
    return Row(
      children: [
        _statCard("Active Bookings", activeBookings.toString(),
            Icons.confirmation_num, Colors.greenAccent),
        const SizedBox(width: 12),
        _statCard("Total Trips", totalTrips.toString(), Icons.directions_bus,
            Colors.blueAccent),
        const SizedBox(width: 12),
        _statCard("Saved", "₹350", Icons.savings, Colors.orangeAccent),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────
  Widget _hero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${greeting()}, ${userName.isNotEmpty ? userName.split(' ').first : 'Traveller'} 👋",
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 6),
        const Text(
          "Where are you\nheaded today?",
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // SEARCH CARD
  // ─────────────────────────────────────────
  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _cityField(Icons.my_location, "From", fromCity,
              (val) => setState(() => fromCity = val)),
          const SizedBox(height: 10),
          // Divider with swap button
          Row(
            children: [
              Expanded(
                  child: Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      thickness: 1)),
              GestureDetector(
                onTap: swapCities,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.swap_vert,
                      color: Colors.white, size: 18),
                ),
              ),
              Expanded(
                  child: Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      thickness: 1)),
            ],
          ),
          const SizedBox(height: 10),
          _cityField(Icons.location_on_outlined, "To", toCity,
              (val) => setState(() => toCity = val)),
          const SizedBox(height: 12),
          _dateField(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search, size: 20),
              label: const Text("Search Buses",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () {
                if (fromCity.isEmpty ||
                    toCity.isEmpty ||
                    selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please select cities and date")),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BusResultsScreen(
                      fromCity: fromCity,
                      toCity: toCity,
                      date: formattedDateForQuery(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityField(
    IconData icon,
    String hint,
    String initialValue,
    ValueChanged<String> onChanged,
  ) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return cities;
        return cities.where(
          (city) => city.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      onSelected: (selection) => onChanged(selection),
      fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
        return TextField(
          controller: textCtrl,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70, size: 20),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: pickDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(
              selectedDate == null ? "Select Travel Date" : formattedDate(),
              style: TextStyle(
                  color: selectedDate == null ? Colors.white38 : Colors.white,
                  fontSize: 15),
            ),
            const Spacer(),
            if (selectedDate != null)
              const Icon(Icons.check_circle,
                  color: Colors.greenAccent, size: 18),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // QUICK ACTIONS
  // ─────────────────────────────────────────
  Widget _quickActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions",
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: quickActions.map((action) {
            return GestureDetector(
              onTap: () {
                if (action['label'] == 'Live Track') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LiveTrackingScreen()),
                  );
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: (action['color'] as Color)
                              .withValues(alpha: 0.25)),
                    ),
                    child: Icon(action['icon'] as IconData,
                        color: action['color'] as Color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['label'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // SPECIAL OFFERS
  // ─────────────────────────────────────────
  Widget _specialOffers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Special Offers",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text("See all",
                  style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            controller: offerController,
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: offer["gradient"] as List<Color>,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(offer["icon"] as IconData,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          offer["title"] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            offer["code"] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 1),
                          ),
                        ),
                        const Spacer(),
                        const Text("Tap to copy",
                            style:
                                TextStyle(color: Colors.white60, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // RECENT BOOKINGS
  // ─────────────────────────────────────────
  Widget _recentBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent Bookings",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text("View all",
                  style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        loadingBookings
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                      color: Colors.redAccent, strokeWidth: 2),
                ),
              )
            : recentBookings.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.confirmation_num_outlined,
                              color: Colors.white24, size: 36),
                          SizedBox(height: 10),
                          Text("No bookings yet",
                              style: TextStyle(color: Colors.white38)),
                          SizedBox(height: 4),
                          Text("Your trip history will appear here",
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: recentBookings.map((booking) {
                      final status = booking['status'] ?? 'pending';
                      final statusColor = _bookingStatusColor(status);
                      final statusIcon = _bookingStatusIcon(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.directions_bus,
                                  color: Colors.redAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${booking['from'] ?? ''} → ${booking['to'] ?? ''}",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    booking['journeyDate'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Icon(statusIcon,
                                        color: statusColor, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      status[0].toUpperCase() +
                                          status.substring(1),
                                      style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${booking['amount'] ?? ''}",
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // POPULAR ROUTES
  // ─────────────────────────────────────────
  Widget _popularRoutes() {
    final routes = [
      {
        "from": "Hyderabad",
        "to": "Bangalore",
        "duration": "8h",
        "from_short": "HYD",
        "to_short": "BLR"
      },
      {
        "from": "Mumbai",
        "to": "Pune",
        "duration": "3h",
        "from_short": "MUM",
        "to_short": "PNQ"
      },
      {
        "from": "Chennai",
        "to": "Coimbatore",
        "duration": "5h",
        "from_short": "CHN",
        "to_short": "CBE"
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Popular Routes",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text("More",
                  style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...routes.map((route) => GestureDetector(
              onTap: () {
                setState(() {
                  fromCity = route['from']!;
                  toCity = route['to']!;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("${route['from']} → ${route['to']} selected")),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    // From badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        route['from_short']!,
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 30,
                                child: Divider(
                                    color: Colors.white24, thickness: 1),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  route['duration']!,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11),
                                ),
                              ),
                              const SizedBox(
                                width: 30,
                                child: Divider(
                                    color: Colors.white24, thickness: 1),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                route['from']!,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11),
                              ),
                              const Text(" → ",
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                              Text(
                                route['to']!,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // To badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        route['to_short']!,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white24, size: 14),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
