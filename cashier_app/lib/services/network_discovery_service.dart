import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../models/server_info.dart';

class NetworkDiscoveryService {
  static final NetworkDiscoveryService _instance = NetworkDiscoveryService._internal();
  factory NetworkDiscoveryService() => _instance;
  NetworkDiscoveryService._internal();

  static const int discoveryPort = 8082;
  static const String broadcastAddress = '255.255.255.255';
  
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  ServerInfo? _serverInfo;

  Future<void> startBroadcasting(ServerInfo serverInfo) async {
    _serverInfo = serverInfo;
    
    try {
      // Log network interface information
      await _logNetworkInterfaces();
      
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      _socket!.broadcastEnabled = true;
      
      print('UDP discovery service started on port $discoveryPort');
      print('Server info: ${_serverInfo!.toJson()}');
      
      // Listen for discovery requests
      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          _handleDiscoveryRequest();
        } else if (event == RawSocketEvent.closed) {
          print('UDP socket closed');
        }
      });
      
      // Start broadcasting server info every 10 seconds
      _broadcastTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _broadcastServerInfo();
      });
      
      // Also broadcast immediately
      _broadcastServerInfo();
      
    } catch (e) {
      print('Error starting UDP discovery service: $e');
      rethrow;
    }
  }

  void _handleDiscoveryRequest() {
    if (_socket == null) return;
    
    final datagram = _socket!.receive();
    if (datagram != null) {
      try {
        final messageString = utf8.decode(datagram.data);
        final message = jsonDecode(messageString);
        
        if (message['type'] == 'discovery_request') {
          // Send immediate response to the requesting client
          _sendDiscoveryResponse(datagram.address, datagram.port);
        }
      } catch (e) {
        // Ignore malformed UDP packets
      }
    }
  }

  void _sendDiscoveryResponse(InternetAddress address, int port) {
    if (_socket == null || _serverInfo == null) return;
    
    try {
      final response = {
        'type': 'server_discovery_response',
        'serverInfo': _serverInfo!.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'responseToRequest': true,
      };
      
      final responseJson = jsonEncode(response);
      final data = utf8.encode(responseJson);
      _socket!.send(data, address, port);
    } catch (e) {
      // Ignore UDP send errors
    }
  }

  void _broadcastServerInfo() {
    if (_socket == null || _serverInfo == null) return;
    
    try {
      final message = {
        'type': 'server_discovery_broadcast',
        'serverInfo': _serverInfo!.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'broadcastMessage': true,
      };
      
      final data = utf8.encode(jsonEncode(message));
      final address = InternetAddress(broadcastAddress);
      
      _socket!.send(data, address, discoveryPort);
      
      // Also send to specific network ranges
      _broadcastToNetworkRanges(data);
      
    } catch (e) {
      print('Error broadcasting server info: $e');
    }
  }

  void _broadcastToNetworkRanges(List<int> data) {
    // Get local network interfaces and broadcast to their subnets
    NetworkInterface.list().then((interfaces) {
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            final subnet = _getSubnetBroadcast(address.address);
            if (subnet != null) {
              try {
                final broadcastAddr = InternetAddress(subnet);
                _socket!.send(data, broadcastAddr, discoveryPort);
              } catch (e) {
                // Ignore errors for specific subnets
              }
            }
          }
        }
      }
    }).catchError((e) {
      print('Error getting network interfaces: $e');
    });
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

  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && 
              !address.isLoopback && 
              !address.isLinkLocal) {
            return address.address;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting local IP address: $e');
      return null;
    }
  }

  Future<List<String>> getAllLocalIpAddresses() async {
    try {
      final addresses = <String>[];
      final interfaces = await NetworkInterface.list();
      
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && 
              !address.isLoopback) {
            addresses.add(address.address);
          }
        }
      }
      
      return addresses;
    } catch (e) {
      print('Error getting all local IP addresses: $e');
      return [];
    }
  }

  Future<void> stop() async {
    print('Stopping network discovery service...');
    
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    
    _socket?.close();
    _socket = null;
    
    _serverInfo = null;
    
    print('Network discovery service stopped');
  }

  // Method for clients to discover servers
  static Future<List<ServerInfo>> discoverServers({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final servers = <ServerInfo>[];
    final completer = Completer<List<ServerInfo>>();
    
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      
      // Send discovery request
      final request = {
        'type': 'discovery_request',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final data = utf8.encode(jsonEncode(request));
      socket.send(data, InternetAddress(broadcastAddress), discoveryPort);
      
      // Listen for responses
      final subscription = socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            try {
              final message = jsonDecode(utf8.decode(datagram.data));
              if (message['type'] == 'server_discovery' && 
                  message['serverInfo'] != null) {
                final serverInfo = ServerInfo.fromJson(message['serverInfo']);
                
                // Avoid duplicates
                if (!servers.any((s) => s.ipAddress == serverInfo.ipAddress)) {
                  servers.add(serverInfo);
                }
              }
            } catch (e) {
              // Ignore malformed messages
            }
          }
        }
      });
      
      // Complete after timeout
      Timer(timeout, () {
        subscription.cancel();
        socket.close();
        completer.complete(servers);
      });
      
      return await completer.future;
    } catch (e) {
      print('Error discovering servers: $e');
      return servers;
    }
  }

  Future<void> _logNetworkInterfaces() async {
    try {
      print('=== Network Interface Information ===');
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
      print('=====================================');
    } catch (e) {
      print('Error logging network interfaces: $e');
    }
  }
}