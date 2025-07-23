# Restaurant Local Server Package Testing Guide

This test app demonstrates all the key features of the `restaurant_local_server` package. Follow this guide to test the package functionality.

## 🚀 Running the Test App

### Prerequisites
- Flutter SDK installed and configured
- Device or emulator running
- Local network connectivity for testing discovery features

### Starting the App
```bash
cd local_server_test_app
flutter run
```

## 📋 Testing Checklist

### Phase 1: Server Control Testing

1. **Start the Test App**
   - Launch the app on your device/emulator
   - Navigate to the "Server Control" tab

2. **Test Server Lifecycle**
   - ✅ Click "Start Server" and verify:
     - Server status changes to "running"
     - Server health shows "healthy"
     - Server statistics appear
     - Log messages show successful startup
   
   - ✅ Click "Stop Server" and verify:
     - Server status changes to "stopped"
     - Statistics disappear
     - Log shows shutdown messages
   
   - ✅ Click "Restart Server" (when running) and verify:
     - Server restarts successfully
     - New uptime counter starts
     - All services reinitialize

3. **Test Broadcasting**
   - ✅ With server running, click "Broadcast Test"
   - ✅ Check logs for broadcast confirmation
   - ✅ Verify server statistics update

### Phase 2: Discovery Testing

1. **Single Device Testing**
   - Navigate to "Discovery" tab
   - ✅ With server running, click "Discover Servers"
   - ✅ Verify the test server appears in the discovered list
   - ✅ Check server details are correct:
     - Name: "Test Server"
     - Version: "1.0.0"
     - Address and ports displayed
     - Capabilities listed

2. **HTTP Endpoint Testing**
   - ✅ Click "Test Health" on discovered server
   - ✅ Verify 200 OK response with health status
   - ✅ Click "Test Info" on discovered server
   - ✅ Verify server information is returned

3. **Multi-Device Testing** (Optional)
   - Run the app on a second device/emulator on the same network
   - Start server on one device
   - Discover from the other device
   - ✅ Verify cross-device discovery works

### Phase 3: WebSocket Testing

1. **Connection Testing**
   - Navigate to "WebSocket" tab
   - Ensure server is running and discovered
   - ✅ Click "Connect WebSocket"
   - ✅ Verify connection success in logs
   - ✅ Check that connection message appears in WebSocket messages

2. **Message Exchange**
   - ✅ Click "Send Test Message"
   - ✅ Verify message sent confirmation in logs
   - ✅ Check for server responses in message list

3. **Broadcast Reception**
   - ✅ Go back to "Server Control" tab
   - ✅ Click "Broadcast Test" while WebSocket is connected
   - ✅ Return to "WebSocket" tab
   - ✅ Verify broadcast message appears in received messages

4. **Disconnection Testing**
   - ✅ Click "Disconnect WebSocket"
   - ✅ Verify clean disconnection in logs
   - ✅ Check that message list clears

### Phase 4: Real-time Communication Testing

1. **Multi-Client Testing** (Requires 2 devices)
   - Device A: Start server, connect WebSocket
   - Device B: Discover server, connect WebSocket
   - Device A: Send broadcast test
   - ✅ Verify Device B receives the broadcast
   - Device B: Send test message
   - ✅ Verify Device A receives the message

2. **Health Monitoring**
   - Monitor server for 2-3 minutes
   - ✅ Verify health checks occur automatically
   - ✅ Check statistics update periodically
   - ✅ Monitor connection stability

### Phase 5: Error Handling Testing

1. **Network Interruption**
   - Start server and connect WebSocket
   - Disable/enable WiFi briefly
   - ✅ Verify auto-recovery mechanisms activate
   - ✅ Check logs for recovery attempts

2. **Port Conflicts** (Advanced)
   - Start the app
   - Try to start another app using same ports
   - ✅ Verify error handling and user feedback

3. **Invalid Operations**
   - Try operations when server is stopped
   - ✅ Verify appropriate error messages
   - ✅ Check UI buttons are properly disabled

### Phase 6: Performance Testing

1. **Stress Testing**
   - Send multiple rapid WebSocket messages
   - ✅ Verify system stability
   - ✅ Check memory usage remains stable

2. **Long-running Test**
   - Keep server running for 10+ minutes
   - ✅ Monitor for memory leaks
   - ✅ Verify statistics accuracy
   - ✅ Check connection stability

## 🔍 Log Analysis

The "Logs" tab provides detailed information about all operations:

### Key Log Messages to Look For:
- ✅ "Server started successfully!" - Confirms startup
- ✅ "Client connected: [id]" - WebSocket connections
- ✅ "Found [N] server(s)" - Discovery results
- ✅ "HTTP Response (200)" - Successful API calls
- ✅ "WebSocket message received" - Real-time communication
- ✅ "Recovery attempt" - Auto-recovery activation
- ✅ "Test entity update broadcasted" - Broadcasting confirmation

### Error Indicators:
- ❌ "Failed to start server" - Startup issues
- ❌ "Discovery failed" - Network problems
- ❌ "WebSocket error" - Connection issues
- ❌ "HTTP request failed" - API problems

## 🎯 Expected Results

After completing all tests, you should see:

### Successful Features:
- ✅ Server lifecycle management (start/stop/restart)
- ✅ UDP-based server discovery
- ✅ Multi-client WebSocket connections
- ✅ Real-time message broadcasting
- ✅ HTTP API endpoints (/health, /system/info)
- ✅ Health monitoring and statistics
- ✅ Auto-recovery mechanisms
- ✅ Comprehensive logging

### Performance Metrics:
- ✅ Server startup time: < 2 seconds
- ✅ Discovery time: < 5 seconds
- ✅ WebSocket connection time: < 1 second
- ✅ Message latency: < 100ms
- ✅ Memory usage: Stable over time
- ✅ Connection stability: No unexpected disconnections

## 🐛 Troubleshooting

### Common Issues:

1. **Discovery Not Working**
   - Ensure devices are on same WiFi network
   - Check firewall/security settings
   - Verify ports 8080-8082 are available

2. **WebSocket Connection Fails**
   - Confirm server is running
   - Check server was discovered successfully
   - Verify network connectivity

3. **High Memory Usage**
   - Check for excessive logging
   - Monitor WebSocket message accumulation
   - Restart app if needed

4. **Port Already in Use**
   - Close other applications using ports 8080-8082
   - Restart the app
   - Check system firewall settings

## 📊 Success Criteria

The package is working correctly if:

- ✅ All server operations complete without errors
- ✅ Discovery finds local servers consistently
- ✅ WebSocket connections are stable and responsive
- ✅ Broadcasting reaches all connected clients
- ✅ HTTP endpoints return valid responses
- ✅ Auto-recovery works during network interruptions
- ✅ Memory usage remains stable over time
- ✅ Logs show appropriate detail without spam

## 🎉 Next Steps

If all tests pass successfully, the `restaurant_local_server` package is ready for integration into your comprehensive restaurant billing system!

The package provides:
- **Proven local networking capabilities**
- **Real-time synchronization**
- **Robust error handling**
- **Production-ready performance**
- **Comprehensive monitoring**

You can now confidently integrate this package with your sqflite + Supabase architecture for a complete local + cloud solution.