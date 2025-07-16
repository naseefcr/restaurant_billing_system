import 'package:json_annotation/json_annotation.dart';

part 'websocket_message.g.dart';

enum WebSocketMessageType {
  // Table updates
  tableStatusUpdate,
  tableCreated,
  tableDeleted,
  tableUpdated,
  
  // Order updates
  orderCreated,
  orderUpdated,
  orderStatusUpdate,
  orderDeleted,
  orderItemAdded,
  orderItemUpdated,
  orderItemRemoved,
  
  // Product updates
  productUpdate,
  productCreated,
  productDeleted,
  productAvailabilityChanged,
  
  // System messages
  systemMessage,
  heartbeat,
  clientConnect,
  clientDisconnect,
  
  // Sync messages
  fullSync,
  syncRequest,
  syncResponse,
}

@JsonSerializable()
class WebSocketMessage {
  final WebSocketMessageType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? clientId;

  WebSocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
    this.clientId,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) =>
      _$WebSocketMessageFromJson(json);

  Map<String, dynamic> toJson() => _$WebSocketMessageToJson(this);

  factory WebSocketMessage.tableStatusUpdate({
    required int tableId,
    required String tableName,
    required String status,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.tableStatusUpdate,
      data: {
        'tableId': tableId,
        'tableName': tableName,
        'status': status,
        'action': 'status_updated',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.tableCreated({
    required Map<String, dynamic> tableData,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.tableCreated,
      data: {
        'table': tableData,
        'action': 'created',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.tableUpdated({
    required Map<String, dynamic> tableData,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.tableUpdated,
      data: {
        'table': tableData,
        'action': 'updated',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.tableDeleted({
    required int tableId,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.tableDeleted,
      data: {
        'tableId': tableId,
        'action': 'deleted',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.orderStatusUpdate({
    required Map<String, dynamic> orderData,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.orderStatusUpdate,
      data: {
        'order': orderData,
        'action': 'status_updated',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.orderCreated({
    required Map<String, dynamic> orderData,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.orderCreated,
      data: {
        'order': orderData,
        'action': 'created',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.orderUpdated({
    required Map<String, dynamic> orderData,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.orderUpdated,
      data: {
        'order': orderData,
        'action': 'updated',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.orderDeleted({
    required int orderId,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.orderDeleted,
      data: {
        'orderId': orderId,
        'action': 'deleted',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.productUpdate({
    required int productId,
    required String name,
    required bool isAvailable,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.productUpdate,
      data: {
        'productId': productId,
        'name': name,
        'isAvailable': isAvailable,
        'action': 'updated',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.productCreated({
    required Map<String, dynamic> productData,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.productCreated,
      data: {
        'product': productData,
        'action': 'created',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.productDeleted({
    required int productId,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.productDeleted,
      data: {
        'productId': productId,
        'action': 'deleted',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.systemMessage({
    required String message,
    String? level,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.systemMessage,
      data: {
        'message': message,
        'level': level ?? 'info',
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.heartbeat({String? clientId}) {
    return WebSocketMessage(
      type: WebSocketMessageType.heartbeat,
      data: {'ping': 'pong'},
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.clientConnect({
    required String clientId,
    required String clientType,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.clientConnect,
      data: {
        'clientId': clientId,
        'clientType': clientType,
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.clientDisconnect({
    required String clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.clientDisconnect,
      data: {
        'clientId': clientId,
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.syncRequest({
    required String syncType,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.syncRequest,
      data: {
        'syncType': syncType,
        'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.syncResponse({
    required String syncType,
    required Map<String, dynamic> syncData,
    required String requestId,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.syncResponse,
      data: {
        'syncType': syncType,
        'syncData': syncData,
        'requestId': requestId,
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  factory WebSocketMessage.fullSync({
    required Map<String, dynamic> allData,
    String? clientId,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.fullSync,
      data: {
        'allData': allData,
        'syncTimestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      clientId: clientId,
    );
  }

  @override
  String toString() {
    return 'WebSocketMessage(type: $type, data: $data, timestamp: $timestamp, clientId: $clientId)';
  }
}