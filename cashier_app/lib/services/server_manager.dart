import 'dart:async';
import 'package:flutter/foundation.dart';
import 'http_server_service.dart';
import 'websocket_service.dart';
import 'network_discovery_service.dart';
import '../models/server_info.dart';

enum ServerStatus {
  stopped,
  starting,
  running,
  stopping,
  error,
}

class ServerManager extends ChangeNotifier {
  static final ServerManager _instance = ServerManager._internal();
  factory ServerManager() => _instance;
  ServerManager._internal();

  ServerStatus _status = ServerStatus.stopped;
  String? _errorMessage;
  ServerInfo? _serverInfo;
  final HttpServerService _httpService = HttpServerService();
  final WebSocketService _webSocketService = WebSocketService();
  final NetworkDiscoveryService _discoveryService = NetworkDiscoveryService();
  
  Timer? _statusTimer;
  StreamSubscription? _webSocketSubscription;

  ServerStatus get status => _status;
  String? get errorMessage => _errorMessage;
  ServerInfo? get serverInfo => _serverInfo;
  bool get isRunning => _status == ServerStatus.running;
  bool get isStopped => _status == ServerStatus.stopped;
  int get connectedClients => _webSocketService.clientCount;

  Future<void> start({
    int httpPort = 8080,
    int webSocketPort = 8081,
  }) async {
    if (_status == ServerStatus.running || _status == ServerStatus.starting) {
      return;
    }

    _updateStatus(ServerStatus.starting);

    try {
      print('Starting server manager...');
      
      // Start HTTP server (this will also start WebSocket and discovery services)
      await _httpService.start(port: httpPort);
      
      // Get server info
      final ipAddress = await _discoveryService.getLocalIpAddress() ?? 'localhost';
      _serverInfo = ServerInfo.create(
        ipAddress: ipAddress,
        httpPort: httpPort,
        webSocketPort: webSocketPort,
      );

      // Listen to WebSocket messages for logging
      _webSocketSubscription = _webSocketService.messageStream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          print('WebSocket message stream error: $error');
        },
      );

      // Start status monitoring
      _startStatusMonitoring();

      // Wait a bit to ensure all services are fully started
      await Future.delayed(const Duration(milliseconds: 500));

      _updateStatus(ServerStatus.running);
      print('Server manager started successfully');
      
      // Force a UI update
      Future.delayed(const Duration(milliseconds: 100), () {
        notifyListeners();
      });
      
    } catch (e) {
      _errorMessage = e.toString();
      _updateStatus(ServerStatus.error);
      print('Error starting server manager: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_status == ServerStatus.stopped || _status == ServerStatus.stopping) {
      return;
    }

    _updateStatus(ServerStatus.stopping);

    try {
      print('Stopping server manager...');
      
      // Stop status monitoring
      _stopStatusMonitoring();
      
      // Stop WebSocket subscription
      await _webSocketSubscription?.cancel();
      _webSocketSubscription = null;
      
      // Stop HTTP server (this will also stop other services)
      await _httpService.stop();
      
      _serverInfo = null;
      _errorMessage = null;
      
      _updateStatus(ServerStatus.stopped);
      print('Server manager stopped successfully');
      
    } catch (e) {
      _errorMessage = e.toString();
      _updateStatus(ServerStatus.error);
      print('Error stopping server manager: $e');
      rethrow;
    }
  }

  Future<void> restart({
    int httpPort = 8080,
    int webSocketPort = 8081,
  }) async {
    print('Restarting server manager...');
    await stop();
    await Future.delayed(const Duration(seconds: 2));
    await start(httpPort: httpPort, webSocketPort: webSocketPort);
  }

  void _updateStatus(ServerStatus newStatus) {
    if (_status != newStatus) {
      final oldStatus = _status;
      _status = newStatus;
      print('Server status changed from ${oldStatus.name} to ${newStatus.name}');
      notifyListeners();
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    // Log WebSocket messages for debugging
    if (kDebugMode) {
      print('WebSocket message: $message');
    }
  }

  void _startStatusMonitoring() {
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkServerHealth();
    });
  }

  void _stopStatusMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  void _checkServerHealth() {
    // Basic health check - could be expanded
    if (_status == ServerStatus.running) {
      try {
        // Check if services are still responsive
        final clientCount = _webSocketService.clientCount;
        print('Server health check: $clientCount clients connected');
      } catch (e) {
        print('Server health check failed: $e');
        _errorMessage = 'Health check failed: $e';
        _updateStatus(ServerStatus.error);
      }
    }
  }

  // Convenience methods for broadcasting
  void broadcastTableStatusUpdate({
    required int tableId,
    required String tableName,
    required String status,
  }) {
    if (_status == ServerStatus.running) {
      _webSocketService.broadcastTableStatusUpdate(
        tableId: tableId,
        tableName: tableName,
        status: status,
      );
    }
  }

  void broadcastOrderUpdate({
    required Map<String, dynamic> orderData,
  }) {
    if (_status == ServerStatus.running) {
      _webSocketService.broadcastOrderUpdate(
        orderData: orderData,
      );
    }
  }

  void broadcastOrderCreated({
    required Map<String, dynamic> orderData,
  }) {
    if (_status == ServerStatus.running) {
      _webSocketService.broadcastOrderCreated(
        orderData: orderData,
      );
    }
  }

  void broadcastProductUpdate({
    required int productId,
    required String name,
    required bool isAvailable,
  }) {
    if (_status == ServerStatus.running) {
      _webSocketService.broadcastProductUpdate(
        productId: productId,
        name: name,
        isAvailable: isAvailable,
      );
    }
  }

  void broadcastSystemMessage({
    required String message,
    String? level,
  }) {
    if (_status == ServerStatus.running) {
      _webSocketService.broadcastSystemMessage(
        message: message,
        level: level,
      );
    }
  }

  // Get server statistics
  Map<String, dynamic> getServerStats() {
    return {
      'status': _status.name,
      'serverInfo': _serverInfo?.toJson(),
      'connectedClients': connectedClients,
      'errorMessage': _errorMessage,
      'uptime': _serverInfo?.startTime != null 
          ? DateTime.now().difference(_serverInfo!.startTime).inSeconds 
          : 0,
    };
  }

  // Get connected clients info
  Map<String, dynamic> getClientsInfo() {
    return _webSocketService.getAllClientsInfo();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}