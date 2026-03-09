// lib/views/remittance/customer_search_screen.dart
// Customer list for remittance: loaded from CustomerStore (Supabase when configured). Searchable by name or bank.

import 'package:flutter/material.dart';
import '../../config/supabase_config.dart';
import '../../providers/mock_data.dart';
import '../../providers/customer_store.dart';
import 'remittance_transaction_screen.dart';
import 'remittance_history_screen.dart';
import 'remittance_rate_screen.dart';
import 'add_customer_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final _searchController = TextEditingController();
  List<MockCustomer> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    await CustomerStore.instance.loadCustomers();
    if (!mounted) return;
    _applyFilter(_searchController.text);
    setState(() => _isLoading = false);
  }

  void _applyFilter(String query) {
    final customers = CustomerStore.instance.customers;
    if (query.trim().isEmpty) {
      _filteredCustomers = customers;
    } else {
      _filteredCustomers = customers
          .where((customer) => customer.matchesSearch(query.trim()))
          .toList();
    }
  }

  void _filterCustomers(String query) {
    setState(() => _applyFilter(query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RemittanceRateScreen(),
                ),
              );
            },
            tooltip: 'Rate Management',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RemittanceHistoryScreen(),
                ),
              );
            },
            tooltip: 'Remittance History',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Search by name or bank',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterCustomers,
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(
                        child: Text('No customers found'),
                      )
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(customer.name[0].toUpperCase()),
                            ),
                            title: Text(customer.name),
                            subtitle: Text(
                              '${customer.phone}\n${customer.bankName} - ${customer.accountNumber}',
                            ),
                            isThreeLine: true,
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RemittanceTransactionScreen(
                                    customer: customer,
                                  ),
                                ),
                              ).then((_) => _loadCustomers());
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const AddCustomerScreen(),
            ),
          );
          if (added == true && mounted) {
            if (isSupabaseConfigured) {
              await _loadCustomers();
            } else {
              setState(() => _applyFilter(_searchController.text));
            }
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }
}
