import 'package:flutter/material.dart';

class RentalSettingsPage extends StatelessWidget {
  const RentalSettingsPage({super.key, required String userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Settings')),
      body: const Center(
        child: Text(
          '⚙️ Manage Rental Preferences & Rates',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
