// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebSocketMessage _$WebSocketMessageFromJson(Map<String, dynamic> json) =>
    WebSocketMessage(
      type: $enumDecode(_$WebSocketMessageTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      clientId: json['clientId'] as String?,
    );

Map<String, dynamic> _$WebSocketMessageToJson(WebSocketMessage instance) =>
    <String, dynamic>{
      'type': _$WebSocketMessageTypeEnumMap[instance.type]!,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
      'clientId': instance.clientId,
    };

const _$WebSocketMessageTypeEnumMap = {
  WebSocketMessageType.tableStatusUpdate: 'tableStatusUpdate',
  WebSocketMessageType.tableCreated: 'tableCreated',
  WebSocketMessageType.tableDeleted: 'tableDeleted',
  WebSocketMessageType.tableUpdated: 'tableUpdated',
  WebSocketMessageType.orderCreated: 'orderCreated',
  WebSocketMessageType.orderUpdated: 'orderUpdated',
  WebSocketMessageType.orderStatusUpdate: 'orderStatusUpdate',
  WebSocketMessageType.orderDeleted: 'orderDeleted',
  WebSocketMessageType.orderItemAdded: 'orderItemAdded',
  WebSocketMessageType.orderItemUpdated: 'orderItemUpdated',
  WebSocketMessageType.orderItemRemoved: 'orderItemRemoved',
  WebSocketMessageType.productUpdate: 'productUpdate',
  WebSocketMessageType.productCreated: 'productCreated',
  WebSocketMessageType.productDeleted: 'productDeleted',
  WebSocketMessageType.productAvailabilityChanged: 'productAvailabilityChanged',
  WebSocketMessageType.systemMessage: 'systemMessage',
  WebSocketMessageType.heartbeat: 'heartbeat',
  WebSocketMessageType.clientConnect: 'clientConnect',
  WebSocketMessageType.clientDisconnect: 'clientDisconnect',
  WebSocketMessageType.fullSync: 'fullSync',
  WebSocketMessageType.syncRequest: 'syncRequest',
  WebSocketMessageType.syncResponse: 'syncResponse',
};
