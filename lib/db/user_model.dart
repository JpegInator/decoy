import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  String email;
  
  String password;
  String name;
  int age;
  int weight;
  int height;

  User({
    required this.email,
    required this.password,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
  });
}