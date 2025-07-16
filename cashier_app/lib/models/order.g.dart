// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: (json['id'] as num?)?.toInt(),
  tableId: (json['tableId'] as num).toInt(),
  tableName: json['tableName'] as String,
  items:
      (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  status:
      $enumDecodeNullable(_$OrderStatusEnumMap, json['status']) ??
      OrderStatus.pending,
  customerName: json['customerName'] as String?,
  specialInstructions: json['specialInstructions'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  servedAt:
      json['servedAt'] == null
          ? null
          : DateTime.parse(json['servedAt'] as String),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'tableId': instance.tableId,
  'tableName': instance.tableName,
  'items': instance.items,
  'totalAmount': instance.totalAmount,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'customerName': instance.customerName,
  'specialInstructions': instance.specialInstructions,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'servedAt': instance.servedAt?.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.preparing: 'preparing',
  OrderStatus.ready: 'ready',
  OrderStatus.served: 'served',
  OrderStatus.completed: 'completed',
  OrderStatus.cancelled: 'cancelled',
};
