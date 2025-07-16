import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/discovered_server.dart';
import '../models/server_info.dart';
import 'websocket_client_service.dart';
import 'network_diagnostics_service.dart';
import 'direct_connection_test.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
  reconnecting,
}

class ServerConnectionService extends ChangeNotifier {
  static final ServerConnectionService _instance = ServerConnectionService._internal();
  factory ServerConnectionService() => _instance;
  ServerConnectionService._internal();

  DiscoveredServer? _connectedServer;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;
  
  final WebSocketClientService _webSocketService = WebSocketClientService();
  
  final StreamController<ConnectionStatus> _statusController = 
      StreamController<ConnectionStatus>.broadcast();

  // Getters
  DiscoveredServer? get connectedServer => _connectedServer;
  ConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == ConnectionStatus.connected;
  bool get isConnecting => _status == ConnectionStatus.connecting;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  WebSocketClientService get webSocketService => _webSocketService;

  Future<bool> connectToServer(DiscoveredServer server) async {
    if (_status == ConnectionStatus.connecting) return false;

    _updateStatus(ConnectionStatus.connecting);
    _connectedServer = server;
    _errorMessage = null;

    try {
      print('Attempting to connect to server: ${server.serverInfo.ipAddress}');
      
      // Run network diagnostics before connection attempt
      await NetworkDiagnosticsService.testSpecificConnection(
        server.serverInfo.ipAddress, 
        server.serverInfo.httpPort
      );
      
      // Test HTTP connection first
      final httpClient = http.Client();
      final url = '${server.serverInfo.httpUrl}/health';
      print('Making HTTP request to: $url');
      
      final response = await httpClient.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'WaiterApp-Connection/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      httpClient.close();
      
      print('HTTP response status: ${response.statusCode}');
      print('HTTP response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server health check failed: ${response.statusCode}');
      }

      // Connect to WebSocket
      print('HTTP connection successful, connecting to WebSocket...');
      final wsConnected = await _webSocketService.connect(
        server.serverInfo.ipAddress,
        server.serverInfo.webSocketPort,
      );
      
      if (!wsConnected) {
        throw Exception('Failed to connect to WebSocket');
      }

      _updateStatus(ConnectionStatus.connected);
      
      print('Successfully connected to server: ${server.serverInfo.ipAddress}');
      return true;

    } catch (e) {
      _errorMessage = e.toString();
      _updateStatus(ConnectionStatus.error);
      print('Failed to connect to server: $e');
      
      // Run diagnostics on failure as well
      print('Running diagnostics due to connection failure...');
      await NetworkDiagnosticsService.runFullDiagnostics();
      
      return false;
    }
  }


  void disconnect() {
    _webSocketService.disconnect();
    
    _connectedServer = null;
    _errorMessage = null;
    _updateStatus(ConnectionStatus.disconnected);
    
    print('Disconnected from server');
  }


  void _updateStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
      notifyListeners();
    }
  }


  // HTTP API methods
  Future<Map<String, dynamic>> getProducts() async {
    return _makeHttpRequest('GET', '/api/products');
  }

  Future<Map<String, dynamic>> getTables() async {
    return _makeHttpRequest('GET', '/api/tables');
  }

  Future<Map<String, dynamic>> getOrders() async {
    return _makeHttpRequest('GET', '/api/orders');
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    return _makeHttpRequest('POST', '/api/orders', body: orderData);
  }

  Future<Map<String, dynamic>> updateTableStatus(int tableId, String status) async {
    return _makeHttpRequest('PATCH', '/api/tables/$tableId/status', body: {
      'status': status,
    });
  }

  // Manual connection methods
  Future<bool> connectToServerByIp(String ipAddress, {
    int httpPort = 8080,
    int webSocketPort = 8081,
  }) async {
    print('Attempting manual connection to: $ipAddress:$httpPort');
    
    // Run direct connection test first
    await DirectConnectionTest.testDirectConnection(ipAddress);
    
    // Run comprehensive diagnostics
    await NetworkDiagnosticsService.runFullDiagnostics();
    
    // Test the specific IP
    await NetworkDiagnosticsService.testSpecificConnection(ipAddress, httpPort);
    
    // Create a temporary server info
    final serverInfo = ServerInfo.create(
      ipAddress: ipAddress,
      httpPort: httpPort,
      webSocketPort: webSocketPort,
    );
    
    final discoveredServer = DiscoveredServer.fromServerInfo(
      serverInfo,
      isManuallyAdded: true,
    );
    
    return await connectToServer(discoveredServer);
  }

  // Quick network scan
  Future<void> scanForServers() async {
    print('Scanning for servers on local network...');
    await DirectConnectionTest.testAllCommonIPs();
  }

  Future<Map<String, dynamic>> _makeHttpRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    if (_connectedServer == null) {
      throw Exception('Not connected to server');
    }

    final url = Uri.parse('${_connectedServer!.serverInfo.httpUrl}$endpoint');
    final headers = {'Content-Type': 'application/json'};
    
    http.Response response;
    
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('HTTP request error: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    disconnect();
    _statusController.close();
    _webSocketService.dispose();
    super.dispose();
  }
}