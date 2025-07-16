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

  @override
  String toString() {
    return 'ServerInfo(name: $name, version: $version, ipAddress: $ipAddress, httpPort: $httpPort, webSocketPort: $webSocketPort, startTime: $startTime, capabilities: $capabilities)';
  }
}