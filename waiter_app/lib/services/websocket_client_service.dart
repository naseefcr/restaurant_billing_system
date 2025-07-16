import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/websocket_message.dart';

enum WebSocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketClientService extends ChangeNotifier {
  WebSocketChannel? _channel;
  WebSocketConnectionStatus _status = WebSocketConnectionStatus.disconnected;
  String? _errorMessage;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  String? _serverHost;
  int? _webSocketPort;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);
  
  final StreamController<WebSocketMessage> _messageController = 
      StreamController<WebSocketMessage>.broadcast();

  WebSocketConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == WebSocketConnectionStatus.connected;
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  Future<bool> connect(String host, int webSocketPort) async {
    if (_status == WebSocketConnectionStatus.connecting ||
        _status == WebSocketConnectionStatus.connected) {
      return _status == WebSocketConnectionStatus.connected;
    }

    _serverHost = host;
    _webSocketPort = webSocketPort;
    
    return _attemptConnection();
  }

  Future<bool> _attemptConnection() async {
    try {
      _updateStatus(WebSocketConnectionStatus.connecting);
      
      final uri = Uri.parse('ws://$_serverHost:$_webSocketPort');
      print('Attempting WebSocket connection to: $uri');
      
      _channel = IOWebSocketChannel.connect(uri);
      
      await _channel!.ready;
      
      _updateStatus(WebSocketConnectionStatus.connected);
      _reconnectAttempts = 0;
      _errorMessage = null;
      
      _startListening();
      _startHeartbeat();
      
      print('WebSocket connected successfully');
      return true;
      
    } catch (e) {
      print('WebSocket connection failed: $e');
      _errorMessage = e.toString();
      _updateStatus(WebSocketConnectionStatus.error);
      
      _scheduleReconnect();
      return false;
    }
  }

  void _startListening() {
    _channel?.stream.listen(
      _handleMessage,
      onDone: _handleDisconnection,
      onError: _handleError,
    );
  }

  void _handleMessage(dynamic data) {
    try {
      final messageData = jsonDecode(data as String);
      final message = WebSocketMessage.fromJson(messageData);
      
      if (message.type == WebSocketMessageType.heartbeat) {
        _sendHeartbeatResponse();
        return;
      }
      
      // Only log non-heartbeat messages
      print('Received WebSocket message: ${message.type}');
      _messageController.add(message);
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _handleDisconnection() {
    print('WebSocket disconnected');
    _updateStatus(WebSocketConnectionStatus.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _errorMessage = error.toString();
    _updateStatus(WebSocketConnectionStatus.error);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnect attempts reached');
      _updateStatus(WebSocketConnectionStatus.error);
      return;
    }

    _reconnectAttempts++;
    _updateStatus(WebSocketConnectionStatus.reconnecting);
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      print('Attempting to reconnect... (attempt $_reconnectAttempts/$maxReconnectAttempts)');
      _attemptConnection();
    });
  }

  void _startHeartbeat() {
    // Client doesn't send periodic heartbeats, only responds to server heartbeats
    // This prevents heartbeat feedback loops
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendHeartbeat() {
    // Client doesn't send periodic heartbeats, only responds to server heartbeats
    // This method is kept for potential future use
  }

  void _sendHeartbeatResponse() {
    if (isConnected) {
      final response = WebSocketMessage.heartbeat(clientId: 'waiter_app');
      _sendMessage(response);
    }
  }

  void _sendMessage(WebSocketMessage message) {
    if (_channel != null && isConnected) {
      try {
        final json = jsonEncode(message.toJson());
        _channel!.sink.add(json);
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    }
  }

  void sendTableStatusUpdate({
    required int tableId,
    required String tableName,
    required String status,
  }) {
    final message = WebSocketMessage.tableStatusUpdate(
      tableId: tableId,
      tableName: tableName,
      status: status,
      clientId: 'waiter_app',
    );
    _sendMessage(message);
  }

  void sendOrderUpdate({
    required Map<String, dynamic> orderData,
  }) {
    final message = WebSocketMessage.orderUpdated(
      orderData: orderData,
      clientId: 'waiter_app',
    );
    _sendMessage(message);
  }

  void requestSync(String syncType) {
    final message = WebSocketMessage.syncRequest(
      syncType: syncType,
      clientId: 'waiter_app',
    );
    _sendMessage(message);
  }

  void _updateStatus(WebSocketConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
      print('WebSocket status changed to: ${_status.name}');
    }
  }

  void disconnect() {
    print('Disconnecting WebSocket...');
    
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    
    _channel?.sink.close();
    _channel = null;
    
    _updateStatus(WebSocketConnectionStatus.disconnected);
    _reconnectAttempts = 0;
    _errorMessage = null;
    
    print('WebSocket disconnected');
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    super.dispose();
  }
}