import 'package:hive/hive.dart';

part 'product.g.dart'; // required for Hive code generation

@HiveType(typeId: 1) // make sure typeId is unique across all models
class Product extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double rate;

  Product(this.name, this.rate);
}
