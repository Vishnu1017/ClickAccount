import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 32) // 👈 Unique ID
class User extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String password;

  @HiveField(4)
  String role;

  User({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });
}
