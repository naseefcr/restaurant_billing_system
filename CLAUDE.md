# Restaurant Billing System

## Project Overview
A comprehensive Flutter-based restaurant management system consisting of two interconnected mobile applications: a cashier app (server) and a waiter app (client). The system provides real-time synchronization, order management, and table status tracking.

## System Architecture
```
┌─────────────────┐    Real-time Sync    ┌─────────────────┐
│   Cashier App   │◄──────────────────────►│   Waiter App    │
│   (Server)      │                       │   (Client)      │
│                 │                       │                 │
│ • SQLite DB     │    HTTP REST API     │ • Memory Cache  │
│ • HTTP Server   │    WebSocket         │ • HTTP Client   │
│ • WebSocket     │    UDP Discovery     │ • WebSocket     │
│ • UDP Broadcast │                       │ • UDP Listen    │
└─────────────────┘                       └─────────────────┘
```

## Applications

### Cashier App (Server)
- **Role**: Main server application
- **Database**: SQLite for persistent data storage
- **Services**: HTTP REST API, WebSocket server, UDP discovery
- **Features**: Order management, billing, table status, product catalog
- **Ports**: 8080 (HTTP), 8081 (WebSocket), 8082 (UDP)

### Waiter App (Client)
- **Role**: Client application for waiters
- **Storage**: In-memory caching with real-time updates
- **Services**: HTTP client, WebSocket client, UDP discovery
- **Features**: Table status viewing, order creation, server discovery
- **Connection**: Discovers and connects to cashier app automatically

## Key Features
- **Real-time Synchronization**: Changes reflect immediately across all apps
- **Automatic Discovery**: Waiter apps automatically find cashier app on network
- **Color-coded Status**: Visual table status (Green/Red/Yellow/Grey)
- **Multi-client Support**: Multiple waiter apps can connect simultaneously
- **Order Management**: Complete order lifecycle from creation to billing
- **Network Resilience**: Automatic reconnection and error handling

## Technology Stack
- **Framework**: Flutter
- **Database**: SQLite (cashier app)
- **Networking**: HTTP REST API, WebSocket, UDP
- **State Management**: Provider pattern
- **UI**: Material Design

## Data Models
- **DiningTable**: Table information with status tracking
- **Order**: Order records with items and status
- **Product**: Product catalog with categories and pricing
- **OrderItem**: Individual items within orders
- **ServerInfo**: Server discovery and connection information

## Network Communication
- **HTTP REST API**: CRUD operations for data management
- **WebSocket**: Real-time bidirectional communication
- **UDP Broadcast**: Automatic server discovery mechanism

## Installation & Setup
1. Clone the repository
2. Navigate to each app directory
3. Run `flutter pub get` in both apps
4. Start cashier app first (server)
5. Start waiter app and connect to server

## Development Workflow
1. **Cashier App Development**: Focus on server-side logic, database operations
2. **Waiter App Development**: Focus on client-side UI, real-time updates
3. **Integration Testing**: Test real-time synchronization between apps
4. **Network Testing**: Verify discovery and connection mechanisms

## Common Commands
```bash
# Install dependencies for both apps
cd cashier_app && flutter pub get
cd ../waiter_app && flutter pub get

# Run both apps simultaneously
cd cashier_app && flutter run &
cd ../waiter_app && flutter run

# Build APKs for both apps
cd cashier_app && flutter build apk
cd ../waiter_app && flutter build apk
```

## API Documentation
See individual CLAUDE.md files in each app directory for detailed API endpoints and WebSocket message types.

## Deployment
- **Local Network**: Both apps communicate over local WiFi
- **Production**: Configure firewall rules for required ports
- **Scaling**: Support for multiple waiter apps per cashier app

## Security Considerations
- Network communication over local WiFi
- No external internet connectivity required
- Basic validation for order data
- Connection authentication via client identification

## Future Enhancements
- User authentication and role management
- Advanced reporting and analytics
- Menu management interface
- Kitchen display system integration
- Payment processing integration

## Support
- Check individual app CLAUDE.md files for specific troubleshooting
- Verify network connectivity for connection issues
- Review console logs for debugging information