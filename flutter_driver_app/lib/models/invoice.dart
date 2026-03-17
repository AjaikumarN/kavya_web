class Invoice {
  final int id;
  final String invoiceNumber;
  final String? clientName;
  final double totalAmount;
  final double? paidAmount;
  final double? dueAmount;
  final String status;
  final String? dueDate;
  final String? createdAt;
  final List<Map<String, dynamic>>? lineItems;
  final Map<String, dynamic>? gstBreakdown;
  final List<Map<String, dynamic>>? payments;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    this.clientName,
    required this.totalAmount,
    this.paidAmount,
    this.dueAmount,
    this.status = 'unpaid',
    this.dueDate,
    this.createdAt,
    this.lineItems,
    this.gstBreakdown,
    this.payments,
  });

  bool get isOverdue {
    if (dueDate == null || status == 'paid') return false;
    final due = DateTime.tryParse(dueDate!);
    return due != null && due.isBefore(DateTime.now());
  }

  double get balanceDue => dueAmount ?? (totalAmount - (paidAmount ?? 0));
  double get cgst => (gstBreakdown?['cgst'] as num?)?.toDouble() ?? 0;
  double get sgst => (gstBreakdown?['sgst'] as num?)?.toDouble() ?? 0;
  double get igst => (gstBreakdown?['igst'] as num?)?.toDouble() ?? 0;

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as int,
        invoiceNumber: json['invoice_number'] as String? ?? '',
        clientName: json['client_name'] as String?,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paid_amount'] as num?)?.toDouble(),
        dueAmount: (json['due_amount'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'unpaid',
        dueDate: json['due_date'] as String?,
        createdAt: json['created_at'] as String?,
        lineItems: (json['line_items'] as List?)?.cast<Map<String, dynamic>>(),
        gstBreakdown: json['gst_breakdown'] as Map<String, dynamic>?,
        payments: (json['payments'] as List?)?.cast<Map<String, dynamic>>(),
      );
}
