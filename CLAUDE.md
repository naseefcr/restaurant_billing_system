# Restaurant Billing System

## Project Overview
A comprehensive Flutter-based local networking solution that evolved from a restaurant management system proof-of-concept into a reusable package for building local server applications with real-time synchronization capabilities.

## Repository Structure

### Main Package: `restaurant_local_server/`
A generic, reusable Flutter package providing local networking infrastructure:
- UDP-based network discovery
- HTTP REST API server with CRUD support
- Multi-client WebSocket server with real-time sync
- Service orchestration and health monitoring
- Production-ready with comprehensive error handling

### Example Applications
Two Flutter applications demonstrating the package capabilities:

#### `cashier_app/` (Server Example)
- **Role**: Example server application using the package
- **Database**: SQLite for persistent data storage
- **Features**: Order management, billing, table status, product catalog
- **Purpose**: Demonstrates server-side implementation patterns

#### `waiter_app/` (Client Example)  
- **Role**: Example client application connecting to server
- **Storage**: In-memory caching with real-time updates
- **Features**: Table status viewing, order creation, server discovery
- **Purpose**: Demonstrates client-side connection and usage patterns

### Package Test Application: `restaurant_local_server/local_server_test_app/`
- **Role**: Dedicated test application for package development
- **Purpose**: Testing package functionality in isolation
- **Features**: All networking capabilities without business logic

## System Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                Restaurant Local Server Package             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ UDP Discovery   │  │  HTTP Server    │  │ WebSocket    │ │
│  │    Service      │  │   (REST API)    │  │   Server     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
              │                    │                    │
              ▼                    ▼                    ▼
┌─────────────────┐    HTTP/WS     ┌─────────────────┐
│   Server App    │◄──────────────►│   Client App    │
│  (Cashier)      │                │   (Waiter)      │
│                 │  Real-time     │                 │
│ • Business      │  Sync &        │ • UI Layer      │
│   Logic         │  Discovery     │ • State Mgmt    │
│ • Data Storage  │                │ • User Actions  │
└─────────────────┘                └─────────────────┘
```

## Key Features
- **Real-time Synchronization**: Changes reflect immediately across all apps with reconnection recovery
- **Automatic Discovery**: Waiter apps automatically find cashier app with network change detection
- **Color-coded Status**: Visual table status (Green/Red/Yellow/Grey)
- **Multi-client Support**: Multiple waiter apps can connect simultaneously
- **Order Management**: Complete order lifecycle from creation to billing with live updates
- **Network Resilience**: Automatic reconnection, health monitoring, and error recovery
- **Connection Health Monitoring**: Visual indicators and automatic stale connection detection
- **Manual Recovery Options**: Refresh buttons for connection and discovery troubleshooting

## Package Features (restaurant_local_server)
- **UDP Network Discovery**: Automatic server discovery across local networks
- **WebSocket Server**: Multi-client real-time communication with heartbeat monitoring  
- **HTTP REST API**: Shelf-based HTTP server with CRUD operation support
- **Service Orchestration**: Unified management of all networking services
- **Health Monitoring**: Automatic health checks with failure recovery
- **Highly Configurable**: Extensive configuration options for all services
- **Production Ready**: Comprehensive error handling and resource management

## Technology Stack
- **Framework**: Flutter/Dart
- **HTTP Server**: Shelf framework with routing and middleware support
- **WebSocket**: Multi-client server with heartbeat monitoring
- **Discovery**: UDP multicast for automatic server discovery
- **Serialization**: JSON with code generation
- **Testing**: Comprehensive unit and integration tests

## Package Usage

### Installation
Add to your `pubspec.yaml`:
```yaml
dependencies:
  restaurant_local_server: ^1.0.0
```

### Quick Start
```dart
import 'package:restaurant_local_server/restaurant_local_server.dart';

final config = LocalServerConfig(
  serverName: 'My Application Server',
  version: '1.0.0',
  httpPort: 8080,
  webSocketPort: 8081,
  discoveryPort: 8082,
);

final serverManager = LocalServerManager(config: config);
await serverManager.start();
```

## Installation & Setup

### For Package Development
```bash
# Install package dependencies
cd restaurant_local_server && flutter pub get

# Run code generation for models
cd restaurant_local_server && flutter packages pub run build_runner build

# Run package tests
cd restaurant_local_server && flutter test
```

### For Example Applications
```bash
# Install dependencies for example apps
cd cashier_app && flutter pub get
cd ../waiter_app && flutter pub get

# Run example apps to see package in action
cd cashier_app && flutter run &
cd ../waiter_app && flutter run
```

### For Package Testing
```bash
# Install test app dependencies
cd restaurant_local_server/local_server_test_app && flutter pub get

# Run package test application
cd restaurant_local_server/local_server_test_app && flutter run
```

## Development Workflow

### Package Development
1. **Core Package**: Develop networking services in `restaurant_local_server/lib/`
2. **Model Updates**: Update shared models and run code generation
3. **Testing**: Use test app in `restaurant_local_server/local_server_test_app/`
4. **Documentation**: Update package README and examples

### Application Development  
1. **Server Apps**: Use package to build server-side applications
2. **Client Apps**: Implement discovery and connection to servers
3. **Integration Testing**: Test real-time synchronization between apps
4. **Custom Routes**: Extend HTTP server with application-specific endpoints

## Common Commands

### Package Development
```bash
# Package setup and testing
cd restaurant_local_server
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter test

# Test app for package
cd local_server_test_app
flutter pub get
flutter run
```

### Example Applications
```bash
# Run restaurant management example
cd cashier_app && flutter run &
cd ../waiter_app && flutter run

# Build production APKs
cd cashier_app && flutter build apk --release
cd ../waiter_app && flutter build apk --release
```

## Documentation Structure
- **Package Documentation**: `restaurant_local_server/README.md` - Complete API reference
- **Example Apps**: Individual CLAUDE.md files in `cashier_app/` and `waiter_app/`
- **Package Testing**: Guides in `restaurant_local_server/local_server_test_app/`
- **Functional Testing**: `FUNCTIONAL_TESTING_GUIDE.md` - End-to-end testing scenarios

## Deployment Options

### Package Distribution
- **Pub.dev**: Publish package for public use
- **Private Repository**: Host internally for organization use
- **Local Development**: Use path dependency during development

### Application Deployment
- **Local Network**: Deploy apps on same WiFi network
- **Production**: Configure firewall rules for required ports (8080, 8081, 8082)
- **Scaling**: Package supports multiple client connections per server

## Evolution History
1. **Phase 1**: Built cashier_app and waiter_app as proof-of-concept
2. **Phase 2**: Extracted shared networking functionality into reusable package
3. **Phase 3**: Created dedicated test app for package development
4. **Current**: Maintained example apps showcasing package capabilities

## Future Development
- **Package Enhancements**: Authentication, advanced routing, performance optimizations
- **Example Extensions**: More complex business logic demonstrations
- **Platform Support**: Enhanced cross-platform compatibility
- **Documentation**: Video tutorials and advanced usage guides

## Support & Resources
- **Package Issues**: Report in `restaurant_local_server/` directory
- **Example App Issues**: Check individual app CLAUDE.md files  
- **Testing**: Use `local_server_test_app` for isolated testing
- **Network Troubleshooting**: Refer to package README troubleshooting section