import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/invoice.dart';

final _api = ApiService();

// ── Accountant Dashboard ──
final accountantDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return _api.getDashboardAccountant();
});

// ── Invoices ──
final invoiceListProvider =
    FutureProvider.autoDispose.family<List<Invoice>, String?>((ref, status) async {
  final data = await _api.getInvoices(status: status);
  return data
      .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Invoice Detail ──
final invoiceDetailProvider =
    FutureProvider.autoDispose.family<Invoice, String>((ref, id) async {
  final data = await _api.getInvoiceDetail(id);
  return Invoice.fromJson(data);
});

// ── Receivables ──
final receivablesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await _api.getReceivables();
  return data.cast<Map<String, dynamic>>();
});

// ── Payments ──
final paymentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Map<String, String?>>((ref, filters) async {
  final data = await _api.getPayments(
    mode: filters['mode'],
    fromDate: filters['from_date'],
    toDate: filters['to_date'],
  );
  return data.cast<Map<String, dynamic>>();
});

// ── Accountant pending expenses (same endpoint, different context) ──
final accountantPendingExpensesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await _api.getExpensesPending();
  return data.cast<Map<String, dynamic>>();
});
