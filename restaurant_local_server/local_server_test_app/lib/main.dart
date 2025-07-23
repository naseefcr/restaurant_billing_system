import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:restaurant_local_server/restaurant_local_server.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Server Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Local Server Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LocalServerManager? _serverManager;
  List<ServerInfo> _discoveredServers = [];
  String _serverStatus = 'stopped';
  String _serverHealth = 'unknown';
  Map<String, dynamic> _serverStats = {};
  final List<String> _logMessages = [];
  WebSocketChannel? _webSocketChannel;
  final List<String> _receivedMessages = [];

  @override
  void initState() {
    super.initState();
    _setupServer();
  }

  @override
  void dispose() {
    _stopServer();
    _webSocketChannel?.sink.close();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.insert(0, '${DateTime.now().toLocal()}: $message');
      if (_logMessages.length > 50) {
        _logMessages.removeLast();
      }
    });
  }

  void _setupServer() {
    // Configure HTTP server (REST API only, no WebSocket)
    final httpConfig = HttpServerConfig(
      httpPort: 8080,
      enableLogging: true,
      enableWebSocket:
          false, // Disable HTTP server's built-in WebSocket (managed by LocalServerManager)
    );

    // Configure dedicated WebSocket server
    final webSocketConfig = WebSocketServerConfig(
      port: 8081,
      enableLogging: true,
    );

    // Configure UDP discovery service
    final discoveryConfig = DiscoveryConfig(
      discoveryPort: 8082,
      enableLogging: true,
    );

    final config = LocalServerConfig(
      httpConfig: httpConfig,
      webSocketConfig: webSocketConfig,
      discoveryConfig: discoveryConfig,
      enableAutoRecovery: true,
      enableLogging: true,
      serverName: 'Test Server',
      serverVersion: '1.0.0',
      capabilities: {
        'test': true,
        'demo': true,
        'real_time_sync': true,
        'app': 'local_server_test_app',
        'environment': 'development',
      },
    );

    final eventHandlers = LocalServerEventHandlers(
      onStatusChange: (oldStatus, newStatus) {
        _addLog(
          'Server status changed: ${oldStatus.name} -> ${newStatus.name}',
        );
        setState(() {
          _serverStatus = newStatus.name;
        });
      },
      onHealthChange: (oldHealth, newHealth) {
        _addLog(
          'Server health changed: ${oldHealth.name} -> ${newHealth.name}',
        );
        setState(() {
          _serverHealth = newHealth.name;
        });
      },
      onClientConnect: (clientId, clientInfo) {
        _addLog('Client connected: $clientId (${clientInfo.type})');
      },
      onClientDisconnect: (clientId, reason) {
        _addLog('Client disconnected: $clientId - $reason');
      },
      onError: (service, error) {
        _addLog('Server error in $service: $error');
      },
      onRecoveryAttempt: (service, attemptNumber) {
        _addLog('Recovery attempt $attemptNumber for $service');
      },
    );

    _serverManager = LocalServerManager(
      config: config,
      eventHandlers: eventHandlers,
    );
  }

  Future<void> _startServer() async {
    try {
      _addLog('Starting server...');
      await _serverManager?.start();
      _addLog('Server started successfully!');
      _updateServerStats();

      // Start periodic stats updates
      _startStatsTimer();
    } catch (e) {
      _addLog('Failed to start server: $e');
    }
  }

  Future<void> _stopServer() async {
    try {
      _addLog('Stopping server...');
      await _serverManager?.stop();
      _addLog('Server stopped successfully!');
      setState(() {
        _serverStats = {};
        _serverStatus = 'stopped';
        _serverHealth = 'unknown';
      });
    } catch (e) {
      _addLog('Failed to stop server: $e');
    }
  }

  Future<void> _restartServer() async {
    try {
      _addLog('Restarting server...');
      await _serverManager?.restart();
      _addLog('Server restarted successfully!');
    } catch (e) {
      _addLog('Failed to restart server: $e');
    }
  }

  void _updateServerStats() {
    final stats = _serverManager?.getStatistics();
    if (stats != null) {
      setState(() {
        _serverStats = stats.toJson();
      });
    }
  }

  void _startStatsTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_serverManager != null && _serverStatus != 'stopped') {
        _updateServerStats();
        _startStatsTimer();
      }
    });
  }

  Future<void> _discoverServers() async {
    try {
      _addLog('Discovering servers...');
      final discoveryConfig = DiscoveryConfig(
        discoveryTimeout: const Duration(seconds: 5),
        enableLogging: true,
      );
      final servers = await NetworkDiscoveryService.discoverServers(
        discoveryConfig,
      );
      setState(() {
        _discoveredServers = servers;
      });
      _addLog('Found ${servers.length} server(s)');

      for (final server in servers) {
        _addLog(
          'Server: ${server.name} at ${server.ipAddress}:${server.httpPort}',
        );
      }
    } catch (e) {
      _addLog('Discovery failed: $e');
    }
  }

  Future<void> _testHttpEndpoint(String endpoint) async {
    if (_discoveredServers.isNotEmpty) {
      final server = _discoveredServers.first;
      final url = '${server.httpUrl}$endpoint';

      try {
        _addLog('Testing HTTP endpoint: $url');
        final response = await http.get(Uri.parse(url));
        _addLog('HTTP Response (${response.statusCode}): ${response.body}');
      } catch (e) {
        _addLog('HTTP request failed: $e');
      }
    } else {
      _addLog('No servers discovered. Please discover servers first.');
    }
  }

  void _connectWebSocket() {
    if (_discoveredServers.isNotEmpty) {
      final server = _discoveredServers.first;
      final wsUrl = server.webSocketUrl;

      try {
        _addLog('Connecting to WebSocket: $wsUrl');
        _webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

        // Listen for messages
        _webSocketChannel!.stream.listen(
          (message) {
            _addLog('WebSocket message received: $message');
            setState(() {
              _receivedMessages.insert(0, message.toString());
              if (_receivedMessages.length > 20) {
                _receivedMessages.removeLast();
              }
            });
          },
          onDone: () {
            _addLog('WebSocket connection closed');
          },
          onError: (error) {
            _addLog('WebSocket error: $error');
          },
        );

        // Send connection message
        final connectMessage = WebSocketMessage.clientConnect(
          clientId: 'test_client_${DateTime.now().millisecondsSinceEpoch}',
          clientType: 'test_app',
          clientMetadata: {'version': '1.0.0', 'platform': 'flutter'},
        );

        _webSocketChannel!.sink.add(jsonEncode(connectMessage.toJson()));
        _addLog('WebSocket connected and connection message sent');
      } catch (e) {
        _addLog('WebSocket connection failed: $e');
      }
    } else {
      _addLog('No servers discovered. Please discover servers first.');
    }
  }

  void _disconnectWebSocket() {
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
    _addLog('WebSocket disconnected');
    setState(() {
      _receivedMessages.clear();
    });
  }

  void _sendTestMessage() {
    if (_webSocketChannel != null) {
      final message = WebSocketMessage.systemMessage(
        message: 'Test message from client at ${DateTime.now()}',
      );

      _webSocketChannel!.sink.add(jsonEncode(message.toJson()));
      _addLog('Test message sent to server');
    } else {
      _addLog('WebSocket not connected');
    }
  }

  void _broadcastTestUpdate() {
    _serverManager?.broadcastEntityUpdate(
      entityType: 'test_entity',
      entityData: {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': 'Test Entity',
        'status': 'updated',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _addLog('Test entity update broadcasted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Server Control'),
                Tab(text: 'Discovery'),
                Tab(text: 'WebSocket'),
                Tab(text: 'Logs'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildServerControlTab(),
                  _buildDiscoveryTab(),
                  _buildWebSocketTab(),
                  _buildLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerControlTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server Status',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Status: '),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _serverStatus == 'running'
                                  ? Colors.green
                                  : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _serverStatus,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('Health: '),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _serverHealth == 'healthy'
                                  ? Colors.green
                                  : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _serverHealth,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: _serverStatus == 'stopped' ? _startServer : null,
                child: const Text('Start Server'),
              ),
              ElevatedButton(
                onPressed: _serverStatus == 'running' ? _stopServer : null,
                child: const Text('Stop Server'),
              ),
              ElevatedButton(
                onPressed: _serverStatus == 'running' ? _restartServer : null,
                child: const Text('Restart Server'),
              ),
              ElevatedButton(
                onPressed:
                    _serverStatus == 'running' ? _broadcastTestUpdate : null,
                child: const Text('Broadcast Test'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_serverStats.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Statistics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    ..._serverStats.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('${entry.key}: ${entry.value}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoveryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: _discoverServers,
            child: const Text('Discover Servers'),
          ),
          const SizedBox(height: 16),
          Text(
            'Discovered Servers (${_discoveredServers.length})',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _discoveredServers.length,
              itemBuilder: (context, index) {
                final server = _discoveredServers[index];
                return Card(
                  child: ListTile(
                    title: Text(server.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Address: ${server.ipAddress}:${server.httpPort}'),
                        Text('Version: ${server.version}'),
                        Text(
                          'Capabilities: ${server.capabilities.keys.join(', ')}',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _testHttpEndpoint('/health'),
                          child: const Text('Test Health'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _testHttpEndpoint('/system/info'),
                          child: const Text('Test Info'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSocketTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: _webSocketChannel == null ? _connectWebSocket : null,
                child: const Text('Connect WebSocket'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _webSocketChannel != null ? _disconnectWebSocket : null,
                child: const Text('Disconnect WebSocket'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _webSocketChannel != null ? _sendTestMessage : null,
                child: const Text('Send Test Message'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'WebSocket Messages (${_receivedMessages.length})',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: _receivedMessages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _receivedMessages[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Server Logs (${_logMessages.length})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _logMessages.clear();
                  });
                },
                child: const Text('Clear Logs'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.black,
              ),
              child: ListView.builder(
                itemCount: _logMessages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      _logMessages[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
