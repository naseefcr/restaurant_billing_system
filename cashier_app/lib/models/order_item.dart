import 'package:json_annotation/json_annotation.dart';

part 'order_item.g.dart';

@JsonSerializable()
class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final String? specialInstructions;
  final DateTime? createdAt;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.specialInstructions,
    this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toInt(),
      orderId: map['order_id']?.toInt() ?? 0,
      productId: map['product_id']?.toInt() ?? 0,
      productName: map['product_name'] ?? '',
      unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 0,
      totalPrice: map['total_price']?.toDouble() ?? 0.0,
      specialInstructions: map['special_instructions'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
      'special_instructions': specialInstructions,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    double? totalPrice,
    String? specialInstructions,
    DateTime? createdAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, orderId: $orderId, productId: $productId, productName: $productName, unitPrice: $unitPrice, quantity: $quantity, totalPrice: $totalPrice, specialInstructions: $specialInstructions, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        other.id == id &&
        other.orderId == orderId &&
        other.productId == productId &&
        other.productName == productName &&
        other.unitPrice == unitPrice &&
        other.quantity == quantity &&
        other.totalPrice == totalPrice &&
        other.specialInstructions == specialInstructions &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        orderId.hashCode ^
        productId.hashCode ^
        productName.hashCode ^
        unitPrice.hashCode ^
        quantity.hashCode ^
        totalPrice.hashCode ^
        specialInstructions.hashCode ^
        createdAt.hashCode;
  }
}