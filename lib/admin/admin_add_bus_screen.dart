// lib/admin/admin_add_bus_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────
const _kBg = Color(0xFF0F172A);
const _kCard = Color(0xFF1F2937);
const _kField = Color(0xFF374151);
const _kAccent = Colors.redAccent;

const _busTypes = [
  'AC Sleeper',
  'Non AC Sleeper',
  'AC Seater',
  'Non AC Seater',
  'Sleeper',
];

const _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _allAmenities = ['wifi', 'charging', 'water'];

const _cities = [
  'Hyderabad',
  'Bangalore',
  'Chennai',
  'Mumbai',
  'Pune',
  'Delhi',
  'Vijayawada',
  'Visakhapatnam',
  'Kochi',
  'Trivandrum',
  'Thiruvananthapuram',
  'Coimbatore',
  'Mysore',
  'Nagpur',
  'Tirupati',
  'Jaipur',
  'Lucknow',
  'Ahmedabad',
  'Agra',
  'Chandigarh',
  'Amritsar',
  'Dehradun',
  'Goa',
  'Mangalore',
  'Madurai',
  'Kozhikode',
  'Kolkata',
  'Bhubaneswar',
];

// ─────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────
class AdminAddBusScreen extends StatefulWidget {
  const AdminAddBusScreen({super.key});

  @override
  State<AdminAddBusScreen> createState() => _AdminAddBusScreenState();
}

