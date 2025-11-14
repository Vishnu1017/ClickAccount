import 'dart:io';
import 'package:bizmate/screens/Camera%20rental%20page/view_rental_details_page.dart'
    show ViewRentalDetailsPage;
import 'package:bizmate/widgets/confirm_delete_dialog.dart'
    show showConfirmDialog;
import 'package:bizmate/widgets/advanced_search_bar.dart'
    show AdvancedSearchBar;
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

  // -------------------------
  // ⭐ CATEGORY LIST ADDED
  // -------------------------
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

  // -------------------------
  // ⭐ CATEGORY FILTER LOGIC ADDED
  // -------------------------
  void _handleCategorySelection(String category) {
    setState(() {
      _selectedCategory = category;
      _filterItems();
    });
  }

  // -------------------------
  // ⭐ UPDATED FILTERING
  // -------------------------
  void _filterItems() {
    final allItems = _rentalBox.values.toList().cast<RentalItem>();

    List<RentalItem> temp = allItems;

    // Category filter
    if (_selectedCategory != "All") {
      temp = temp.where((item) => item.category == _selectedCategory).toList();
    }

    // Search filter
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
            showDateFilter: true,
          ),

          // -------------------------
          // ⭐ CATEGORY SELECTOR BAR
          // -------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine screen size category
                final bool isSmall = constraints.maxWidth < 380;
                final bool isTablet = constraints.maxWidth > 600;

                // Responsive values
                final double chipHeight = isTablet ? 50 : (isSmall ? 36 : 40);
                final double horizontalPadding =
                    isTablet ? 22 : (isSmall ? 14 : 18);
                final double verticalPadding =
                    isTablet ? 12 : (isSmall ? 8 : 10);
                final double fontSize = isTablet ? 16 : (isSmall ? 13 : 14);
                final double iconSize = isTablet ? 20 : (isSmall ? 16 : 18);

                return SizedBox(
                  height: chipHeight,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalPadding,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected
                                    ? LinearGradient(
                                      colors: [
                                        Colors.blue.shade600,
                                        Colors.blue.shade900,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                    : LinearGradient(
                                      colors: [
                                        Colors.grey.shade200,
                                        Colors.grey.shade300,
                                      ],
                                    ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                size: iconSize,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          Expanded(
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

                final items =
                    (_searchQuery.isEmpty && _selectedCategory == "All")
                        ? box.values.toList().cast<RentalItem>()
                        : filteredItems;

                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, color: Colors.white70, size: 80),
                        SizedBox(height: 16),
                        Text(
                          "No items match your filters",
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

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 2;
                    double childAspectRatio = 0.65;

                    if (constraints.maxWidth >= 1200) {
                      crossAxisCount = 5;
                    } else if (constraints.maxWidth >= 900) {
                      crossAxisCount = 4;
                    } else if (constraints.maxWidth >= 600) {
                      crossAxisCount = 3;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspectRatio,
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE3F2FD), Color(0xFFB2EBF2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _buildCardContent(item, originalIndex),
                          ),
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
              child: Image.file(
                File(item.imagePath),
                height: constraints.maxHeight * 0.45,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) =>
                        Container(height: constraints.maxHeight * 0.45),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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

                    // brand
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

                    // Bottom price + view details
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${item.price.toStringAsFixed(0)}/day',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
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
                          const SizedBox(height: 6),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 20,
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
