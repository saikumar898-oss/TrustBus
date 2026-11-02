// lib/models/bus_models.dart

class BusStop {
  final String name;
  final String time;

  const BusStop({required this.name, required this.time});

  factory BusStop.fromMap(Map<String, dynamic> m) => BusStop(
        name: m['name'] ?? '',
        time: m['time'] ?? '',
      );
}

class BusReview {
  final String name;
  final int stars;
  final String comment;

  const BusReview({
    required this.name,
    required this.stars,
    required this.comment,
  });

  factory BusReview.fromMap(Map<String, dynamic> m) => BusReview(
        name: m['name'] ?? 'Anonymous',
        stars: (m['stars'] is int) ? m['stars'] : 3,
        comment: m['comment'] ?? '',
      );
}

class BusModel {
  final String id;
  final String busName;
  final String busType;
  final String from;
  final String to;
  final String departureTime;
  final String arrivalTime;
  final double rating;
  final int seats;
  final int price;
  final List<String> amenities;
  final List<String> operatingDays;
  final bool? hasWomenSeats;
  final bool? isLive;
  final String? currentLocation;
  final List<BusStop>? boardingPoints;
  final List<BusStop>? droppingPoints;
  final List<BusReview>? reviews;

  const BusModel({
    required this.id,
    required this.busName,
    required this.busType,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.arrivalTime,
    required this.rating,
    required this.seats,
    required this.price,
    required this.amenities,
    required this.operatingDays,
    this.hasWomenSeats,
    this.isLive,
    this.currentLocation,
    this.boardingPoints,
    this.droppingPoints,
    this.reviews,
  });

  factory BusModel.fromMap(String id, Map<String, dynamic> d) {
    List<BusStop> parseStops(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(BusStop.fromMap)
            .toList();
      }
      return [];
    }

    List<BusReview> parseReviews(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(BusReview.fromMap)
            .toList();
      }
      return [];
    }

    return BusModel(
      id: id,
      busName: d['busName'] ?? '',
      busType: d['busType'] ?? '',
      from: d['from'] ?? '',
      to: d['to'] ?? '',
      departureTime: d['departureTime'] ?? '00:00',
      arrivalTime: d['arrivalTime'] ?? '00:00',
      rating: (d['rating'] is num) ? (d['rating'] as num).toDouble() : 0.0,
      seats: (d['seats'] is int) ? d['seats'] : 0,
      price: (d['price'] is int) ? d['price'] : 0,
      amenities:
          (d['amenities'] is List) ? List<String>.from(d['amenities']) : [],
      operatingDays: (d['days'] is List) ? List<String>.from(d['days']) : [],
      hasWomenSeats: d['hasWomenSeats'] as bool?,
      isLive: d['isLive'] as bool?,
      currentLocation: d['currentLocation'] as String?,
      boardingPoints: parseStops(d['boardingPoints']),
      droppingPoints: parseStops(d['droppingPoints']),
      reviews: parseReviews(d['reviews']),
    );
  }
}
