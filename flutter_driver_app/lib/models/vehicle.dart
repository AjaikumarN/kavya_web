class Vehicle {
  final int id;
  final String registrationNumber;
  final String type;
  final String? model;
  final String status;
  final String? currentDriverName;
  final int? currentDriverId;
  final double? odometerKm;
  final double? lastLat;
  final double? lastLng;
  final double? speed;
  final String? lastGpsUpdate;
  final String? nextServiceDue;
  final double? nextServiceKm;
  final List<Map<String, dynamic>>? documents;
  final Map<String, dynamic>? currentTrip;

  const Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.type,
    this.model,
    this.status = 'idle',
    this.currentDriverName,
    this.currentDriverId,
    this.odometerKm,
    this.lastLat,
    this.lastLng,
    this.speed,
    this.lastGpsUpdate,
    this.nextServiceDue,
    this.nextServiceKm,
    this.documents,
    this.currentTrip,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as int,
        registrationNumber: json['registration_number'] as String? ?? '',
        type: json['type'] as String? ?? '',
        model: json['model'] as String?,
        status: json['status'] as String? ?? 'idle',
        currentDriverName: json['current_driver_name'] as String?,
        currentDriverId: json['current_driver_id'] as int?,
        odometerKm: (json['odometer_km'] as num?)?.toDouble(),
        lastLat: (json['last_lat'] as num?)?.toDouble(),
        lastLng: (json['last_lng'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        lastGpsUpdate: json['last_gps_update'] as String?,
        nextServiceDue: json['next_service_due'] as String?,
        nextServiceKm: (json['next_service_km'] as num?)?.toDouble(),
        documents: (json['documents'] as List?)?.cast<Map<String, dynamic>>(),
        currentTrip: json['current_trip'] as Map<String, dynamic>?,
      );
}
