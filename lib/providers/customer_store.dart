// lib/providers/customer_store.dart
// Single source of truth for remittance customers. Loads from Supabase when configured, else mock + in-memory.

import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../providers/mock_data.dart';
import '../services/supabase_customer_service.dart';

class CustomerStore extends ChangeNotifier {
  CustomerStore._();
  static final CustomerStore _instance = CustomerStore._();
  static CustomerStore get instance => _instance;

  List<MockCustomer> _customers = [];
  bool _loaded = false;

  List<MockCustomer> get customers => List.unmodifiable(_customers);

  /// Load customers from Supabase (when configured) or mock data. Call on app start or when opening customer list.
  Future<void> loadCustomers() async {
    if (isSupabaseConfigured) {
      try {
        _customers = await SupabaseCustomerService.loadCustomers();
        // Optional: if DB is empty (e.g. new project), seed one fake customer for testing
        if (_customers.isEmpty && kDebugMode) {
          _loaded = true;
          final fake = MockCustomer(
            id: 'cust_fake_001',
            name: 'Test Customer',
            phone: '+60111234567',
            bankName: 'Maybank',
            accountNumber: '1234567890',
            ifscCode: 'MAYB0001234',
            country: 'India',
            createdAt: DateTime.now(),
            lastTransactionDate: null,
            totalTransactions: 0,
          );
          await addCustomer(fake);
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('CustomerStore.loadCustomers: $e');
        }
        _customers = [];
      }
    } else {
      _customers = MockDataProvider.getCustomers();
    }
    _loaded = true;
    notifyListeners();
  }

  bool get isLoaded => _loaded;

  /// Add a customer and persist to Supabase when configured. Updates the list and notifies listeners.
  Future<void> addCustomer(MockCustomer customer) async {
    _customers.insert(0, customer);
    notifyListeners();
    if (isSupabaseConfigured) {
      await SupabaseCustomerService.saveCustomer(customer);
    }
  }

  /// Remove a customer and delete from Supabase when configured.
  Future<void> removeCustomer(String id) async {
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
    if (isSupabaseConfigured) {
      await SupabaseCustomerService.deleteCustomer(id);
    }
  }
}
