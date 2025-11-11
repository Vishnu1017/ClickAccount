import 'dart:io';
import 'dart:ui';
import 'package:bizmate/screens/Camera%20rental%20page/view_rental_details_page.dart'
    show ViewRentalDetailsPage;
import 'package:bizmate/widgets/confirm_delete_dialog.dart'
    show showConfirmDialog;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/rental_item.dart';
import 'edit_rental_item_page.dart';

class RentalItems extends StatefulWidget {
  const RentalItems({super.key});

  @override
  State<RentalItems> createState() => _RentalItemsState();
}

class _RentalItemsState extends State<RentalItems> {
  late Box<RentalItem> _rentalBox;

  @override
  void initState() {
    super.initState();
    _rentalBox = Hive.box<RentalItem>('rental_items');
  }

  void _deleteItem(int index) {
    showConfirmDialog(
      context: context,
      title: "Delete Item?",
      message: "Are you sure you want to remove this item permanently?",
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.redAccent,
      onConfirm: () {
        _rentalBox.deleteAt(index); // your existing delete logic
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF00BCD4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ValueListenableBuilder(
          valueListenable: _rentalBox.listenable(),
          builder: (context, Box<RentalItem> box, _) {
            if (box.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white70,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No items added yet!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }

            final items = box.values.toList().cast<RentalItem>();

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    width > 900
                        ? 4
                        : width > 600
                        ? 3
                        : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.6,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onLongPress: () => _deleteItem(index),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditRentalItemPage(item: item, index: index),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE3F2FD), Color(0xFFB2EBF2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: _buildCardContent(item, index),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(RentalItem item, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Stack(
                children: [
                  Image.file(
                    File(item.imagePath),
                    height: constraints.maxHeight * 0.45,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, _, __) => Container(
                          height: constraints.maxHeight * 0.45,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                item.availability == 'Available'
                                    ? Colors.green.withOpacity(0.9)
                                    : Colors.redAccent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.availability,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _deleteItem(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0D47A1),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.branding_watermark_rounded,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.brand,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${item.price.toStringAsFixed(0)}/day',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                  fontSize: 14,
                                ),
                              ),
                              Icon(
                                item.availability == 'Available'
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color:
                                    item.availability == 'Available'
                                        ? Colors.green
                                        : Colors.redAccent,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ViewRentalDetailsPage(
                                        item: item,
                                        name: item.name,
                                        imageUrl:
                                            item.imagePath, // ✅ image from file
                                        pricePerDay:
                                            item.price, // ✅ double value
                                        availability: item.availability,
                                      ),
                                ),
                              );
                            },
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
