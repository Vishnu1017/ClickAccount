import 'package:bizmate/widgets/confirm_delete_dialog.dart'
    show showConfirmDialog;
import 'package:flutter/material.dart';
import 'package:bizmate/models/product_store.dart';
import 'package:bizmate/models/product.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
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
    bool confirmed = false;

    await showConfirmDialog(
      context: context,
      title: "Confirm Deletion",
      message: "Are you sure you want to delete this package?",
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.redAccent,
      onConfirm: () {
        ProductStore().remove(index);
        confirmed = true;
      },
    );

    return confirmed;
  }
}
