// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovered_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoveredServer _$DiscoveredServerFromJson(
  Map<String, dynamic> json,
) => DiscoveredServer(
  serverInfo: ServerInfo.fromJson(json['serverInfo'] as Map<String, dynamic>),
  discoveredAt: DateTime.parse(json['discoveredAt'] as String),
  lastSeen: DateTime.parse(json['lastSeen'] as String),
  status:
      $enumDecodeNullable(_$ServerConnectionStatusEnumMap, json['status']) ??
      ServerConnectionStatus.discovered,
  errorMessage: json['errorMessage'] as String?,
  signalStrength: (json['signalStrength'] as num?)?.toInt() ?? 100,
  isManuallyAdded: json['isManuallyAdded'] as bool? ?? false,
);

Map<String, dynamic> _$DiscoveredServerToJson(DiscoveredServer instance) =>
    <String, dynamic>{
      'serverInfo': instance.serverInfo,
      'discoveredAt': instance.discoveredAt.toIso8601String(),
      'lastSeen': instance.lastSeen.toIso8601String(),
      'status': _$ServerConnectionStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
      'signalStrength': instance.signalStrength,
      'isManuallyAdded': instance.isManuallyAdded,
    };

const _$ServerConnectionStatusEnumMap = {
  ServerConnectionStatus.discovered: 'discovered',
  ServerConnectionStatus.connecting: 'connecting',
  ServerConnectionStatus.connected: 'connected',
  ServerConnectionStatus.disconnected: 'disconnected',
  ServerConnectionStatus.error: 'error',
};
