import 'package:json_annotation/json_annotation.dart';
import 'order_item.dart';

part 'order.g.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  served,
  completed,
  cancelled,
}

@JsonSerializable()
class Order {
  final int? id;
  final int tableId;
  final String tableName;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String? customerName;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? servedAt;

  Order({
    this.id,
    required this.tableId,
    required this.tableName,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.customerName,
    this.specialInstructions,
    required this.createdAt,
    this.updatedAt,
    this.servedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem>? items}) {
    return Order(
      id: map['id']?.toInt(),
      tableId: map['table_id']?.toInt() ?? 0,
      tableName: map['table_name'] ?? '',
      items: items ?? [],
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      customerName: map['customer_name'],
      specialInstructions: map['special_instructions'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      servedAt: map['served_at'] != null ? DateTime.parse(map['served_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_id': tableId,
      'table_name': tableName,
      'total_amount': totalAmount,
      'status': status.name,
      'customer_name': customerName,
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'served_at': servedAt?.toIso8601String(),
    };
  }

  Order copyWith({
    int? id,
    int? tableId,
    String? tableName,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    String? customerName,
    String? specialInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? servedAt,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      servedAt: servedAt ?? this.servedAt,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, tableId: $tableId, tableName: $tableName, items: $items, totalAmount: $totalAmount, status: $status, customerName: $customerName, specialInstructions: $specialInstructions, createdAt: $createdAt, updatedAt: $updatedAt, servedAt: $servedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        other.id == id &&
        other.tableId == tableId &&
        other.tableName == tableName &&
        other.items == items &&
        other.totalAmount == totalAmount &&
        other.status == status &&
        other.customerName == customerName &&
        other.specialInstructions == specialInstructions &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.servedAt == servedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tableId.hashCode ^
        tableName.hashCode ^
        items.hashCode ^
        totalAmount.hashCode ^
        status.hashCode ^
        customerName.hashCode ^
        specialInstructions.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        servedAt.hashCode;
  }
}