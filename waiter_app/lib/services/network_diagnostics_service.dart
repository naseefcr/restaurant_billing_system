import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class NetworkDiagnosticsService {
  static const List<String> commonPorts = ['8080', '8081', '8082'];
  static const List<String> testIpRanges = [
    '192.168.1',
    '192.168.0', 
    '10.0.0',
    '172.16.0'
  ];

  static Future<void> runFullDiagnostics() async {
    print('\n=== NETWORK DIAGNOSTICS START ===');
    await _checkNetworkInterfaces();
    await _scanLocalNetwork();
    await _testUdpConnectivity();
    await _testHttpConnectivity();
    print('=== NETWORK DIAGNOSTICS END ===\n');
  }

  static Future<void> _checkNetworkInterfaces() async {
    print('\n--- Network Interfaces ---');
    try {
      final interfaces = await NetworkInterface.list();
      
      for (final interface in interfaces) {
        print('Interface: ${interface.name}');
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            print('  IPv4: ${address.address}');
            print('  Loopback: ${address.isLoopback}');
            print('  Link Local: ${address.isLinkLocal}');
            
            // Extract subnet info
            final subnet = _getSubnet(address.address);
            if (subnet != null) {
              print('  Subnet: $subnet.0/24');
            }
          }
        }
        print('');
      }
    } catch (e) {
      print('Error checking network interfaces: $e');
    }
  }

  static Future<void> _scanLocalNetwork() async {
    print('\n--- Local Network Scan ---');
    
    try {
      final localIps = await _getLocalIpAddresses();
      
      for (final localIp in localIps) {
        final subnet = _getSubnet(localIp);
        if (subnet != null) {
          print('Scanning subnet: $subnet.0/24');
          
          for (int i = 1; i <= 20; i++) {
            final targetIp = '$subnet.$i';
            if (targetIp != localIp) {
              await _pingIp(targetIp);
            }
          }
        }
      }
    } catch (e) {
      print('Error scanning local network: $e');
    }
  }

  static Future<void> _testUdpConnectivity() async {
    print('\n--- UDP Connectivity Test ---');
    
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      
      print('UDP socket bound to port: ${socket.port}');
      
      // Test sending to broadcast addresses
      final testData = 'DIAGNOSTIC_TEST'.codeUnits;
      
      for (final ipRange in testIpRanges) {
        final broadcastIp = '$ipRange.255';
        try {
          socket.send(testData, InternetAddress(broadcastIp), 8082);
          print('Sent UDP to: $broadcastIp:8082');
        } catch (e) {
          print('Failed to send UDP to $broadcastIp: $e');
        }
      }
      
      socket.close();
    } catch (e) {
      print('Error testing UDP connectivity: $e');
    }
  }

  static Future<void> _testHttpConnectivity() async {
    print('\n--- HTTP Connectivity Test ---');
    
    try {
      final localIps = await _getLocalIpAddresses();
      
      for (final localIp in localIps) {
        final subnet = _getSubnet(localIp);
        if (subnet != null) {
          
          for (int i = 1; i <= 10; i++) {
            final targetIp = '$subnet.$i';
            if (targetIp != localIp) {
              await _testHttpToIp(targetIp);
            }
          }
        }
      }
    } catch (e) {
      print('Error testing HTTP connectivity: $e');
    }
  }

  static Future<void> _pingIp(String ip) async {
    // Since we can't use ping directly, we'll try a TCP connection test
    try {
      final socket = await Socket.connect(ip, 8080, timeout: Duration(seconds: 2));
      print('TCP connection successful to: $ip:8080');
      socket.destroy();
    } catch (e) {
      // This is expected for most IPs, so we'll only log successful connections
    }
  }

  static Future<void> _testHttpToIp(String ip) async {
    for (final port in commonPorts) {
      try {
        final client = http.Client();
        final url = 'http://$ip:$port/health';
        
        final response = await client.get(
          Uri.parse(url),
          headers: {'User-Agent': 'NetworkDiagnostics/1.0'},
        ).timeout(Duration(seconds: 3));
        
        print('HTTP SUCCESS: $url - Status: ${response.statusCode}');
        client.close();
        return; // Found a working server
        
      } catch (e) {
        // Continue to next port
      }
    }
  }

  static String? _getSubnet(String ipAddress) {
    final parts = ipAddress.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return null;
  }

  static Future<List<String>> _getLocalIpAddresses() async {
    final addresses = <String>[];
    try {
      final interfaces = await NetworkInterface.list();
      
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && 
              !address.isLoopback &&
              !address.isLinkLocal) {
            addresses.add(address.address);
          }
        }
      }
    } catch (e) {
      print('Error getting local IP addresses: $e');
    }
    return addresses;
  }

  static Future<void> testSpecificConnection(String ip, int port) async {
    print('\n--- Testing Specific Connection: $ip:$port ---');
    
    try {
      // Test TCP connection
      try {
        final socket = await Socket.connect(ip, port, timeout: Duration(seconds: 5));
        print('TCP connection successful to $ip:$port');
        socket.destroy();
      } catch (e) {
        print('TCP connection failed to $ip:$port: $e');
      }
      
      // Test HTTP connection
      try {
        final client = http.Client();
        final response = await client.get(
          Uri.parse('http://$ip:$port/health'),
          headers: {'User-Agent': 'NetworkDiagnostics/1.0'},
        ).timeout(Duration(seconds: 5));
        
        print('HTTP response from $ip:$port - Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        client.close();
        
      } catch (e) {
        print('HTTP request failed to $ip:$port: $e');
      }
      
    } catch (e) {
      print('Error testing connection to $ip:$port: $e');
    }
  }
}