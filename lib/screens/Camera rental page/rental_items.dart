import 'dart:io';
import 'package:bizmate/screens/Camera%20rental%20page/view_rental_details_page.dart';
import 'package:bizmate/widgets/confirm_delete_dialog.dart';
import 'package:bizmate/widgets/advanced_search_bar.dart';
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
  String _searchQuery = "";
  List<RentalItem> filteredItems = [];

  final List<String> _categories = [
    'All',
    'Camera',
    'Lens',
    'Light',
    'Tripod',
    'Drone',
    'Gimbal',
    'Microphone',
  ];

  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _rentalBox = Hive.box<RentalItem>('rental_items');
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterItems();
    });
  }

  void _handleDateRangeChanged(DateTimeRange? range) {
    setState(() {
      _filterItems();
    });
  }

  void _filterItems() {
    final allItems = _rentalBox.values.toList().cast<RentalItem>();
    List<RentalItem> temp = allItems;

    if (_selectedCategory != "All") {
      temp = temp.where((item) => item.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp =
          temp.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.brand.toLowerCase().contains(query) ||
                item.availability.toLowerCase().contains(query) ||
                item.price.toString().contains(query);
          }).toList();
    }

    filteredItems = temp;
  }

  void _deleteItem(int index) {
    showConfirmDialog(
      context: context,
      title: "Delete Item?",
      message: "Are you sure you want to remove this item permanently?",
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.redAccent,
      onConfirm: () {
        _rentalBox.deleteAt(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          AdvancedSearchBar(
            hintText: 'Search rental items...',
            onSearchChanged: _handleSearchChanged,
            onDateRangeChanged: _handleDateRangeChanged,
            showDateFilter: false,
          ),

          // CATEGORY CHIPS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final bool isSelected = _selectedCategory == category;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _filterItems();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient:
                            isSelected
                                ? LinearGradient(
                                  colors: [
                                    Colors.blue.shade700,
                                    Colors.blue.shade900,
                                  ],
                                )
                                : LinearGradient(
                                  colors: [
                                    Colors.grey.shade200,
                                    Colors.grey.shade300,
                                  ],
                                ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ]
                                : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 14,
                            color:
                                isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[900],
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // RENTAL GRID
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _rentalBox.listenable(),
              builder: (context, Box<RentalItem> box, _) {
                if (box.isEmpty) {
                  return const Center(
                    child: Text(
                      'No items added yet!',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  );
                }

                final items =
                    (_searchQuery.isEmpty && _selectedCategory == "All")
                        ? box.values.toList().cast<RentalItem>()
                        : filteredItems;

                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      "No items match your filters",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    double width = constraints.maxWidth;

                    int crossAxisCount =
                        width < 360
                            ? 1
                            : width < 600
                            ? 2
                            : width < 900
                            ? 3
                            : width < 1200
                            ? 4
                            : 5;

                    double cardRatio =
                        width < 360
                            ? 0.85
                            : width < 600
                            ? 0.70
                            : 0.65;

                    return GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: cardRatio,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final originalIndex = _rentalBox.values
                            .toList()
                            .indexOf(item);

                        return GestureDetector(
                          onLongPress: () => _deleteItem(originalIndex),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => EditRentalItemPage(
                                      item: item,
                                      index: originalIndex,
                                    ),
                              ),
                            );
                          },
                          child: _buildCard(item, originalIndex),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ⭐⭐⭐ FULL CARD WITH YOUR MISSING POSITIONED ICON ROW
  Widget _buildCard(RentalItem item, int index) {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFE3F2FD), Color(0xFFB2EBF2)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: Image.file(
                      File(item.imagePath),
                      height: c.maxHeight * 0.42,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.camera, size: 14),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  item.brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '₹${item.price.toStringAsFixed(0)}/day',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      item.availability == 'Available'
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color:
                                          item.availability == 'Available'
                                              ? Colors.green
                                              : Colors.red,
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D47A1),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
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
                                                imageUrl: item.imagePath,
                                                pricePerDay: item.price,
                                                availability: item.availability,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'View Details',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
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
              ),

              // ⭐⭐⭐ YOUR MISSING POSITIONED DESIGN RESTORED ⭐⭐⭐
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
        );
      },
    );
  }
}
