// lib/dashboard/authority_dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../screens/manage_buses_screen.dart';
import '../screens/live_tracking_screen.dart';
import '../screens/bus_condition_screen.dart';
import '../screens/driver_details_screen.dart';
import '../screens/bus_safety_screen.dart';

class AuthorityDashboard extends StatefulWidget {
  const AuthorityDashboard({super.key});

  @override
  State<AuthorityDashboard> createState() => _AuthorityDashboardState();
}

class _AuthorityDashboardState extends State<AuthorityDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _hoveredIndex = -1;

  // ── Firestore ────────────────────────────────────────────────
  final _db = FirebaseFirestore.instance;

  // ── Live stat streams ────────────────────────────────────────
  Stream<int> get _activeCount => _db
      .collection('fleet_buses')
      .where('status', isEqualTo: 'Active')
      .snapshots()
      .map((s) => s.size);

  Stream<int> get _onRouteCount => _db
      .collection('fleet_buses')
      .where('status', isEqualTo: 'On Route')
      .snapshots()
      .map((s) => s.size);

  Stream<int> get _alertCount => _db
      .collection('fleet_buses')
      .where('status', isEqualTo: 'Maintenance')
      .snapshots()
      .map((s) => s.size);

  // ── Accent palette ───────────────────────────────────────────
  static const Color _bg = Color(0xFF080C14);
  static const Color _surface = Color(0xFF0E1420);
  static const Color _accent = Color(0xFF3B82F6);
  static const Color _green = Color(0xFF22C55E);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Dashboard items ──────────────────────────────────────────
  List<_DashItem> get _items => [
        _DashItem(
          icon: Icons.directions_bus_rounded,
          label: "Manage Buses",
          subtitle: "Fleet overview",
          color: _accent,
          onTap: () => _push(const ManageBusesScreen()),
        ),
        _DashItem(
          icon: Icons.person_pin_rounded,
          label: "Driver Details",
          subtitle: "Staff records",
          color: const Color(0xFF8B5CF6),
          onTap: () => _push(const DriverDetailsScreen()),
        ),
        _DashItem(
          icon: Icons.alt_route_rounded,
          label: "Bus Routes",
          subtitle: "Route planning",
          color: _green,
          onTap: () {},
        ),
        _DashItem(
          icon: Icons.my_location_rounded,
          label: "Live Tracking",
          subtitle: "Real-time GPS",
          color: const Color(0xFF06B6D4),
          isLive: true,
          onTap: () => _push(const LiveTrackingScreen()),
        ),
        _DashItem(
          icon: Icons.build_circle_rounded,
          label: "Maintenance",
          subtitle: "Service logs",
          color: _amber,
          onTap: () {},
        ),
        _DashItem(
          icon: Icons.bar_chart_rounded,
          label: "Reports",
          subtitle: "Analytics",
          color: const Color(0xFFEC4899),
          onTap: () {},
        ),
        _DashItem(
          icon: Icons.event_seat_rounded,
          label: "Seat Availability",
          subtitle: "Occupancy map",
          color: const Color(0xFF10B981),
          onTap: () {},
        ),
        _DashItem(
          icon: Icons.warning_amber_rounded,
          label: "Bus Condition",
          subtitle: "Health checks",
          color: _red,
          onTap: () => _push(const BusConditionScreen()),
        ),
        _DashItem(
          icon: Icons.verified_user_rounded,
          label: "Safety & Quality",
          subtitle: "Compliance",
          color: _green,
          onTap: () => _push(const BusSafetyScreen()),
        ),
        _DashItem(
          icon: Icons.tune_rounded,
          label: "Settings",
          subtitle: "Configuration",
          color: _textSecondary,
          onTap: () {},
        ),
      ];

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── TOP APP BAR ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _GridPainter()),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _accent.withValues(alpha: 0.15),
                          _surface,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 60,
                      20,
                      16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: _accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Authority Panel",
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "TrustBus Control",
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _IconBtn(
                          icon: Icons.logout_rounded,
                          onTap: () async => await auth.logout(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── STATS ROW (live from Firestore) ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Row(
                children: [
                  _LiveStatChip(
                    label: "Active Buses",
                    stream: _activeCount,
                    color: _green,
                  ),
                  const SizedBox(width: 10),
                  _LiveStatChip(
                    label: "On Route",
                    stream: _onRouteCount,
                    color: _accent,
                  ),
                  const SizedBox(width: 10),
                  _LiveStatChip(
                    label: "Alerts",
                    stream: _alertCount,
                    color: _red,
                  ),
                ],
              ),
            ),
          ),

          // ── SECTION LABEL ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── GRID ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _items[index];
                  final delay = index * 0.06;

                  return AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final progress = Curves.easeOutCubic.transform(
                        ((_animController.value - delay) / (1 - delay))
                            .clamp(0.0, 1.0),
                      );
                      return Opacity(
                        opacity: progress,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - progress)),
                          child: child,
                        ),
                      );
                    },
                    child: _DashCard(
                      item: item,
                      isHovered: _hoveredIndex == index,
                      onHover: (v) =>
                          setState(() => _hoveredIndex = v ? index : -1),
                    ),
                  );
                },
                childCount: _items.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size.width > 900
                    ? 4
                    : size.width > 600
                        ? 3
                        : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── LIVE STAT CHIP (reads from Firestore stream) ─────────────────

class _LiveStatChip extends StatelessWidget {
  final String label;
  final Stream<int> stream;
  final Color color;

  const _LiveStatChip({
    required this.label,
    required this.stream,
    required this.color,
  });

  static const Color _card = Color(0xFF121929);
  static const Color _border = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 1),
        ),
        child: StreamBuilder<int>(
          stream: stream,
          builder: (context, snapshot) {
            final value = snapshot.data ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.connectionState == ConnectionState.waiting
                      ? '—'
                      : '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── DASHBOARD CARD ───────────────────────────────────────────────

class _DashItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isLive;
  final VoidCallback onTap;

  const _DashItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLive = false,
  });
}

class _DashCard extends StatelessWidget {
  final _DashItem item;
  final bool isHovered;
  final ValueChanged<bool> onHover;

  static const Color _card = Color(0xFF121929);
  static const Color _cardHover = Color(0xFF172033);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFF1E293B);

  const _DashCard({
    required this.item,
    required this.isHovered,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isHovered ? _cardHover : _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHovered ? item.color.withValues(alpha: 0.35) : _border,
              width: 1.5,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              if (isHovered)
                Positioned(
                  top: -10,
                  left: -10,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.color.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item.color
                                .withValues(alpha: isHovered ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: item.color, size: 22),
                        ),
                        const Spacer(),
                        if (item.isLive) const _LiveDot(),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isHovered
                            ? _textPrimary
                            : _textPrimary.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SMALL WIDGETS ────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFF064E3B),
            const Color(0xFF022C22),
            _ctrl.value,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              "LIVE",
              style: TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155), width: 1),
        ),
        child: const Icon(Icons.logout_rounded,
            color: Color(0xFF94A3B8), size: 18),
      ),
    );
  }
}

// ── GRID BACKGROUND PAINTER ──────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    const spacing = 32.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
