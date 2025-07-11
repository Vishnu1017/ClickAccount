import 'package:hive/hive.dart';
import 'product.dart';

class ProductStore {
  static final ProductStore _singleton = ProductStore._internal();
  factory ProductStore() => _singleton;
  ProductStore._internal();

  final String _boxName = 'products';

  Box<Product> get box => Hive.box<Product>(_boxName); // ✅ Add this getter

  List<String> get all => box.values.map((product) => product.name).toList();

  List<Product> getAll() => box.values.toList();

  void add(String name, double rate) {
    box.add(Product(name, rate));
  }

  void remove(int index) {
    box.deleteAt(index);
  }
}
