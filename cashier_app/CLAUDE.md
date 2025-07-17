# Restaurant Billing System - Cashier App

## Project Overview
A Flutter-based cashier application for restaurant billing with real-time synchronization capabilities. This app serves as the main server that manages orders, tables, products, and synchronizes data with connected waiter apps.

## Architecture
- **Type**: Flutter Mobile App (Server-side)
- **Database**: SQLite with sqflite
- **Real-time**: WebSocket server + HTTP REST API
- **Network**: UDP discovery service for auto-discovery
- **State Management**: Provider pattern
- **UI**: Material Design with TabBar navigation

## Key Features
- Table management with color-coded status (Green: available, Red: occupied, Yellow: billed)
- Product catalog management
- Order processing and billing
- Real-time synchronization with waiter apps
- Network discovery service for automatic client connection
- Multi-client WebSocket support

## Project Structure
```
lib/
├── main.dart                           # App entry point
├── screens/
│   └── cashier_home_screen.dart       # Main tabbed interface
├── services/
│   ├── http_server_service.dart       # HTTP REST API server
│   ├── websocket_service.dart         # WebSocket server for real-time sync
│   ├── network_discovery_service.dart # UDP discovery service
│   └── realtime_sync_service.dart     # Real-time data synchronization
├── models/
│   ├── dining_table.dart              # Table model with status
│   ├── order.dart                     # Order model with items
│   ├── product.dart                   # Product model
│   ├── order_item.dart                # Order item model
│   ├── server_info.dart               # Server information model
│   └── websocket_message.dart         # WebSocket message types
├── database/
│   ├── database_helper.dart           # SQLite database operations
│   └── database_constants.dart        # Database schema constants
└── providers/
    └── server_manager.dart            # Server state management
```

## Database Schema
- **products**: Product catalog with categories, prices, availability
- **dining_tables**: Table information with status tracking
- **orders**: Order records with customer and status information
- **order_items**: Individual items within orders

## Network Services
- **HTTP Server**: Port 8080 - REST API for data operations
- **WebSocket Server**: Port 8081 - Real-time synchronization
- **UDP Discovery**: Port 8082 - Auto-discovery broadcast service

## Common Commands
```bash
# Run the app
flutter run

# Build APK
flutter build apk

# Run tests
flutter test

# Check dependencies
flutter pub deps

# Clean build
flutter clean && flutter pub get
```

## Development Setup
1. Ensure Flutter SDK is installed
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app
4. The app will automatically start all server services

## Key Dependencies
- `sqflite`: SQLite database
- `provider`: State management
- `web_socket_channel`: WebSocket communication
- `shelf`: HTTP server framework
- `shelf_router`: HTTP routing
- `shelf_cors_headers`: CORS support

## Real-time Features
- Table status updates broadcast to all connected clients with bidirectional sync
- Order creation/updates synchronized across apps with immediate notifications
- Product availability changes reflected immediately across all clients
- Client connection/disconnection handling with automatic recovery
- Heartbeat monitoring to maintain connection health
- Automatic client reconnection support with data resynchronization

## Testing
- Unit tests for database operations
- Widget tests for UI components
- Integration tests for real-time synchronization

## Troubleshooting
- **Connection Issues**: Check firewall settings for ports 8080, 8081, 8082
- **Database Errors**: Clear app data or reinstall to reset database
- **Real-time Sync**: Verify WebSocket connections in logs and check heartbeat monitoring
- **Network Discovery**: Ensure UDP broadcast is enabled on network
- **Client Reconnection**: Monitor WebSocket client connections and heartbeat responses
- **Network Changes**: Server automatically adapts to IP changes and broadcasts discovery
- **Performance**: Monitor console logs for excessive messages or connection issues

## Color Coding System
- **Green**: Available tables
- **Red**: Occupied tables  
- **Yellow**: Billed tables
- **Grey**: Unavailable/maintenance tables

## API Endpoints
- `GET /api/tables` - Get all tables
- `POST /api/tables` - Create table
- `PATCH /api/tables/:id/status` - Update table status
- `GET /api/products` - Get all products
- `POST /api/orders` - Create order
- `GET /api/orders/table/:id` - Get orders for table
- `GET /health` - Health check

## WebSocket Message Types
- `table_status_update` - Table status changes
- `order_created` - New order notifications
- `order_updated` - Order modifications
- `product_update` - Product changes
- `heartbeat` - Connection maintenance