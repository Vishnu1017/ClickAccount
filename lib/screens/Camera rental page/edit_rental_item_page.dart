import 'dart:io';
import 'package:bizmate/widgets/app_snackbar.dart' show AppSnackBar;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/rental_item.dart';

class EditRentalItemPage extends StatefulWidget {
  final RentalItem item;
  final int index;

  const EditRentalItemPage({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  State<EditRentalItemPage> createState() => _EditRentalItemPageState();
}

class _EditRentalItemPageState extends State<EditRentalItemPage> {
  late TextEditingController nameController;
  late TextEditingController brandController;
  late TextEditingController priceController;
  String availability = 'Available';
  late Box<RentalItem> rentalBox;

  @override
  void initState() {
    super.initState();
    rentalBox = Hive.box<RentalItem>('rental_items');
    nameController = TextEditingController(text: widget.item.name);
    brandController = TextEditingController(text: widget.item.brand);
    priceController = TextEditingController(text: widget.item.price.toString());
    availability = widget.item.availability;
  }

  void _saveChanges() {
    final updatedItem = RentalItem(
      name: nameController.text,
      brand: brandController.text,
      price: double.tryParse(priceController.text) ?? 0,
      imagePath: widget.item.imagePath,
      availability: availability,
      category: '',
    );

    rentalBox.putAt(widget.index, updatedItem);

    // ✅ Show success snackbar message
    AppSnackBar.showSuccess(context, message: 'Changes saved successfully!');

    // Delay the navigation pop slightly so snackbar is visible briefly
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Edit Rental Item',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.item.imagePath),
                  height: size.height * 0.25,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Input fields
            _buildTextField(nameController, 'Item Name', Icons.camera_alt),
            _buildTextField(brandController, 'Brand', Icons.business),
            _buildTextField(
              priceController,
              'Price per day',
              Icons.currency_rupee,
              isNumber: true,
            ),

            // Modern dropdown
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: DropdownButtonFormField<String>(
                value: availability,
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Availability',
                  labelStyle: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.event_available_rounded,
                    color: Colors.blueAccent,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Available',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 22),
                        SizedBox(width: 10),
                        Text('Available'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Unavailable',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.redAccent, size: 22),
                        SizedBox(width: 10),
                        Text('Unavailable'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => availability = value!),
              ),
            ),
            const SizedBox(height: 30),

            // Gradient save button
            GestureDetector(
              onTap: _saveChanges,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
