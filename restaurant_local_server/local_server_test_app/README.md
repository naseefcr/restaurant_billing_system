# Restaurant Local Server - Test Application

A comprehensive Flutter test application for validating the `restaurant_local_server` package functionality. This app demonstrates all the key features including server management, UDP discovery, WebSocket communication, and real-time broadcasting.

## 🎯 Purpose

This test app serves as:
- **Package Validation**: Verify all features work correctly
- **Integration Example**: Show how to use the package in a real Flutter app
- **Development Tool**: Test server functionality during development
- **Reference Implementation**: Demonstrate best practices for using the package

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.7.2)
- Device or emulator for testing
- Local network connectivity for discovery features

### Installation
```bash
# Navigate to the test app directory
cd local_server_test_app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 App Features

### 🔧 Server Control Tab
- **Start/Stop/Restart Server**: Full server lifecycle management
- **Server Status Monitoring**: Real-time status and health indicators
- **Statistics Display**: Live server performance metrics
- **Broadcasting Tests**: Test real-time message distribution

### 🔍 Discovery Tab
- **Server Discovery**: Find local servers using UDP broadcasting
- **Server Details**: View discovered server information
- **HTTP Testing**: Test REST API endpoints (`/health`, `/system/info`)
- **Multi-server Support**: Handle multiple discovered servers

### 🔗 WebSocket Tab
- **Connection Management**: Connect/disconnect to WebSocket servers
- **Message Testing**: Send and receive test messages
- **Real-time Updates**: Live message feed from server
- **Connection Monitoring**: Track WebSocket connection status

### 📋 Logs Tab
- **Comprehensive Logging**: Detailed operation logs
- **Real-time Updates**: Live log stream with timestamps
- **Error Tracking**: Monitor errors and recovery attempts
- **Log Management**: Clear logs and monitor system health

## 🧪 Testing Workflow

### Phase 1: Basic Functionality
1. Start the server and verify successful initialization
2. Check server status and health indicators
3. Test server lifecycle operations (start/stop/restart)

### Phase 2: Network Discovery
1. Discover local servers using UDP broadcasting
2. Verify server information accuracy
3. Test HTTP endpoint accessibility

### Phase 3: Real-time Communication
1. Establish WebSocket connections
2. Test bidirectional messaging
3. Verify broadcast message distribution

### Phase 4: Error Handling
1. Test network interruption recovery
2. Verify error logging and user feedback
3. Check auto-recovery mechanisms

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for detailed testing instructions.

## 🐛 Troubleshooting

### Common Issues

**Server Won't Start**
- Check if ports 8080-8082 are already in use
- Verify network permissions
- Review error logs in the Logs tab

**Discovery Not Finding Servers**
- Ensure devices are on the same WiFi network
- Check firewall settings for UDP port 8082
- Verify multicast is enabled on the network

**WebSocket Connection Issues**
- Confirm server is running and discovered
- Check network connectivity between devices
- Monitor logs for connection error details

## 🎯 Next Steps

After successful testing, you can integrate the package into your comprehensive restaurant billing system with confidence that the local networking capabilities are solid and production-ready.
