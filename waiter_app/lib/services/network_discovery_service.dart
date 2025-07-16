import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/server_info.dart';
import '../models/discovered_server.dart';

class NetworkDiscoveryService extends ChangeNotifier {
  static final NetworkDiscoveryService _instance = NetworkDiscoveryService._internal();
  factory NetworkDiscoveryService() => _instance;
  NetworkDiscoveryService._internal();

  static const int discoveryPort = 8082;
  static const String broadcastAddress = '255.255.255.255';
  
  RawDatagramSocket? _socket;
  Timer? _discoveryTimer;
  Timer? _cleanupTimer;
  
  final Map<String, DiscoveredServer> _discoveredServers = {};
  final StreamController<DiscoveredServer> _serverDiscoveredController = 
      StreamController<DiscoveredServer>.broadcast();
  final StreamController<String> _serverLostController = 
      StreamController<String>.broadcast();

  List<DiscoveredServer> get discoveredServers => _discoveredServers.values.toList();
  List<DiscoveredServer> get onlineServers => 
      _discoveredServers.values.where((server) => server.isOnline).toList();
  Stream<DiscoveredServer> get onServerDiscovered => _serverDiscoveredController.stream;
  Stream<String> get onServerLost => _serverLostController.stream;
  
  bool get isDiscovering => _discoveryTimer != null;
  int get serverCount => _discoveredServers.length;
  int get onlineServerCount => onlineServers.length;

  Future<void> startDiscovery() async {
    if (isDiscovering) return;
    
    try {
      // Log network interface information first
      await _logNetworkInterfaces();
      
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;
      
      print('Network discovery started on local port: ${_socket!.port}');
      
      // Listen for server responses
      _socket!.listen((RawSocketEvent event) {
        print('UDP client event: $event at ${DateTime.now()}');
        if (event == RawSocketEvent.read) {
          _handleServerResponse();
        } else if (event == RawSocketEvent.write) {
          print('UDP client ready for writing');
        }
      });
      
      // Send discovery requests every 5 seconds
      _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _sendDiscoveryRequest();
      });
      
