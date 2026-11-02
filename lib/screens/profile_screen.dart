import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool loading = true;
  bool isEditing = false;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  bool saving = false;

  int totalBookings = 0;
  int confirmedTrips = 0;
  double totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadStats();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (doc.exists && mounted) {
      setState(() {
        userData = doc.data();
        nameCtrl.text = doc.data()?["name"] ?? "";
        phoneCtrl.text = doc.data()?["phone"] ?? "";
        loading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection("bookings")
          .where("userId", isEqualTo: uid)
          .get();

      int confirmed = 0;
      double spent = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['status'] == 'confirmed') {
          confirmed++;
          spent += (data['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          totalBookings = snap.docs.length;
          confirmedTrips = confirmed;
          totalSpent = spent;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (nameCtrl.text.trim().isEmpty) {
      _showSnack("Name cannot be empty");
      return;
    }

    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "name": nameCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        userData?["name"] = nameCtrl.text.trim();
        userData?["phone"] = phoneCtrl.text.trim();
        isEditing = false;
        saving = false;
      });

      _showSnack("Profile updated successfully");
    } catch (e) {
      setState(() => saving = false);
      _showSnack("Failed to update: $e");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to logout?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: const StadiumBorder()),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : CustomScrollView(
              slivers: [
                // ── Sliver App Bar ──────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: const Color(0xFF111827),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (!isEditing)
                      TextButton.icon(
                        icon: const Icon(Icons.edit,
                            color: Colors.redAccent, size: 16),
                        label: const Text("Edit",
                            style: TextStyle(color: Colors.redAccent)),
                        onPressed: () => setState(() => isEditing = true),
                      )
                    else
                      TextButton(
                        onPressed: () => setState(() => isEditing = false),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.white54)),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1E293B),
                            Color(0xFF0F172A),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Avatar
                          Stack(
                            children: [
                              () {
                                final pic = userData?["profilePic"] ?? "";
                                if (pic.isNotEmpty) {
                                  return CircleAvatar(
                                    radius: 46,
                                    backgroundImage: NetworkImage(pic),
                                  );
                                }
                                final name = userData?["name"] ?? "U";
                                final letter = name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : "U";
                                return CircleAvatar(
                                  radius: 46,
                                  backgroundColor:
                                      Colors.redAccent.withValues(alpha: 0.2),
                                  child: Text(
                                    letter,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }(),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFF0F172A),
                                        width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      size: 13, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userData?["name"] ?? "",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData?["email"] ?? "",
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats
                        _statsRow(),
                        const SizedBox(height: 24),

                        // Role badge
                        _roleBadge(),
                        const SizedBox(height: 20),

                        // Info / Edit card
                        isEditing ? _editCard() : _infoCard(),
                        const SizedBox(height: 24),

                        // Account section
                        _sectionTitle("Account"),
                        const SizedBox(height: 10),
                        _menuTile(Icons.confirmation_num_outlined,
                            "My Bookings", Colors.blueAccent, () {}),
                        _menuTile(Icons.history, "Trip History",
                            Colors.purpleAccent, () {}),
                        _menuTile(Icons.account_balance_wallet_outlined,
                            "Payments & Refunds", Colors.greenAccent, () {}),
                        _menuTile(Icons.star_outline, "Reviews Given",
                            Colors.orangeAccent, () {}),

                        const SizedBox(height: 20),

                        // Settings section
                        _sectionTitle("Settings"),
                        const SizedBox(height: 10),
                        _menuTile(Icons.notifications_outlined, "Notifications",
                            Colors.tealAccent, () {}),
                        _menuTile(Icons.lock_outline, "Change Password",
                            Colors.redAccent, () {}),
                        _menuTile(Icons.help_outline, "Help & Support",
                            Colors.white54, () {}),
                        _menuTile(Icons.info_outline, "About TrustBus",
                            Colors.white54, () {}),

                        const SizedBox(height: 24),

                        // Logout
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text("Logout",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.redAccent.withValues(alpha: 0.12),
                              foregroundColor: Colors.redAccent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                    color: Colors.redAccent
                                        .withValues(alpha: 0.3)),
                              ),
                            ),
                            onPressed: _confirmLogout,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // App version
                        const Center(
                          child: Text("TrustBus v1.0.0",
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 12)),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────
  // STATS ROW
  // ─────────────────────────────────────────
  Widget _statsRow() {
    return Row(
      children: [
        _statBox("${totalBookings}", "Bookings", Icons.confirmation_num,
            Colors.blueAccent),
        const SizedBox(width: 10),
        _statBox("${confirmedTrips}", "Trips Done", Icons.directions_bus,
            Colors.greenAccent),
        const SizedBox(width: 10),
        _statBox("₹${totalSpent.toStringAsFixed(0)}", "Spent",
            Icons.account_balance_wallet, Colors.orangeAccent),
      ],
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // ROLE BADGE
  // ─────────────────────────────────────────
  Widget _roleBadge() {
    final role = userData?["role"] ?? "customer";
    final isAdmin = role == "admin";
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAdmin
                ? Colors.orangeAccent.withValues(alpha: 0.12)
                : Colors.blueAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAdmin
                  ? Colors.orangeAccent.withValues(alpha: 0.3)
                  : Colors.blueAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: isAdmin ? Colors.orangeAccent : Colors.blueAccent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                isAdmin ? "Admin" : "Customer",
                style: TextStyle(
                    color: isAdmin ? Colors.orangeAccent : Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (userData?["username"] != null)
          Text(
            "@${userData!["username"]}",
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // INFO CARD (read-only)
  // ─────────────────────────────────────────
  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _infoTile(Icons.person_outline, "Full Name", userData?["name"] ?? ""),
          _divider(),
          _infoTile(Icons.email_outlined, "Email", userData?["email"] ?? ""),
          _divider(),
          _infoTile(Icons.phone_outlined, "Phone", userData?["phone"] ?? ""),
          _divider(),
          _infoTile(Icons.tag, "Username", "@${userData?["username"] ?? ""}"),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white54, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : "—",
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // EDIT CARD
  // ─────────────────────────────────────────
  Widget _editCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Edit Profile",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 16),
          _editField(Icons.person_outline, "Full Name", nameCtrl),
          const SizedBox(height: 12),
          _editField(Icons.phone_outlined, "Phone Number", phoneCtrl,
              keyboard: TextInputType.phone),
          const SizedBox(height: 4),
          Text(
            "Email cannot be changed",
            style: TextStyle(
                color: Colors.white38.withValues(alpha: 0.6), fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: const StadiumBorder(),
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Save Changes",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(
    IconData icon,
    String hint,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // MENU TILES
  // ─────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1));
  }

  Widget _menuTile(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: Colors.white12, height: 1),
      );
}
