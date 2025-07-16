import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/websocket_message.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final Map<String, WebSocketChannel> _clients = {};
  final Map<String, Map<String, dynamic>> _clientInfo = {};
  final StreamController<WebSocketMessage> _messageController = StreamController<WebSocketMessage>.broadcast();
  HttpServer? _server;
  Timer? _heartbeatTimer;

  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  int get clientCount => _clients.length;
  List<String> get connectedClients => _clients.keys.toList();

  Future<void> start({int port = 8081}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('WebSocket server started on port $port');

      // Handle requests in the background without blocking the start method
      _server!.listen((request) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          _handleWebSocketConnection(request);
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('WebSocket connections only')
            ..close();
        }
      });

      // Give the server a moment to start listening
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      print('Error starting WebSocket server: $e');
      rethrow;
    }
  }

  Future<void> _handleWebSocketConnection(HttpRequest request) async {
    try {
      final webSocket = await WebSocketTransformer.upgrade(request);
      final clientId = _generateClientId();
      final channel = IOWebSocketChannel(webSocket);

      _clients[clientId] = channel;
      _clientInfo[clientId] = {
        'id': clientId,
        'connectedAt': DateTime.now(),
        'lastSeen': DateTime.now(),
        'userAgent': request.headers.value('user-agent'),
        'remoteAddress': request.connectionInfo?.remoteAddress.address,
      };

      print('Client connected: $clientId');

      // Send connection acknowledgment
      final connectMessage = WebSocketMessage.clientConnect(
        clientId: clientId,
        clientType: 'waiter_app',
      );
      channel.sink.add(jsonEncode(connectMessage.toJson()));

      // Broadcast to other clients
      _broadcastMessage(connectMessage, exclude: clientId);

      // Listen for messages from this client
      channel.stream.listen(
        (data) => _handleClientMessage(clientId, data),
        onDone: () => _handleClientDisconnect(clientId),
        onError: (error) => _handleClientError(clientId, error),
      );

      // Start heartbeat if this is the first client
      if (_clients.length == 1) {
        _startHeartbeat();
      }
    } catch (e) {
      print('Error handling WebSocket connection: $e');
    }
  }

  void _handleClientMessage(String clientId, dynamic data) {
    try {
      final Map<String, dynamic> messageData = jsonDecode(data);
      final message = WebSocketMessage.fromJson(messageData);

      // Update client last seen
      if (_clientInfo.containsKey(clientId)) {
        _clientInfo[clientId]!['lastSeen'] = DateTime.now();
      }

      // Handle different message types
      switch (message.type) {
        case WebSocketMessageType.heartbeat:
          // Client heartbeat response - no need to respond back
          break;
        case WebSocketMessageType.tableStatusUpdate:
        case WebSocketMessageType.orderUpdated:
        case WebSocketMessageType.orderCreated:
        case WebSocketMessageType.productUpdate:
          // Broadcast updates to all other clients
          _broadcastMessage(message, exclude: clientId);
          break;
        default:
          print('Unknown message type: ${message.type}');
      }

      // Emit message to stream for other services to handle
      _messageController.add(message);
    } catch (e) {
      print('Error handling client message from $clientId: $e');
    }
  }

  void _handleClientDisconnect(String clientId) {
    print('Client disconnected: $clientId');
    
    _clients.remove(clientId);
    _clientInfo.remove(clientId);

    // Broadcast disconnect message
    final disconnectMessage = WebSocketMessage.clientDisconnect(clientId: clientId);
    _broadcastMessage(disconnectMessage);

    // Stop heartbeat if no clients
    if (_clients.isEmpty) {
      _stopHeartbeat();
    }
  }

  void _handleClientError(String clientId, dynamic error) {
    print('Client error for $clientId: $error');
    _handleClientDisconnect(clientId);
  }

  void _broadcastMessage(WebSocketMessage message, {String? exclude}) {
    final messageJson = jsonEncode(message.toJson());
    
    final clientsToNotify = _clients.entries
        .where((entry) => entry.key != exclude)
        .toList();

    for (final entry in clientsToNotify) {
      try {
        entry.value.sink.add(messageJson);
      } catch (e) {
        print('Error sending message to client ${entry.key}: $e');
        _handleClientDisconnect(entry.key);
      }
    }
  }

  void _sendToClient(String clientId, WebSocketMessage message) {
    final client = _clients[clientId];
    if (client != null) {
      try {
        client.sink.add(jsonEncode(message.toJson()));
      } catch (e) {
        print('Error sending message to client $clientId: $e');
        _handleClientDisconnect(clientId);
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final heartbeatMessage = WebSocketMessage.heartbeat();
      _broadcastMessage(heartbeatMessage);
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  String _generateClientId() {
    return 'client_${DateTime.now().millisecondsSinceEpoch}_${_clients.length}';
  }

  // Public methods for broadcasting updates
  void broadcastMessage(WebSocketMessage message) {
    _broadcastMessage(message);
  }

  void broadcastTableStatusUpdate({
    required int tableId,
    required String tableName,
    required String status,
  }) {
    final message = WebSocketMessage.tableStatusUpdate(
      tableId: tableId,
      tableName: tableName,
      status: status,
    );
    _broadcastMessage(message);
  }

  void broadcastOrderUpdate({
    required Map<String, dynamic> orderData,
  }) {
    final message = WebSocketMessage.orderUpdated(
      orderData: orderData,
    );
    _broadcastMessage(message);
  }

  void broadcastOrderCreated({
    required Map<String, dynamic> orderData,
  }) {
    final message = WebSocketMessage.orderCreated(
      orderData: orderData,
    );
    _broadcastMessage(message);
  }

  void broadcastProductUpdate({
    required int productId,
    required String name,
    required bool isAvailable,
  }) {
    final message = WebSocketMessage.productUpdate(
      productId: productId,
      name: name,
      isAvailable: isAvailable,
    );
    _broadcastMessage(message);
  }

  void broadcastSystemMessage({
    required String message,
    String? level,
  }) {
    final systemMessage = WebSocketMessage.systemMessage(
      message: message,
      level: level,
    );
    _broadcastMessage(systemMessage);
  }

  Map<String, dynamic> getClientInfo(String clientId) {
    return _clientInfo[clientId] ?? {};
  }

  Map<String, dynamic> getAllClientsInfo() {
    return Map.from(_clientInfo);
  }

  Future<void> stop() async {
    print('Stopping WebSocket server...');
    
    _stopHeartbeat();
    
    // Close all client connections
    for (final client in _clients.values) {
      await client.sink.close();
    }
    
    _clients.clear();
    _clientInfo.clear();
    
    // Close the server
    await _server?.close(force: true);
    _server = null;
    
    print('WebSocket server stopped');
  }
}