// lib/models/seat_model.dart

enum SeatType { seater, sleeper }

enum SeatStatus { available, selected, booked }

enum SeatGender { any, maleOnly, femaleOnly }

class SeatModel {
  final int number;
  final SeatType seatType;
  final SeatGender gender;
  final bool isBooked;
  final bool isSelected;

  const SeatModel({
    required this.number,
    this.seatType = SeatType.seater,
    this.gender = SeatGender.any,
    this.isBooked = false,
    this.isSelected = false,
  });

  // ── Computed ──
  SeatStatus get status {
    if (isBooked) return SeatStatus.booked;
    if (isSelected) return SeatStatus.selected;
    return SeatStatus.available;
  }

  bool get isAvailable => status == SeatStatus.available;
  bool get isMaleOnly => gender == SeatGender.maleOnly;
  bool get isFemaleOnly => gender == SeatGender.femaleOnly;
  bool get isSleeper => seatType == SeatType.sleeper;

  // ── copyWith ──
  SeatModel copyWith({
    int? number,
    SeatType? seatType,
    SeatGender? gender,
    bool? isBooked,
    bool? isSelected,
  }) =>
      SeatModel(
        number: number ?? this.number,
        seatType: seatType ?? this.seatType,
        gender: gender ?? this.gender,
        isBooked: isBooked ?? this.isBooked,
        isSelected: isSelected ?? this.isSelected,
      );

  SeatModel toggleSelected() {
    if (isBooked) return this;
    return copyWith(isSelected: !isSelected);
  }

  // ── Firestore ──
  Map<String, dynamic> toMap() => {
        'number': number,
        'seatType': seatType.name,
        'gender': gender.name,
        'isBooked': isBooked,
      };

  factory SeatModel.fromMap(Map<String, dynamic> map) => SeatModel(
        number: (map['number'] as num?)?.toInt() ?? 0,
        seatType: SeatType.values.firstWhere(
          (e) => e.name == (map['seatType'] ?? 'seater'),
          orElse: () => SeatType.seater,
        ),
        gender: SeatGender.values.firstWhere(
          (e) => e.name == (map['gender'] ?? 'any'),
          orElse: () => SeatGender.any,
        ),
        isBooked: map['isBooked'] as bool? ?? false,
      );

  // ── Layout generator ──
  static List<SeatModel> generateLayout({
    required int total,
    required bool isSleeper,
    Set<int> bookedNumbers = const {},
  }) =>
      List.generate(total, (i) {
        final n = i + 1;
        return SeatModel(
          number: n,
          seatType: isSleeper ? SeatType.sleeper : SeatType.seater,
          isBooked: bookedNumbers.contains(n),
        );
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SeatModel && number == other.number;

  @override
  int get hashCode => number.hashCode;

  @override
  String toString() => 'SeatModel(#$number, ${seatType.name}, ${status.name})';
}

// ── List extension ──
extension SeatListX on List<SeatModel> {
  List<SeatModel> get selected => where((s) => s.isSelected).toList();
  List<SeatModel> get booked => where((s) => s.isBooked).toList();
  List<SeatModel> get available => where((s) => s.isAvailable).toList();

  List<int> get selectedNumbers =>
      selected.map((s) => s.number).toList()..sort();
  int get selectedCount => selected.length;

  List<SeatModel> toggleSeat(int number) => [
        for (final s in this)
          if (s.number == number) s.toggleSelected() else s,
      ];

  List<SeatModel> applyBooked(Set<int> numbers) => [
        for (final s in this)
          if (numbers.contains(s.number))
            s.copyWith(isBooked: true, isSelected: false)
          else
            s,
      ];
}
