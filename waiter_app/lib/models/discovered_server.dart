import 'package:json_annotation/json_annotation.dart';
import 'server_info.dart';

part 'discovered_server.g.dart';

enum ServerConnectionStatus {
  discovered,
  connecting,
  connected,
  disconnected,
  error,
}

@JsonSerializable()
class DiscoveredServer {
  final ServerInfo serverInfo;
  final DateTime discoveredAt;
  final DateTime lastSeen;
  final ServerConnectionStatus status;
  final String? errorMessage;
  final int signalStrength; // 0-100, estimated based on response time
  final bool isManuallyAdded;

  DiscoveredServer({
    required this.serverInfo,
    required this.discoveredAt,
    required this.lastSeen,
    this.status = ServerConnectionStatus.discovered,
    this.errorMessage,
    this.signalStrength = 100,
    this.isManuallyAdded = false,
  });

  factory DiscoveredServer.fromJson(Map<String, dynamic> json) =>
      _$DiscoveredServerFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoveredServerToJson(this);

  factory DiscoveredServer.fromServerInfo(
    ServerInfo serverInfo, {
    bool isManuallyAdded = false,
  }) {
    final now = DateTime.now();
    return DiscoveredServer(
      serverInfo: serverInfo,
      discoveredAt: now,
      lastSeen: now,
      isManuallyAdded: isManuallyAdded,
    );
  }

  DiscoveredServer copyWith({
    ServerInfo? serverInfo,
    DateTime? discoveredAt,
    DateTime? lastSeen,
    ServerConnectionStatus? status,
    String? errorMessage,
    int? signalStrength,
    bool? isManuallyAdded,
  }) {
    return DiscoveredServer(
      serverInfo: serverInfo ?? this.serverInfo,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      signalStrength: signalStrength ?? this.signalStrength,
      isManuallyAdded: isManuallyAdded ?? this.isManuallyAdded,
    );
  }

  bool get isOnline => DateTime.now().difference(lastSeen).inSeconds < 30;
  bool get isConnected => status == ServerConnectionStatus.connected;
  bool get hasError => status == ServerConnectionStatus.error;
  
  String get displayName => serverInfo.name;
  String get displayAddress => '${serverInfo.ipAddress}:${serverInfo.httpPort}';
  
  Duration get timeSinceDiscovered => DateTime.now().difference(discoveredAt);
  Duration get timeSinceLastSeen => DateTime.now().difference(lastSeen);

  String get statusText {
    switch (status) {
      case ServerConnectionStatus.discovered:
        return 'Discovered';
      case ServerConnectionStatus.connecting:
        return 'Connecting...';
      case ServerConnectionStatus.connected:
        return 'Connected';
      case ServerConnectionStatus.disconnected:
        return 'Disconnected';
      case ServerConnectionStatus.error:
        return 'Error';
    }
  }

  @override
  String toString() {
    return 'DiscoveredServer(serverInfo: $serverInfo, discoveredAt: $discoveredAt, lastSeen: $lastSeen, status: $status, errorMessage: $errorMessage, signalStrength: $signalStrength, isManuallyAdded: $isManuallyAdded)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveredServer &&
        other.serverInfo == serverInfo &&
        other.discoveredAt == discoveredAt &&
        other.lastSeen == lastSeen &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.signalStrength == signalStrength &&
        other.isManuallyAdded == isManuallyAdded;
  }

  @override
  int get hashCode {
    return serverInfo.hashCode ^
        discoveredAt.hashCode ^
        lastSeen.hashCode ^
        status.hashCode ^
        errorMessage.hashCode ^
        signalStrength.hashCode ^
        isManuallyAdded.hashCode;
  }
}