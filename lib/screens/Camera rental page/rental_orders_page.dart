import 'package:flutter/material.dart';

class RentalOrdersPage extends StatelessWidget {
  const RentalOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Orders')),
      body: const Center(
        child: Text(
          '📦 All Camera Rental Orders',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
