import 'package:json_annotation/json_annotation.dart';

part 'server_info.g.dart';

@JsonSerializable()
class ServerInfo {
  final String name;
  final String version;
  final String ipAddress;
  final int httpPort;
  final int webSocketPort;
  final DateTime startTime;
  final Map<String, dynamic> capabilities;

  ServerInfo({
    required this.name,
    required this.version,
    required this.ipAddress,
    required this.httpPort,
    required this.webSocketPort,
    required this.startTime,
    required this.capabilities,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ServerInfoToJson(this);

  factory ServerInfo.create({
    required String ipAddress,
    int httpPort = 8080,
    int webSocketPort = 8081,
  }) {
    return ServerInfo(
      name: 'Restaurant Billing System - Cashier App',
      version: '1.0.0',
      ipAddress: ipAddress,
      httpPort: httpPort,
      webSocketPort: webSocketPort,
      startTime: DateTime.now(),
      capabilities: {
        'products': true,
        'tables': true,
        'orders': true,
        'realtime': true,
        'websocket': true,
        'udp_discovery': true,
      },
    );
  }

  String get httpUrl => 'http://$ipAddress:$httpPort';
  String get webSocketUrl => 'ws://$ipAddress:$webSocketPort';
  
  Duration get uptime => DateTime.now().difference(startTime);
  
  bool get isValid => 
      name.isNotEmpty && 
      ipAddress.isNotEmpty && 
      httpPort > 0 && 
      webSocketPort > 0;

  @override
  String toString() {
    return 'ServerInfo(name: $name, version: $version, ipAddress: $ipAddress, httpPort: $httpPort, webSocketPort: $webSocketPort, startTime: $startTime, capabilities: $capabilities)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerInfo &&
        other.name == name &&
        other.version == version &&
        other.ipAddress == ipAddress &&
        other.httpPort == httpPort &&
        other.webSocketPort == webSocketPort &&
        other.startTime == startTime;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        version.hashCode ^
        ipAddress.hashCode ^
        httpPort.hashCode ^
        webSocketPort.hashCode ^
        startTime.hashCode;
  }
}