# Restaurant Local Server - Troubleshooting Guide

This guide covers common issues and their solutions when using the restaurant_local_server package.

## 🔧 Port Binding Issues

### Problem: "Failed to create server socket - shared flag to bind()"

**Symptoms:**
```
SocketException: Failed to create server socket (OS Error: The shared flag to bind() needs to be `true` if binding multiple times on the same (address, port) combination.), address = 0.0.0.0, port = 8081
```

**Root Cause:**
Multiple services trying to bind to the same port simultaneously. This commonly occurs when:
1. HttpServer's built-in WebSocket tries to use the same port as the dedicated WebSocket server
2. Multiple LocalServerManager instances are created
3. Previous server instance wasn't properly stopped

**Solution:**
```dart
final httpConfig = HttpServerConfig(
  httpPort: 8080,
  enableWebSocket: false, // ← IMPORTANT: Disable to prevent conflicts
  enableLogging: true,
);

final webSocketConfig = WebSocketServerConfig(
  port: 8081, // Different port from HTTP
  enableLogging: true,
);
```

**Architecture:**
```
LocalServerManager
├── HttpServer (port 8080) - REST API only
├── WebSocketServer (port 8081) - Real-time communication
└── DiscoveryService (port 8082) - UDP discovery
```

### Problem: Port Already in Use

**Symptoms:**
```
Address already in use (OS Error: Address already in use, errno = 98)
```

**Solutions:**
1. **Stop previous instances:**
   ```dart
   await serverManager.stop(); // Always stop before restarting
   ```

2. **Use different ports:**
   ```dart
   final config = LocalServerConfig(
     httpConfig: HttpServerConfig(httpPort: 8090), // Changed from 8080
     webSocketConfig: WebSocketServerConfig(port: 8091), // Changed from 8081
     discoveryConfig: DiscoveryConfig(discoveryPort: 8092), // Changed from 8082
   );
   ```

3. **Check system processes:**
   ```bash
   # Find processes using the ports
   lsof -i :8080
   lsof -i :8081
   lsof -i :8082
   
   # Kill if necessary
   kill -9 <PID>
   ```

## 📱 Android-Specific Issues

### Problem: Network Operations Not Working

**Symptoms:**
- Server starts but can't be discovered
- HTTP requests fail
- WebSocket connections timeout

**Solution - Add Required Permissions:**

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Network permissions for local server functionality -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
    
    <application ... >
