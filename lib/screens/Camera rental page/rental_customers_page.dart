import 'dart:ui';
import 'package:bizmate/widgets/app_snackbar.dart' show AppSnackBar;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../models/customer_model.dart';

class RentalCustomersPage extends StatefulWidget {
  const RentalCustomersPage({Key? key}) : super(key: key);

  @override
  State<RentalCustomersPage> createState() => _RentalCustomersPageState();
}

class _RentalCustomersPageState extends State<RentalCustomersPage> {
  late Box<CustomerModel> customerBox;
  bool _isLoading = true;
  List<CustomerModel> customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      if (!Hive.isBoxOpen('customers')) {
        await Hive.openBox<CustomerModel>('customers');
      }
      customerBox = Hive.box<CustomerModel>('customers');

      setState(() {
        customers = customerBox.values.toList().reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading customers: $e');
      setState(() => _isLoading = false);
      AppSnackBar.showError(
        context,
        message: 'Error loading customers: $e',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _deleteCustomer(int index) async {
    final customer = customers[index];
    await customer.delete();
    setState(() {
      customers.removeAt(index);
    });
    AppSnackBar.showSuccess(
      context,
      message: '${customer.name} deleted successfully',
    );
  }

  // Reusable fancy delete confirmation dialog
  Future<bool> _confirmDelete(CustomerModel customer) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: MediaQuery.of(ctx).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.redAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Delete Customer?",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Are you sure you want to delete ${customer.name}? This action cannot be undone.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : customers.isEmpty
              ? const Center(
                child: Text(
                  "No Customers Found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Dismissible(
                      key: Key(customer.key.toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        // Use the fancy confirmation dialog
                        return await _confirmDelete(customer);
                      },
                      onDismissed: (_) => _deleteCustomer(index),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade400,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      child: Card(
                        elevation: 5,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: Colors.deepPurple.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.deepPurple.shade200,
                                child: Text(
                                  customer.name.isNotEmpty
                                      ? customer.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Phone: ${customer.phone}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Added on: ${customer.createdAt.day}/${customer.createdAt.month}/${customer.createdAt.year}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
