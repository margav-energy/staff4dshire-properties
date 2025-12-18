import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/invoice_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class InvoiceProvider extends ChangeNotifier {
  static const String _storageKey = 'invoices_list';
  List<Invoice> _invoices = [];
  bool _isLoading = false;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;

  // Get invoices by status
  List<Invoice> getInvoicesByStatus(InvoiceStatus status) {
    return _invoices.where((i) => i.status == status).toList();
  }

  // Get unpaid invoices
  List<Invoice> getUnpaidInvoices() {
    return _invoices.where((i) => !i.isPaid).toList();
  }

  // Get invoices by project
  List<Invoice> getInvoicesByProject(String projectId) {
    return _invoices.where((i) => i.projectId == projectId).toList();
  }

  // Get invoice by ID
  Invoice? getInvoiceById(String id) {
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  // Load invoices from API or storage
  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (ApiConfig.isApiEnabled) {
        try {
          final response = await ApiService.get('/invoices');
          if (response is List) {
            _invoices = response
                .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
                .toList();
            await _saveToStorage();
          }
        } catch (e) {
          debugPrint('Failed to load invoices from API: $e');
          await _loadFromStorage();
        }
      } else {
        await _loadFromStorage();
      }
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      await _loadFromStorage();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate invoice from job completion
  Future<Invoice> generateInvoice({
    required String projectId,
    required String staffId,
    String? timeEntryId,
    String? jobCompletionId,
    String? supervisorId,
    required double amount,
    double? hoursWorked,
    double? hourlyRate,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = {
        'project_id': projectId,
        'staff_id': staffId,
        'time_entry_id': timeEntryId,
        'job_completion_id': jobCompletionId,
        'supervisor_id': supervisorId,
        'amount': amount,
        'hours_worked': hoursWorked,
        'hourly_rate': hourlyRate,
        'description': description,
        'status': 'pending',
      };

      Invoice invoice;
      if (ApiConfig.isApiEnabled) {
        try {
          final response = await ApiService.post('/invoices', data);
          invoice = Invoice.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Failed to generate invoice via API: $e');
          // Create locally as fallback
          invoice = Invoice(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            invoiceNumber: 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
            projectId: projectId,
            timeEntryId: timeEntryId,
            jobCompletionId: jobCompletionId,
            staffId: staffId,
            supervisorId: supervisorId,
            amount: amount,
            hoursWorked: hoursWorked,
            hourlyRate: hourlyRate,
            description: description,
            status: InvoiceStatus.pending,
          );
        }
      } else {
        invoice = Invoice(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          invoiceNumber: 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          projectId: projectId,
          timeEntryId: timeEntryId,
          jobCompletionId: jobCompletionId,
          staffId: staffId,
          supervisorId: supervisorId,
          amount: amount,
          hoursWorked: hoursWorked,
          hourlyRate: hourlyRate,
          description: description,
          status: InvoiceStatus.pending,
        );
      }

      _invoices.add(invoice);
      await _saveToStorage();
      _isLoading = false;
      notifyListeners();
      return invoice;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Mark invoice as paid (admin only)
  Future<void> markInvoiceAsPaid(String invoiceId, String adminId) async {
    final index = _invoices.indexWhere((i) => i.id == invoiceId);
    if (index == -1) return;

    try {
      if (ApiConfig.isApiEnabled) {
        try {
          final response = await ApiService.put('/invoices/$invoiceId/pay', {
            'paid_by': adminId,
          });
          _invoices[index] = Invoice.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Failed to mark as paid via API: $e');
          _invoices[index] = _invoices[index].copyWith(
            isPaid: true,
            paidAt: DateTime.now(),
            paidBy: adminId,
            status: InvoiceStatus.paid,
          );
        }
      } else {
        _invoices[index] = _invoices[index].copyWith(
          isPaid: true,
          paidAt: DateTime.now(),
          paidBy: adminId,
          status: InvoiceStatus.paid,
        );
      }

      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking invoice as paid: $e');
      rethrow;
    }
  }

  // Save to local storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final invoicesJson = _invoices.map((i) => i.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(invoicesJson));
    } catch (e) {
      debugPrint('Error saving invoices: $e');
    }
  }

  // Load from local storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final invoicesJsonString = prefs.getString(_storageKey);
      if (invoicesJsonString != null && invoicesJsonString.isNotEmpty) {
        final List<dynamic> invoicesJson = jsonDecode(invoicesJsonString);
        _invoices = invoicesJson
            .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading invoices from storage: $e');
    }
  }
}