```

### Problem: UDP Discovery Not Working

**Symptoms:**
- Server starts but isn't discoverable
- Discovery returns empty list

**Solutions:**
1. **Check network permissions** (see above)
2. **Verify multicast support:**
   ```dart
   final discoveryConfig = DiscoveryConfig(
     discoveryPort: 8082,
     enableLogging: true, // Enable to see discovery logs
     maxRetries: 3,
   );
   ```

3. **Test on same WiFi network:**
   - Ensure both devices are on the same subnet
   - Check router's multicast settings
   - Disable VPN if active

## 🌐 Network Configuration Issues

### Problem: Server Not Accessible from Other Devices

**Symptoms:**
- Server works locally but can't be reached from other devices
- Discovery finds server but connection fails

**Solutions:**
1. **Check IP binding:**
   ```dart
   final httpConfig = HttpServerConfig(
     httpPort: 8080,
     bindAddress: '0.0.0.0', // Bind to all interfaces
     enableLogging: true,
   );
   ```

2. **Verify firewall settings:**
   - Allow ports 8080-8082 through firewall
   - Check router's port forwarding rules
   - Disable any network security software temporarily

3. **Test connectivity:**
   ```bash
   # From another device, test HTTP endpoint
   curl http://192.168.1.35:8080/health
   
   # Test port accessibility
   telnet 192.168.1.35 8080
   ```

### Problem: WebSocket Connection Drops

**Symptoms:**
- Initial connection succeeds but drops after a few seconds
- Intermittent connection losses

**Solutions:**
1. **Increase heartbeat interval:**
   ```dart
   final webSocketConfig = WebSocketServerConfig(
     port: 8081,
     heartbeatIntervalSeconds: 60, // Increased from 30
     clientTimeoutSeconds: 180,    // Increased timeout
   );
   ```

2. **Check network stability:**
   - Monitor WiFi signal strength
   - Test with mobile hotspot
   - Check for network interference

## 🐛 Application-Level Issues

### Problem: UI Overflow Errors

**Symptoms:**
```
A RenderFlex overflowed by X pixels on the right
```

**Solution:**
```dart
// Use Wrap instead of Row for responsive layout
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    ElevatedButton(...),
    ElevatedButton(...),
  ],
)
```

### Problem: Memory Leaks

**Symptoms:**
- App becomes slow over time
- High memory usage
- Connection instability

**Solutions:**
1. **Proper cleanup:**
   ```dart
   @override
   void dispose() {
     _serverManager?.stop();
     _webSocketChannel?.sink.close();
     super.dispose();
   }
   ```

2. **Limit log retention:**
   ```dart
   void _addLog(String message) {
     setState(() {
       _logMessages.insert(0, message);
       if (_logMessages.length > 50) { // Limit log size
         _logMessages.removeLast();
       }
     });
   }
   ```

## 📊 Performance Issues

### Problem: Slow Server Startup

**Symptoms:**
- Server takes more than 5 seconds to start
- Timeouts during initialization

**Solutions:**
1. **Optimize startup sequence:**
   ```dart
   final config = LocalServerConfig(
     // ... other config
     serviceTimeoutSeconds: 15, // Increase timeout
     healthCheckIntervalSeconds: 60, // Reduce frequency
   );
   ```

2. **Check system resources:**
   - Monitor CPU usage
   - Check available memory
   - Close unnecessary applications

### Problem: High Message Latency

**Symptoms:**
- WebSocket messages take >500ms to arrive
- Discovery takes >10 seconds

**Solutions:**
1. **Optimize network configuration:**
   ```dart
   final webSocketConfig = WebSocketServerConfig(
     port: 8081,
     maxConnections: 10, // Limit concurrent connections
     enableLogging: false, // Disable in production
   );
   ```

2. **Network optimization:**
   - Use 5GHz WiFi instead of 2.4GHz
   - Reduce WiFi channel congestion
   - Position devices closer to router

## 🔍 Debugging Tips

### Enable Comprehensive Logging

```dart
final config = LocalServerConfig(
  httpConfig: HttpServerConfig(
    httpPort: 8080,
    enableLogging: true,
    verboseLogging: true, // Detailed logs
  ),
  webSocketConfig: WebSocketServerConfig(
    port: 8081,
    enableLogging: true,
  ),
  discoveryConfig: DiscoveryConfig(
    discoveryPort: 8082,
    enableLogging: true,
  ),
);
```

### Monitor System Logs

```bash
# Android logs
adb logcat | grep flutter

# Monitor specific package
adb logcat | grep restaurant_local_server
```

### Test Individual Components

```dart
// Test HTTP server only
final httpOnly = LocalServerConfig(
  httpConfig: HttpServerConfig(httpPort: 8080),
  enableWebSocketServer: false,
  enableDiscoveryService: false,
);

// Test WebSocket server only
final wsOnly = LocalServerConfig(
  webSocketConfig: WebSocketServerConfig(port: 8081),
  enableHttpServer: false,
  enableDiscoveryService: false,
);
```

## 📞 Getting Help

If you continue experiencing issues:

1. **Check logs carefully** - Most issues show clear error messages
2. **Test on different devices** - Isolate device-specific problems
3. **Test on different networks** - Identify network-related issues
4. **Simplify configuration** - Start with minimal config and add features gradually
5. **Check package version** - Ensure you're using the latest version

## 🎯 Prevention Best Practices

1. **Always stop servers before restarting:**
   ```dart
   await serverManager.stop();
   await Future.delayed(Duration(seconds: 1));
   await serverManager.start();
   ```

2. **Use unique ports for different apps:**
   - App A: HTTP 8080, WS 8081, UDP 8082
   - App B: HTTP 8090, WS 8091, UDP 8092

3. **Handle errors gracefully:**
   ```dart
   try {
     await serverManager.start();
   } catch (e) {
     print('Server startup failed: $e');
     // Show user-friendly error message
   }
   ```

4. **Test on actual devices** - Emulator networking may differ from real devices

5. **Monitor resource usage** - Check memory and CPU usage regularly