import 'package:flutter/material.dart';
import 'package:click_account/models/product_store.dart';
import 'package:click_account/models/product.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  List<String> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchExpanded =
            _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAnimatedSearchBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: _isSearchExpanded ? 50 : 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color:
              _isSearchExpanded
                  ? Colors.indigo.withOpacity(0.3)
                  : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 10),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search packages...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      filteredProducts.clear();
                    } else {
                      final query = value.toLowerCase();
                      filteredProducts =
                          ProductStore().all.where((product) {
                            return product.toLowerCase().contains(query);
                          }).toList();
                    }
                  });
                },
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child:
                _searchController.text.isEmpty
                    ? IconButton(
                      icon: Icon(Icons.search, color: Colors.indigo),
                      onPressed: () {
                        _searchFocusNode.requestFocus();
                      },
                    )
                    : IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        setState(() {
                          filteredProducts.clear();
                          _isSearchExpanded = false;
                        });
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body: Column(
        children: [
          _buildAnimatedSearchBar(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: ProductStore().box.listenable(),
              builder: (context, Box<Product> box, _) {
                final allProducts = box.values.toList();
                final products =
                    _searchController.text.isEmpty
                        ? ProductStore().all
                        : filteredProducts;

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty
                              ? Icons.inventory_2
                              : Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? "No Packages Yet"
                              : "No matching packages found",
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
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final productName = products[index];
                    final productIndex = ProductStore().all.indexOf(
                      productName,
                    );
                    final productRate =
                        productIndex < allProducts.length
                            ? allProducts[productIndex].rate
                            : 0.0;

                    return Dismissible(
                      key: Key(productName + index.toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss:
                          (direction) => _confirmDelete(productIndex),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        margin: EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 30,
                        ),
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
                            child: Icon(
                              Icons.shopping_bag,
                              color: Color(0xFF1A237E),
                            ),
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
                          trailing: Icon(
                            Icons.drag_handle,
                            color: Colors.white70,
                          ),
                        ),
                      ),
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

  Future<bool> _confirmDelete(int index) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            final media = MediaQuery.of(ctx);
            final isSmallScreen = media.size.width < 600;
            final double iconSize = isSmallScreen ? 24.0 : 30.0;
            final double fontSize = isSmallScreen ? 16.0 : 20.0;
            final double padding = isSmallScreen ? 12.0 : 20.0;
            final double buttonPadding = isSmallScreen ? 10.0 : 16.0;

            return AlertDialog(
              insetPadding: EdgeInsets.all(padding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.red, size: iconSize),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      "Confirm Deletion",
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Are you sure you want to delete this package?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: fontSize - 2),
                ),
              ),
              actionsPadding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: buttonPadding - 4,
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: fontSize - 2,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ProductStore().remove(index);
                          Navigator.of(ctx).pop(true);
                        },
                        icon: Icon(Icons.delete_forever, size: iconSize - 2),
                        label: Text(
                          "Delete",
                          style: TextStyle(fontSize: fontSize - 2),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: buttonPadding - 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