class _AdminAddBusScreenState extends State<AdminAddBusScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _busNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController();
  final _depCtrl = TextEditingController();
  final _arrCtrl = TextEditingController();

  // Dropdowns / toggles
  String? _from;
  String? _to;
  String _busType = 'AC Sleeper';
  final Set<String> _selectedDays = {
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  };
  final Set<String> _selectedAmenities = {'wifi', 'charging', 'water'};

  bool _isLoading = false;

  @override
  void dispose() {
    _busNameCtrl.dispose();
    _priceCtrl.dispose();
    _seatsCtrl.dispose();
    _ratingCtrl.dispose();
    _depCtrl.dispose();
    _arrCtrl.dispose();
    super.dispose();
  }

  // ── Auto-fill amenities when bus type changes ──
  void _onBusTypeChanged(String? val) {
    if (val == null) return;
    setState(() {
      _busType = val;
      _selectedAmenities.clear();
      if (val == 'AC Sleeper') {
        _selectedAmenities.addAll(['wifi', 'charging', 'water']);
      } else if (val == 'AC Seater') {
        _selectedAmenities.addAll(['charging', 'water']);
      } else if (val == 'Sleeper') {
        _selectedAmenities.add('water');
      }
      // Non-AC types: no amenities by default
    });
  }

  // ── Time picker ──
  Future<void> _pickTime(TextEditingController ctrl) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kAccent,
            surface: _kCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      ctrl.text = '$h:$m';
    }
  }

  // ── Submit ──
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_from == null || _to == null) {
      _snack('Please select From and To cities.', isError: true);
      return;
    }
    if (_from == _to) {
      _snack('From and To cities cannot be the same.', isError: true);
      return;
    }
    if (_selectedDays.isEmpty) {
      _snack('Select at least one operating day.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('buses').add({
        'busName': _busNameCtrl.text.trim(),
        'from': _from,
        'to': _to,
        'departureTime': _depCtrl.text.trim(),
        'arrivalTime': _arrCtrl.text.trim(),
        'price': int.parse(_priceCtrl.text.trim()),
        'seats': int.parse(_seatsCtrl.text.trim()),
        'busType': _busType,
        'rating': double.parse(_ratingCtrl.text.trim()),
        'days': _selectedDays.toList(),
        'amenities': _selectedAmenities.toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _snack('Bus added successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
    ));
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Add New Bus',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: _kAccent, strokeWidth: 2))),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Bus Name ──
            _sectionLabel('Bus Operator Name'),
            _textField(
              controller: _busNameCtrl,
              hint: 'e.g. VRL Travels',
              validator: (v) => v!.trim().isEmpty ? 'Enter bus name' : null,
            ),
            const SizedBox(height: 20),

            // ── From / To ──
            _sectionLabel('Route'),
            Row(children: [
              Expanded(
                child: _cityDropdown(
                  label: 'From',
                  value: _from,
                  onChanged: (v) => setState(() => _from = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _cityDropdown(
                  label: 'To',
                  value: _to,
                  onChanged: (v) => setState(() => _to = v),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Departure / Arrival ──
            _sectionLabel('Timings'),
            Row(children: [
              Expanded(
                child: _timeField(
                  label: 'Departure',
                  ctrl: _depCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeField(
                  label: 'Arrival',
                  ctrl: _arrCtrl,
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Price / Seats / Rating ──
            _sectionLabel('Details'),
            Row(children: [
              Expanded(
                child: _textField(
                  controller: _priceCtrl,
                  hint: 'Price (₹)',
                  keyboard: TextInputType.number,
                  validator: (v) {
                    if (v!.trim().isEmpty) return 'Enter price';
                    if (int.tryParse(v.trim()) == null) return 'Numbers only';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  controller: _seatsCtrl,
                  hint: 'Seats',
                  keyboard: TextInputType.number,
                  validator: (v) {
                    if (v!.trim().isEmpty) return 'Enter seats';
                    if (int.tryParse(v.trim()) == null) return 'Numbers only';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  controller: _ratingCtrl,
                  hint: 'Rating',
                  keyboard:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v!.trim().isEmpty) return 'Enter rating';
                    final r = double.tryParse(v.trim());
                    if (r == null || r < 0 || r > 5) return '0.0 – 5.0';
                    return null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Bus Type ──
            _sectionLabel('Bus Type'),
            _dropdownField<String>(
              value: _busType,
              items: _busTypes,
              onChanged: _onBusTypeChanged,
            ),
            const SizedBox(height: 20),

            // ── Operating Days ──
            _sectionLabel('Operating Days'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allDays.map((day) {
                final selected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => setState(() {
                    selected
                        ? _selectedDays.remove(day)
                        : _selectedDays.add(day);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          selected ? _kAccent.withValues(alpha: 0.2) : _kField,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? _kAccent : Colors.white12,
                      ),
                    ),
                    child: Text(day,
                        style: TextStyle(
                          color: selected ? _kAccent : Colors.white54,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              TextButton(
                onPressed: () => setState(() => _selectedDays.addAll(_allDays)),
                child: const Text('All', style: TextStyle(color: _kAccent)),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedDays.clear()),
                child:
                    const Text('None', style: TextStyle(color: Colors.white38)),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Amenities ──
            _sectionLabel('Amenities'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allAmenities.map((a) {
                final selected = _selectedAmenities.contains(a);
                final icon = a == 'wifi'
                    ? Icons.wifi
                    : a == 'charging'
                        ? Icons.bolt
                        : Icons.opacity;
                final label = a == 'wifi'
                    ? 'WiFi'
                    : a == 'charging'
                        ? 'Charging'
                        : 'Water';
                return GestureDetector(
                  onTap: () => setState(() {
                    selected
                        ? _selectedAmenities.remove(a)
                        : _selectedAmenities.add(a);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.blueAccent.withValues(alpha: 0.15)
                          : _kField,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? Colors.blueAccent : Colors.white12,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon,
                          size: 14,
                          color: selected ? Colors.blueAccent : Colors.white38),
                      const SizedBox(width: 6),
                      Text(label,
                          style: TextStyle(
                            color:
                                selected ? Colors.blueAccent : Colors.white54,
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          )),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // ── Preview Card ──
            _previewCard(),
            const SizedBox(height: 24),

            // ── Submit ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: const Text('Add Bus to Firestore',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  PREVIEW CARD
  // ─────────────────────────────────────────
  Widget _previewCard() {
    final name = _busNameCtrl.text.trim();
    final dep = _depCtrl.text.trim();
    final arr = _arrCtrl.text.trim();
    final pr = _priceCtrl.text.trim();
    final st = _seatsCtrl.text.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name.isEmpty ? 'Bus name' : name,
                style: TextStyle(
                  color: name.isEmpty ? Colors.white24 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                pr.isEmpty ? '₹ —' : '₹$pr',
                style: TextStyle(
                  color: pr.isEmpty ? Colors.white24 : _kAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Text(dep.isEmpty ? '--:--' : dep,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            Expanded(
              child: Column(children: [
                Text(_busType,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: Container(height: 1, color: Colors.white12)),
                  const Icon(Icons.arrow_forward,
                      size: 12, color: Colors.white24),
                ]),
              ]),
            ),
            Text(arr.isEmpty ? '--:--' : arr,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (_from != null)
              Text(_from!,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const Spacer(),
            if (_to != null)
              Text(_to!,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (st.isNotEmpty) ...[
              const Icon(Icons.event_seat, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Text('$st seats',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 12),
            ],
            ..._selectedAmenities.map((a) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    a == 'wifi'
                        ? Icons.wifi
                        : a == 'charging'
                            ? Icons.bolt
                            : Icons.opacity,
                    size: 14,
                    color: Colors.white38,
                  ),
                )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Text(_busType,
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          if (_selectedDays.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _selectedDays.length == 7
                  ? 'Runs every day'
                  : 'Runs on: ${_selectedDays.join(', ')}',
              style: const TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  HELPER WIDGETS
  // ─────────────────────────────────────────
  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}), // live preview update
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: _kField,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            errorStyle: const TextStyle(color: Colors.orangeAccent),
          ),
        ),
      );

  Widget _timeField({
    required String label,
    required TextEditingController ctrl,
  }) =>
      GestureDetector(
        onTap: () => _pickTime(ctrl),
        child: AbsorbPointer(
          child: TextFormField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            validator: (v) => v!.trim().isEmpty ? 'Pick $label time' : null,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: _kField,
              suffixIcon: const Icon(Icons.access_time,
                  color: Colors.white38, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              errorStyle: const TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ),
      );

  Widget _cityDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: _kCard,
        style: const TextStyle(color: Colors.white),
        hint: Text(label, style: const TextStyle(color: Colors.white24)),
        validator: (v) => v == null ? 'Select $label' : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: _kField,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          errorStyle: const TextStyle(color: Colors.orangeAccent),
        ),
        items: _cities
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) {
          onChanged(v);
          setState(() {});
        },
      );

  Widget _dropdownField<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        value: value,
        dropdownColor: _kCard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: _kField,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        ),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i.toString())))
            .toList(),
        onChanged: onChanged,
      );
}
