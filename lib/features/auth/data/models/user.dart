import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;

  final String name;
  final String email;
  final String phone;

  @JsonKey(name: 'national_id')
  final String nationalId;

  /// Citizen | Staff | Admin
  final String role;

  /// active | suspended | deleted (اختياري)
  final String? status;

  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;

  final String? address;

  /// لو السيرفر بيرجع role_id مستقبلاً
  @JsonKey(name: 'role_id')
  final String? roleId;

  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.nationalId,
    required this.role,
    this.status,
    this.dateOfBirth,
    this.address,
    this.roleId,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isStaff => role.toLowerCase() == 'staff';
  bool get isCitizen => role.toLowerCase() == 'citizen';
}
