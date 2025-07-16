# Restaurant Billing System - Waiter App

## Project Overview
A Flutter-based waiter application for restaurant order management that connects to the cashier app server. This app allows waiters to view table status, create orders, and sync data in real-time with the main cashier system.

## Architecture
- **Type**: Flutter Mobile App (Client-side)
- **Connection**: HTTP REST API + WebSocket client
- **Network**: UDP discovery client for server auto-discovery
- **State Management**: Provider pattern
- **UI**: Material Design with TabBar navigation
- **Local Cache**: In-memory caching with real-time updates

## Key Features
- Automatic server discovery via UDP broadcast
- Real-time table status synchronization
- Order creation and submission
- Product catalog viewing
- Table management with color-coded status
- Connection status monitoring
- Manual server connection option

## Project Structure
```
lib/
├── main.dart                              # App entry point
├── screens/
│   ├── waiter_home_screen.dart           # Main tabbed interface
│   └── server_discovery_screen.dart      # Server discovery and connection
├── services/
│   ├── server_connection_service.dart    # HTTP API client
│   ├── websocket_client_service.dart     # WebSocket client for real-time sync
│   ├── network_discovery_service.dart    # UDP discovery client
│   └── realtime_data_service.dart        # Real-time data management
├── models/
│   ├── dining_table.dart                 # Table model with status
│   ├── order.dart                        # Order model with items
│   ├── product.dart                      # Product model
│   ├── order_item.dart                   # Order item model
│   ├── server_info.dart                  # Server information model
│   ├── discovered_server.dart            # Discovered server model
│   └── websocket_message.dart            # WebSocket message types
└── providers/
    └── server_connection_service.dart    # Connection state management
```

## Connection Flow
1. **Discovery**: UDP broadcast to find cashier app servers
2. **HTTP Connection**: Establish REST API connection
3. **WebSocket Connection**: Connect for real-time updates
4. **Data Sync**: Initial data fetch and cache population
5. **Real-time Updates**: Continuous synchronization

## Network Services
- **HTTP Client**: Connects to cashier app port 8080
- **WebSocket Client**: Connects to cashier app port 8081
- **UDP Discovery**: Listens on port 8082 for server broadcasts

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
3. Ensure cashier app is running on the same network
4. Run `flutter run` to start the app
5. Use server discovery or manual connection to connect

## Key Dependencies
- `provider`: State management
- `web_socket_channel`: WebSocket communication
- `http`: HTTP client for REST API
- `flutter/material`: UI components

## Real-time Features
- Automatic table status updates from cashier app
- Order notifications and status changes
- Product availability updates
- Connection status monitoring
- Automatic reconnection on connection loss

## Server Discovery
- **Automatic**: UDP broadcast scanning every 15 seconds
- **Manual**: Direct IP address connection option
- **Connection Validation**: HTTP health check before connection
- **Fallback**: Manual connection when discovery fails

## UI Components
- **Server Discovery Screen**: Connection management
- **Tables Tab**: Color-coded table grid with status
- **Orders Tab**: Order creation and management
- **Products Tab**: Available product catalog
- **Connection Status**: Real-time connection indicator

## Color Coding System
- **Green**: Available tables
- **Red**: Occupied tables
- **Yellow**: Billed tables
- **Grey**: Unavailable/maintenance tables

## Order Management
- Select table → Choose products → Set quantities → Submit order
- Multiple orders per table support
- Order status tracking
- Real-time order updates

## Connection States
- **Disconnected**: No server connection
- **Discovering**: Searching for servers
- **Connecting**: Establishing connection
- **Connected**: Fully operational
- **Reconnecting**: Attempting to restore connection
- **Error**: Connection failed

## API Endpoints Used
- `GET /api/tables` - Fetch table status
- `GET /api/products/available` - Get available products
- `POST /api/orders` - Submit new orders
- `GET /api/orders/table/:id` - Get table orders
- `GET /health` - Connection health check

## WebSocket Message Handling
- `table_status_update` - Update table status in real-time
- `order_created` - New order notifications
- `order_updated` - Order status changes
- `product_update` - Product availability changes
- `heartbeat` - Connection maintenance

## Troubleshooting
- **Discovery Issues**: Check network connectivity and firewall
- **Connection Timeout**: Verify cashier app is running and accessible
- **Real-time Sync**: Check WebSocket connection status
- **Order Submission**: Ensure all required fields are provided
- **Network Issues**: Use manual connection with IP address

## Testing
- Unit tests for HTTP client operations
- Widget tests for UI components
- Integration tests for real-time synchronization
- Connection reliability tests

## Error Handling
- Network connectivity errors
- Server unavailability
- Invalid server responses
- WebSocket disconnections
- Order submission failures

## Performance Optimization
- Efficient data caching
- Reduced UDP discovery frequency
- Optimized WebSocket message handling
- Minimal UI rebuilds with Provider