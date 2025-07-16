import 'package:json_annotation/json_annotation.dart';

part 'dining_table.g.dart';

enum TableStatus {
  available,
  occupied,
  reserved,
  cleaning,
  maintenance,
}

@JsonSerializable()
class DiningTable {
  final int? id;
  final String name;
  final int capacity;
  final TableStatus status;
  final String? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DiningTable({
    this.id,
    required this.name,
    required this.capacity,
    this.status = TableStatus.available,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  factory DiningTable.fromJson(Map<String, dynamic> json) => _$DiningTableFromJson(json);
  Map<String, dynamic> toJson() => _$DiningTableToJson(this);

  factory DiningTable.fromMap(Map<String, dynamic> map) {
    return DiningTable(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      capacity: map['capacity']?.toInt() ?? 1,
      status: TableStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      location: map['location'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'status': status.name,
      'location': location,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  DiningTable copyWith({
    int? id,
    String? name,
    int? capacity,
    TableStatus? status,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiningTable(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DiningTable(id: $id, name: $name, capacity: $capacity, status: $status, location: $location, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiningTable &&
        other.id == id &&
        other.name == name &&
        other.capacity == capacity &&
        other.status == status &&
        other.location == location &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        capacity.hashCode ^
        status.hashCode ^
        location.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}