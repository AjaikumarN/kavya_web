class Job {
  final int id;
  final String jobNumber;
  final String? clientName;
  final String? origin;
  final String? destination;
  final String status;
  final String? vehicleNumber;
  final int? vehicleId;
  final String? driverName;
  final String? lrNumber;
  final String? date;
  final double? freightAmount;

  const Job({
    required this.id,
    required this.jobNumber,
    this.clientName,
    this.origin,
    this.destination,
    this.status = 'created',
    this.vehicleNumber,
    this.vehicleId,
    this.driverName,
    this.lrNumber,
    this.date,
    this.freightAmount,
  });

  bool get needsLR => lrNumber == null && status == 'vehicle_assigned';

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as int,
        jobNumber: json['job_number'] as String? ?? '',
        clientName: json['client_name'] as String?,
        origin: json['origin'] as String?,
        destination: json['destination'] as String?,
        status: json['status'] as String? ?? 'created',
        vehicleNumber: json['vehicle_number'] as String?,
        vehicleId: json['vehicle_id'] as int?,
        driverName: json['driver_name'] as String?,
        lrNumber: json['lr_number'] as String?,
        date: json['date'] as String?,
        freightAmount: (json['freight_amount'] as num?)?.toDouble(),
      );
}
