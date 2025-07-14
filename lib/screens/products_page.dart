import 'package:flutter/material.dart';
import 'package:click_account/models/product_store.dart';
import 'package:click_account/models/product.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProductsPage extends StatefulWidget {
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body: ValueListenableBuilder(
        valueListenable: ProductStore().box.listenable(),
        builder: (context, Box<Product> box, _) {
          final allProducts = box.values.toList();
          final products = ProductStore().all; // List of names

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    "No Packages Yet",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productName = products[index];
              final productRate =
                  index < allProducts.length ? allProducts[index].rate : 0.0;

              return Dismissible(
                key: Key(productName + index.toString()),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) => _confirmDelete(index),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  margin: EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete, color: Colors.white, size: 30),
                ),
                child: Container(
                  margin: EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF1A237E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.shopping_bag, color: Color(0xFF1A237E)),
                    ),
                    title: Text(
                      productName,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Rate: ₹${productRate.toStringAsFixed(2)}",
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: Icon(Icons.drag_handle, color: Colors.white70),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(int index) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive sizing values
                  final bool isSmallScreen = constraints.maxWidth < 600;
                  final double iconSize = isSmallScreen ? 24.0 : 28.0;
                  final double fontSize = isSmallScreen ? 16.0 : 18.0;
                  final double padding = isSmallScreen ? 12.0 : 16.0;
                  final double buttonPadding = isSmallScreen ? 10.0 : 14.0;

                  return AlertDialog(
                    insetPadding: EdgeInsets.all(padding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    titlePadding: EdgeInsets.fromLTRB(
                      padding,
                      padding,
                      padding,
                      8,
                    ),
                    contentPadding: EdgeInsets.fromLTRB(
                      padding,
                      8,
                      padding,
                      padding,
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: iconSize),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Text(
                          "Confirm Deletion",
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      "Are you sure you want to delete this Package?",
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                    actionsPadding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: 8,
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: buttonPadding,
                                  vertical: buttonPadding - 4,
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: fontSize - 2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 16),
                          Flexible(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: buttonPadding,
                                  vertical: buttonPadding - 4,
                                ),
                              ),
                              icon: Icon(
                                Icons.delete_forever,
                                size: iconSize - 2,
                              ),
                              label: Text(
                                "Delete",
                                style: TextStyle(fontSize: fontSize - 2),
                              ),
                              onPressed: () {
                                ProductStore().remove(index);
                                Navigator.of(ctx).pop(true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
        ) ??
        false;
  }
}
