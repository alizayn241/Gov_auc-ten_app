// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      nationalId: json['national_id'] as String,
      role: json['role'] as String,
      status: json['status'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      address: json['address'] as String?,
      roleId: json['role_id'] as String?,
      token: json['token'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'national_id': instance.nationalId,
      'role': instance.role,
      'status': instance.status,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'address': instance.address,
      'role_id': instance.roleId,
      'token': instance.token,
    };
