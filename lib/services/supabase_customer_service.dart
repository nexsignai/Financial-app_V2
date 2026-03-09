// lib/services/supabase_customer_service.dart
// Load and save remittance customers to Supabase.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/mock_data.dart';

class SupabaseCustomerService {
  static SupabaseClient get _client => Supabase.instance.client;

  static const _table = 'customers';

  static String _toIso(DateTime d) => d.toUtc().toIso8601String();

  static DateTime _fromIso(String? s) {
    if (s == null || s.isEmpty) return DateTime.now();
    return DateTime.parse(s).toLocal();
  }

  static String _userIdOrThrow() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    return user.id;
  }

  static Future<List<MockCustomer>> loadCustomers() async {
    final res = await _client
        .from(_table)
        .select()
        .eq('user_id', _userIdOrThrow())
        .order('created_at', ascending: false);
    final list = res as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final createdAt = _fromIso(m['created_at'] as String?);
      return MockCustomer(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        bankName: m['bank_name'] as String? ?? '',
        accountNumber: m['account_number'] as String? ?? '',
        ifscCode: m['ifsc_code'] as String?,
        country: m['country'] as String? ?? 'India',
        createdAt: createdAt,
        lastTransactionDate: createdAt,
        totalTransactions: 0,
      );
    }).toList();
  }

  static Future<void> saveCustomer(MockCustomer customer) async {
    await _client.from(_table).upsert({
      'id': customer.id,
      'user_id': _userIdOrThrow(),
      'name': customer.name,
      'phone': customer.phone,
      'bank_name': customer.bankName,
      'account_number': customer.accountNumber,
      'ifsc_code': customer.ifscCode,
      'country': customer.country,
      'created_at': _toIso(customer.createdAt),
    });
  }

  static Future<void> deleteCustomer(String id) async {
    await _client
        .from(_table)
        .delete()
        .eq('user_id', _userIdOrThrow())
        .eq('id', id);
  }
}
