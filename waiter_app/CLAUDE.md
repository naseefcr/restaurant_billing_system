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
- Automatic server discovery via UDP broadcast with network change detection
- Real-time table status synchronization with reconnection recovery
- Order creation and submission with immediate UI updates
- Product catalog viewing with availability sync
- Table management with color-coded status
- Connection health monitoring with visual indicators
- Manual server connection option with refresh capabilities
- Automatic reconnection and data sync after network interruptions

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
1. **Discovery**: UDP broadcast to find cashier app servers with network monitoring
2. **HTTP Connection**: Establish REST API connection with health checks
3. **WebSocket Connection**: Connect for real-time updates with heartbeat monitoring
4. **Data Sync**: Initial data fetch and cache population
5. **Real-time Updates**: Continuous synchronization with automatic recovery
6. **Health Monitoring**: Connection health checks every 30 seconds
7. **Auto-Recovery**: Automatic reconnection and data resync on network changes

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
- Automatic table status updates from cashier app with bidirectional sync
- Order notifications and status changes with immediate UI updates
- Product availability updates with real-time inventory sync
- Connection health monitoring with visual indicators (green/orange/red)
- Automatic reconnection on connection loss with data resynchronization
- Network change detection with automatic discovery restart
- Heartbeat monitoring to detect stale connections
- Manual refresh capabilities for both connection and discovery

## Server Discovery
- **Automatic**: UDP broadcast scanning every 15 seconds with network change detection
- **Manual**: Direct IP address connection option with refresh button
- **Connection Validation**: HTTP health check before connection
- **Network Monitoring**: Detects IP changes and restarts discovery automatically
- **Fallback**: Manual connection when discovery fails
- **Refresh Capability**: Manual refresh button to clear stale servers and restart discovery

## UI Components
- **Server Discovery Screen**: Connection management with refresh functionality
- **Tables Tab**: Color-coded table grid with real-time status updates
- **Orders Tab**: Order creation and management with live updates
- **Products Tab**: Available product catalog with real-time availability
- **Connection Health Indicator**: Visual status (green/orange/red) in app bar
- **Manual Refresh Buttons**: For both connection and discovery
- **Real-time Notifications**: User feedback for connection status changes

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
- **Discovering**: Searching for servers with network monitoring
- **Connecting**: Establishing connection with validation
- **Connected**: Fully operational with health monitoring
- **Reconnecting**: Attempting to restore connection with data resync
- **Error**: Connection failed with recovery options

## Connection Health Indicators
- **Green WiFi Icon**: Connected and healthy (heartbeat < 60s)
- **Orange Warning Icon**: Connected but potentially stale (no recent heartbeat)
- **Red WiFi-off Icon**: Disconnected or connection failed

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
- **Discovery Issues**: Check network connectivity, firewall, or use manual refresh button
- **Connection Timeout**: Verify cashier app is running and use connection health indicator
- **Real-time Sync**: Check WebSocket connection health (green/orange/red indicator)
- **Order Submission**: Ensure all required fields are provided and connection is healthy
- **Network Issues**: Use manual connection with IP address or refresh discovery
- **Stale Connection**: Use manual refresh button in app bar to force reconnection
- **After Network Changes**: Wait for automatic detection or use refresh functionality

## Manual Recovery Options
- **Refresh Connection**: Tap refresh button in app bar to force reconnection
- **Refresh Discovery**: Tap refresh button in discovery screen to restart scanning
- **Manual Connection**: Enter server IP directly if discovery fails
- **Connection Health**: Check color indicator for connection status

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