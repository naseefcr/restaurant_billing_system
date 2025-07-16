import 'dart:io';
import 'package:http/http.dart' as http;

class DirectConnectionTest {
  static Future<void> testDirectConnection(String serverIp) async {
    print('\n=== DIRECT CONNECTION TEST TO $serverIp ===');
    
    // Test 1: Ping test (using TCP connection attempt)
    await _testTcpConnection(serverIp, 8080);
    
    // Test 2: HTTP GET request
    await _testHttpConnection(serverIp, 8080);
    
    // Test 3: UDP test
    await _testUdpConnection(serverIp, 8082);
    
    print('=== DIRECT CONNECTION TEST COMPLETE ===\n');
  }
  
  static Future<void> _testTcpConnection(String ip, int port) async {
    print('\n--- TCP Connection Test ---');
    try {
      final socket = await Socket.connect(ip, port, timeout: Duration(seconds: 5));
      print('✓ TCP connection successful to $ip:$port');
      socket.destroy();
    } catch (e) {
      print('✗ TCP connection failed to $ip:$port: $e');
    }
  }
  
  static Future<void> _testHttpConnection(String ip, int port) async {
    print('\n--- HTTP Connection Test ---');
    try {
      final client = http.Client();
      final url = 'http://$ip:$port/health';
      
      print('Making HTTP request to: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'DirectConnectionTest/1.0',
        },
      ).timeout(Duration(seconds: 10));
      
      print('✓ HTTP response: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      
      client.close();
      
    } catch (e) {
      print('✗ HTTP connection failed to $ip:$port: $e');
    }
  }
  
  static Future<void> _testUdpConnection(String ip, int port) async {
    print('\n--- UDP Connection Test ---');
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      
      // Send test UDP packet
      final testMessage = {
        'type': 'connection_test',
        'message': 'Direct connection test from waiter app',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final data = testMessage.toString().codeUnits;
      final sentBytes = socket.send(data, InternetAddress(ip), port);
      
      print('✓ Sent UDP test packet to $ip:$port ($sentBytes bytes)');
      
      socket.close();
      
    } catch (e) {
      print('✗ UDP connection failed to $ip:$port: $e');
    }
  }
  
  static Future<void> testAllCommonIPs() async {
    print('\n=== SCANNING COMMON LOCAL IPs ===');
    
    final commonIPs = [
      '192.168.1.1',
      '192.168.1.2', 
      '192.168.1.3',
      '192.168.1.4',
      '192.168.1.5',
      '192.168.0.1',
      '10.0.0.1',
    ];
    
    for (final ip in commonIPs) {
      await _quickHttpTest(ip);
    }
    
    print('=== SCAN COMPLETE ===\n');
  }
  
  static Future<void> _quickHttpTest(String ip) async {
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('http://$ip:8080/health'),
      ).timeout(Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        print('✓ FOUND SERVER: $ip:8080 - ${response.body}');
      }
      
      client.close();
      
    } catch (e) {
      // Silently ignore failures for quick scan
    }
  }
}