      // Clean up offline servers every 30 seconds
      _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _cleanupOfflineServers();
      });
      
      // Send initial discovery request
      _sendDiscoveryRequest();
      
      notifyListeners();
      
    } catch (e) {
      print('Error starting network discovery: $e');
      rethrow;
    }
  }

  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    
    _socket?.close();
    _socket = null;
    
    print('Network discovery stopped');
    notifyListeners();
  }

  void _sendDiscoveryRequest() {
    if (_socket == null) return;
    
    try {
      final request = {
        'type': 'discovery_request',
        'timestamp': DateTime.now().toIso8601String(),
        'requesterId': _generateRequesterId(),
      };
      
      final data = utf8.encode(jsonEncode(request));
      
      // Send to broadcast address
      print('Sending UDP discovery request to $broadcastAddress:$discoveryPort');
      _socket!.send(data, InternetAddress(broadcastAddress), discoveryPort);
      
      // Also send to specific network ranges
      _sendToNetworkRanges(data);
      
    } catch (e) {
      print('Error sending discovery request: $e');
    }
  }

  void _sendToNetworkRanges(List<int> data) {
    // Get local network interfaces and send to their subnets
    NetworkInterface.list().then((interfaces) {
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            final subnet = _getSubnetBroadcast(address.address);
            if (subnet != null) {
              try {
                final broadcastAddr = InternetAddress(subnet);
                _socket!.send(data, broadcastAddr, discoveryPort);
                print('Sent discovery to subnet: $subnet');
              } catch (e) {
                print('Error sending to subnet $subnet: $e');
              }
            }
            
            // Also try to send directly to specific IP ranges
            _sendToSpecificIPs(data, address.address);
          }
        }
      }
    }).catchError((e) {
      print('Error getting network interfaces: $e');
    });
  }

  void _sendToSpecificIPs(List<int> data, String localIp) {
    final parts = localIp.split('.');
    if (parts.length != 4) return;
    
    try {
      final baseIp = '${parts[0]}.${parts[1]}.${parts[2]}';
      
      // Try common IP addresses in the same subnet
      for (int i = 1; i <= 20; i++) {
        try {
          final targetIp = '$baseIp.$i';
          if (targetIp != localIp) {
            _socket!.send(data, InternetAddress(targetIp), discoveryPort);
          }
        } catch (e) {
          // Ignore individual IP failures
        }
      }
      print('Sent discovery requests to $baseIp.1-20');
    } catch (e) {
      print('Error sending to specific IPs: $e');
    }
  }

  String? _getSubnetBroadcast(String ipAddress) {
    final parts = ipAddress.split('.');
    if (parts.length != 4) return null;
    
    try {
      // Assume /24 subnet (255.255.255.0)
      return '${parts[0]}.${parts[1]}.${parts[2]}.255';
    } catch (e) {
      return null;
    }
  }

  void _handleServerResponse() {
    if (_socket == null) return;
    
    final datagram = _socket!.receive();
    if (datagram != null) {
      print('✓ Received UDP response from ${datagram.address.address}:${datagram.port} - ${datagram.data.length} bytes');
      
      try {
        final messageString = utf8.decode(datagram.data);
        print('UDP response content: $messageString');
        
        final message = jsonDecode(messageString);
        print('Parsed UDP response: ${message['type']}');
        
        if (message['type'] == 'server_discovery_response' || 
            message['type'] == 'server_discovery_broadcast') {
          
          final serverInfoMap = message['serverInfo'] as Map<String, dynamic>;
          final serverInfo = ServerInfo.fromJson(serverInfoMap);
          
          print('📡 Discovered server: ${serverInfo.name} at ${serverInfo.ipAddress}:${serverInfo.httpPort}');
          _handleServerDiscovered(serverInfo, datagram.address.address);
        } else {
          print('Unknown UDP response type: ${message['type']}');
        }
      } catch (e) {
        print('Error handling server response: $e');
        print('Raw response data: ${datagram.data}');
        print('Data as string: ${String.fromCharCodes(datagram.data)}');
      }
    } else {
      print('Received null datagram despite read event');
    }
  }

  void _handleServerDiscovered(ServerInfo serverInfo, String sourceAddress) {
    final serverId = '${serverInfo.ipAddress}:${serverInfo.httpPort}';
    final now = DateTime.now();
    
    if (_discoveredServers.containsKey(serverId)) {
      // Update existing server
      final existingServer = _discoveredServers[serverId]!;
      _discoveredServers[serverId] = existingServer.copyWith(
        serverInfo: serverInfo,
        lastSeen: now,
      );
    } else {
      // New server discovered
      final discoveredServer = DiscoveredServer.fromServerInfo(serverInfo);
      _discoveredServers[serverId] = discoveredServer;
      
      print('Discovered new server: ${serverInfo.name} at ${serverInfo.ipAddress}');
      _serverDiscoveredController.add(discoveredServer);
    }
    
    notifyListeners();
  }

  void _cleanupOfflineServers() {
    final now = DateTime.now();
    final offlineThreshold = const Duration(seconds: 45);
    
    final serversToRemove = <String>[];
    
    for (final entry in _discoveredServers.entries) {
      final server = entry.value;
      final timeSinceLastSeen = now.difference(server.lastSeen);
      
      if (timeSinceLastSeen > offlineThreshold && !server.isManuallyAdded) {
        serversToRemove.add(entry.key);
      }
    }
    
    for (final serverId in serversToRemove) {
      _discoveredServers.remove(serverId);
      _serverLostController.add(serverId);
      print('Removed offline server: $serverId');
    }
    
    if (serversToRemove.isNotEmpty) {
      notifyListeners();
    }
  }

  String _generateRequesterId() {
    return 'waiter_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Manual server addition
  Future<bool> addServerManually(String ipAddress, {
    int httpPort = 8080,
    int webSocketPort = 8081,
  }) async {
    try {
      // Validate IP address format
      final address = InternetAddress(ipAddress);
      if (address.type != InternetAddressType.IPv4) {
        return false;
      }
      
      // Create server info for manual entry
      final serverInfo = ServerInfo.create(
        ipAddress: ipAddress,
        httpPort: httpPort,
        webSocketPort: webSocketPort,
      );
      
      // Test connection by making a simple HTTP request
      final url = '${serverInfo.httpUrl}/health';
      print('Testing connection to: $url');
      print('Making HTTP request from waiter app to cashier app');
      
      try {
        final client = http.Client();
        final response = await client.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'WaiterApp/1.0',
          },
        ).timeout(const Duration(seconds: 10));
        
        print('HTTP response: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
        
        client.close();
        
        if (response.statusCode == 200) {
          // Server is reachable, add it
          final serverId = '${serverInfo.ipAddress}:${serverInfo.httpPort}';
          final discoveredServer = DiscoveredServer.fromServerInfo(
            serverInfo,
            isManuallyAdded: true,
          );
          
          _discoveredServers[serverId] = discoveredServer;
          _serverDiscoveredController.add(discoveredServer);
          
          print('Manually added server: ${serverInfo.ipAddress}');
          notifyListeners();
          return true;
        } else {
          print('Server returned status: ${response.statusCode}');
        }
      } catch (e) {
        print('HTTP request error: $e');
        print('Failed to connect to: $url');
      }
      
      return false;
    } catch (e) {
      print('Error adding server manually: $e');
      return false;
    }
  }

  void removeServer(String serverId) {
    if (_discoveredServers.containsKey(serverId)) {
      _discoveredServers.remove(serverId);
      _serverLostController.add(serverId);
      print('Removed server: $serverId');
      notifyListeners();
    }
  }

  void clearAllServers() {
    _discoveredServers.clear();
    print('Cleared all discovered servers');
    notifyListeners();
  }

  DiscoveredServer? getServerById(String serverId) {
    return _discoveredServers[serverId];
  }

  DiscoveredServer? getServerByIpAddress(String ipAddress) {
    return _discoveredServers.values
        .where((server) => server.serverInfo.ipAddress == ipAddress)
        .firstOrNull;
  }

  @override
  void dispose() {
    stopDiscovery();
    _serverDiscoveredController.close();
    _serverLostController.close();
    super.dispose();
  }

  Future<void> _logNetworkInterfaces() async {
    try {
      print('=== Waiter App Network Interface Information ===');
      final interfaces = await NetworkInterface.list();
      
      for (final interface in interfaces) {
        print('Interface: ${interface.name}');
        for (final address in interface.addresses) {
          print('  Address: ${address.address} (${address.type})');
          print('  Loopback: ${address.isLoopback}');
          print('  Link Local: ${address.isLinkLocal}');
          print('  Multicast: ${address.isMulticast}');
        }
      }
      print('===============================================');
    } catch (e) {
      print('Error logging network interfaces: $e');
    }
  }
}