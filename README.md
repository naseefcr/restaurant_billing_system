# Restaurant Billing System

A real-time restaurant billing system built with Flutter, featuring separate cashier and waiter applications with WebSocket-based real-time synchronization.

## 🏗️ Project Structure

```
restaurant_billing_system/
├── cashier_app/          # Cashier/Server application
├── waiter_app/           # Waiter/Client application
└── README.md             # This file
```

## 📱 Applications

### Cashier App (Server)
- **Role**: Primary server application that runs on the cashier's device
- **Features**:
  - HTTP REST API server (port 8080)
  - WebSocket server for real-time communication (port 8081)
  - UDP discovery service (port 8082)
  - SQLite database for data persistence
  - Product, table, and order management
  - Real-time data broadcasting to connected waiter apps

### Waiter App (Client)
- **Role**: Client application for waiters to take orders and manage tables
- **Features**:
  - Automatic server discovery via UDP broadcast
  - Real-time WebSocket connection to cashier app
  - Table status management
  - Order creation and management
  - Automatic reconnection and sync
  - Manual server connection capability

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio or VS Code
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/naseefcr/restaurant_billing_system.git
   cd restaurant_billing_system
   ```

2. **Setup Cashier App**
   ```bash
   cd cashier_app
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

3. **Setup Waiter App**
   ```bash
   cd ../waiter_app
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

### Running the Applications

1. **Start the Cashier App first:**
   ```bash
   cd cashier_app
   flutter run
   ```
   - Tap "Start Server" to begin HTTP/WebSocket/UDP services
   - Note the IP address displayed (e.g., 192.168.1.4:8080)

2. **Start the Waiter App:**
   ```bash
   cd waiter_app
   flutter run
   ```
   - The app will automatically discover the cashier app via UDP
   - If auto-discovery fails, manually enter the cashier app's IP address

## 🏭 Architecture

### Real-time Communication Flow
```
Waiter App → WebSocket → Cashier App → Broadcast → All Connected Waiter Apps
```

### Network Discovery
```
Waiter App → UDP Broadcast (port 8082) → Cashier App → UDP Response → Connection Established
```

### Data Synchronization
- **Tables**: Real-time status updates (available, occupied, reserved, etc.)
- **Orders**: Live order creation, updates, and billing
- **Products**: Menu item management and availability
- **Auto-reconnection**: Automatic connection recovery on network interruption

## 🔧 Technical Stack

- **Frontend**: Flutter (Dart)
- **Database**: SQLite (sqflite)
- **Real-time Communication**: WebSockets (web_socket_channel)
- **Network Discovery**: UDP Sockets (dart:io)
- **HTTP Server**: Shelf framework
- **State Management**: Provider pattern
- **Serialization**: json_annotation + build_runner

## 📱 Features

### Cashier App Features
- ✅ HTTP REST API server
- ✅ WebSocket real-time broadcasting
- ✅ UDP server discovery
- ✅ SQLite database management
- ✅ Product CRUD operations
- ✅ Table management
- ✅ Order processing and billing
- ✅ Real-time client connection monitoring

### Waiter App Features
- ✅ Automatic server discovery
- ✅ Real-time data synchronization
- ✅ Table status management
- ✅ Order creation and submission
- ✅ Manual server connection
- ✅ Connection status monitoring
- ✅ Offline resilience with auto-reconnection

## 🔨 Development

### JSON Model Generation
After making changes to model classes with `@JsonSerializable()`:

**Cashier App:**
```bash
cd cashier_app
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**Waiter App:**
```bash
cd waiter_app
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Network Configuration

#### Android Permissions
Both apps include necessary network permissions:
- `INTERNET` - Basic internet access
- `ACCESS_NETWORK_STATE` - Network status monitoring
- `ACCESS_WIFI_STATE` - WiFi state access
- `CHANGE_WIFI_MULTICAST_STATE` - UDP multicast support

#### Network Security
Android apps are configured to allow cleartext HTTP traffic for local development via `network_security_config.xml`.

## 🐛 Troubleshooting

### Connection Issues
1. **Check WiFi**: Ensure both devices are on the same WiFi network
2. **Check IP Address**: Verify the cashier app's displayed IP address
3. **Manual Connection**: Use the manual IP connection feature in waiter app
4. **Firewall**: Ensure ports 8080, 8081, 8082 are not blocked
5. **Network Diagnostics**: Check app logs for detailed connection information

### Common Logs to Monitor
- **Cashier App**: "HTTP server started on http://[IP]:8080"
- **Waiter App**: "✓ Discovered server: [Name] at [IP]:8080"
- **UDP Discovery**: "Received UDP packet from [IP]:[PORT]"
- **WebSocket**: "WebSocket connected successfully"

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Future Enhancements

- [ ] User authentication and role management
- [ ] Menu categories and modifiers
- [ ] Payment integration
- [ ] Kitchen display system
- [ ] Sales analytics and reporting
- [ ] Multi-location support
- [ ] Cloud synchronization
- [ ] Print receipt functionality

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section above
- Review app logs for detailed error information

---

**Note**: This is a local network application designed for restaurant environments. Both apps should be connected to the same WiFi network for optimal performance.