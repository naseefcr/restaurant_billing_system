// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dining_table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiningTable _$DiningTableFromJson(Map<String, dynamic> json) => DiningTable(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  capacity: (json['capacity'] as num).toInt(),
  status:
      $enumDecodeNullable(_$TableStatusEnumMap, json['status']) ??
      TableStatus.available,
  location: json['location'] as String?,
  createdAt:
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$DiningTableToJson(DiningTable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'capacity': instance.capacity,
      'status': _$TableStatusEnumMap[instance.status]!,
      'location': instance.location,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$TableStatusEnumMap = {
  TableStatus.available: 'available',
  TableStatus.occupied: 'occupied',
  TableStatus.reserved: 'reserved',
  TableStatus.cleaning: 'cleaning',
  TableStatus.maintenance: 'maintenance',
};
