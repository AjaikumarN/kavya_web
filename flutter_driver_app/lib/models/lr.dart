class LR {
  final int id;
  final String lrNumber;
  final int? jobId;
  final String? jobNumber;
  final String? consignorName;
  final String? consignorAddress;
  final String? consignorGstin;
  final String? consigneeName;
  final String? consigneeAddress;
  final String? consigneeGstin;
  final String? goodsDescription;
  final int? numberOfPackages;
  final double? weightKg;
  final double? goodsValue;
  final double? freightAmount;
  final String? paymentMode;
  final String? riskType;
  final String? notes;
  final String? ewbNumber;
  final String? date;

  const LR({
    required this.id,
    required this.lrNumber,
    this.jobId,
    this.jobNumber,
    this.consignorName,
    this.consignorAddress,
    this.consignorGstin,
    this.consigneeName,
    this.consigneeAddress,
    this.consigneeGstin,
    this.goodsDescription,
    this.numberOfPackages,
    this.weightKg,
    this.goodsValue,
    this.freightAmount,
    this.paymentMode,
    this.riskType,
    this.notes,
    this.ewbNumber,
    this.date,
  });

  bool get hasEwb => ewbNumber != null && ewbNumber!.isNotEmpty;
  String? get fromLocation => consignorAddress;
  String? get toLocation => consigneeAddress;

  factory LR.fromJson(Map<String, dynamic> json) => LR(
        id: json['id'] as int,
        lrNumber: json['lr_number'] as String? ?? '',
        jobId: json['job_id'] as int?,
        jobNumber: json['job_number'] as String?,
        consignorName: json['consignor_name'] as String?,
        consignorAddress: json['consignor_address'] as String?,
        consignorGstin: json['consignor_gstin'] as String?,
        consigneeName: json['consignee_name'] as String?,
        consigneeAddress: json['consignee_address'] as String?,
        consigneeGstin: json['consignee_gstin'] as String?,
        goodsDescription: json['goods_description'] as String?,
        numberOfPackages: json['number_of_packages'] as int?,
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        goodsValue: (json['goods_value'] as num?)?.toDouble(),
        freightAmount: (json['freight_amount'] as num?)?.toDouble(),
        paymentMode: json['payment_mode'] as String?,
        riskType: json['risk_type'] as String?,
        notes: json['notes'] as String?,
        ewbNumber: json['ewb_number'] as String?,
        date: json['date'] as String?,
      );
}
