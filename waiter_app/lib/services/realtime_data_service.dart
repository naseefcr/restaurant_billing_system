import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/websocket_message.dart';
import '../models/dining_table.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'server_connection_service.dart';

class RealTimeDataService extends ChangeNotifier {
  static final RealTimeDataService _instance = RealTimeDataService._internal();
  factory RealTimeDataService() => _instance;
  RealTimeDataService._internal();

  final ServerConnectionService _connectionService = ServerConnectionService();
  StreamSubscription? _webSocketSubscription;

  // Local data caches
  final Map<int, DiningTable> _tablesCache = {};
  final Map<int, Order> _ordersCache = {};
  final Map<int, Product> _productsCache = {};

  // Notification streams
  final StreamController<DiningTable> _tableUpdateController = 
      StreamController<DiningTable>.broadcast();
  final StreamController<Order> _orderUpdateController = 
      StreamController<Order>.broadcast();
  final StreamController<Product> _productUpdateController = 
      StreamController<Product>.broadcast();
  final StreamController<String> _notificationController = 
      StreamController<String>.broadcast();

  // Getters
  Map<int, DiningTable> get tablesCache => Map.unmodifiable(_tablesCache);
  Map<int, Order> get ordersCache => Map.unmodifiable(_ordersCache);
  Map<int, Product> get productsCache => Map.unmodifiable(_productsCache);
  
  Stream<DiningTable> get tableUpdates => _tableUpdateController.stream;
  Stream<Order> get orderUpdates => _orderUpdateController.stream;
  Stream<Product> get productUpdates => _productUpdateController.stream;
  Stream<String> get notifications => _notificationController.stream;

  void initialize() {
    // Only initialize if not already initialized
    if (_webSocketSubscription != null) {
      print('RealTimeDataService already initialized');
      return;
    }
    
    // Check if WebSocket service is connected
    if (!_connectionService.webSocketService.isConnected) {
      print('WebSocket service not connected, skipping initialization');
      return;
    }
    
    // Listen to WebSocket messages
    _webSocketSubscription = _connectionService.webSocketService.messageStream
        .listen(
          _handleWebSocketMessage,
          onError: (error) {
            print('WebSocket message stream error: $error');
          },
          onDone: () {
            print('WebSocket message stream closed');
          },
        );
    
    print('RealTimeDataService initialized and listening to WebSocket messages');
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    print('RealTimeDataService: Handling real-time message: ${message.type}');
    print('Message data: ${message.data}');

    switch (message.type) {
      case WebSocketMessageType.tableStatusUpdate:
      case WebSocketMessageType.tableCreated:
      case WebSocketMessageType.tableUpdated:
      case WebSocketMessageType.tableDeleted:
        _handleTableUpdate(message);
        break;

      case WebSocketMessageType.orderCreated:
      case WebSocketMessageType.orderUpdated:
      case WebSocketMessageType.orderStatusUpdate:
      case WebSocketMessageType.orderDeleted:
        _handleOrderUpdate(message);
        break;

      case WebSocketMessageType.productUpdate:
      case WebSocketMessageType.productCreated:
      case WebSocketMessageType.productDeleted:
      case WebSocketMessageType.productAvailabilityChanged:
        _handleProductUpdate(message);
        break;

      case WebSocketMessageType.systemMessage:
        _handleSystemMessage(message);
        break;

      default:
        print('Unhandled message type: ${message.type}');
    }
  }

  void _handleTableUpdate(WebSocketMessage message) {
    try {
      final data = message.data;

      switch (message.type) {
        case WebSocketMessageType.tableStatusUpdate:
          final tableId = data['tableId'] as int;
          final status = data['status'] as String;
          final tableName = data['tableName'] as String;

          if (_tablesCache.containsKey(tableId)) {
            final tableStatus = TableStatus.values.firstWhere(
              (s) => s.name == status,
              orElse: () => TableStatus.available,
            );

            _tablesCache[tableId] = _tablesCache[tableId]!.copyWith(
              status: tableStatus,
              updatedAt: DateTime.now(),
            );

            _tableUpdateController.add(_tablesCache[tableId]!);
            _notificationController.add('Table $tableName status changed to ${tableStatus.name}');
          }
          break;

        case WebSocketMessageType.tableCreated:
          final tableData = data['table'] as Map<String, dynamic>;
          final table = DiningTable.fromJson(tableData);

          if (table.id != null) {
            _tablesCache[table.id!] = table;
            _tableUpdateController.add(table);
            _notificationController.add('New table added: ${table.name}');
          }
          break;

        case WebSocketMessageType.tableUpdated:
          final tableData = data['table'] as Map<String, dynamic>;
          final table = DiningTable.fromJson(tableData);

          if (table.id != null) {
            _tablesCache[table.id!] = table;
            _tableUpdateController.add(table);
            _notificationController.add('Table ${table.name} updated');
          }
          break;

        case WebSocketMessageType.tableDeleted:
          final tableId = data['tableId'] as int;
          final removedTable = _tablesCache.remove(tableId);
          if (removedTable != null) {
            _notificationController.add('Table ${removedTable.name} removed');
          }
          break;

        default:
          break;
      }

      notifyListeners();
    } catch (e) {
      print('Error handling table update: $e');
    }
  }

  void _handleOrderUpdate(WebSocketMessage message) {
    try {
      final data = message.data;

      switch (message.type) {
        case WebSocketMessageType.orderCreated:
          final orderData = data['order'] as Map<String, dynamic>;
          final order = Order.fromJson(orderData);

          if (order.id != null) {
            _ordersCache[order.id!] = order;
            _orderUpdateController.add(order);
            _notificationController.add('New order #${order.id} created for table ${order.tableName}');
          }
          break;

        case WebSocketMessageType.orderUpdated:
        case WebSocketMessageType.orderStatusUpdate:
          final orderData = data['order'] as Map<String, dynamic>;
          final order = Order.fromJson(orderData);

          if (order.id != null) {
            _ordersCache[order.id!] = order;
            _orderUpdateController.add(order);
            _notificationController.add('Order #${order.id} updated: ${order.status.name}');
          }
          break;

        case WebSocketMessageType.orderDeleted:
          final orderId = data['orderId'] as int;
          final removedOrder = _ordersCache.remove(orderId);
          if (removedOrder != null) {
            _notificationController.add('Order #$orderId has been removed');
          }
          break;

        default:
          break;
      }

      notifyListeners();
    } catch (e) {
      print('Error handling order update: $e');
    }
  }

  void _handleProductUpdate(WebSocketMessage message) {
    try {
      final data = message.data;

      switch (message.type) {
        case WebSocketMessageType.productUpdate:
        case WebSocketMessageType.productAvailabilityChanged:
          final productId = data['productId'] as int;
          final name = data['name'] as String?;
          final isAvailable = data['isAvailable'] as bool?;

          if (_productsCache.containsKey(productId)) {
            _productsCache[productId] = _productsCache[productId]!.copyWith(
              name: name,
              isAvailable: isAvailable,
              updatedAt: DateTime.now(),
            );

            _productUpdateController.add(_productsCache[productId]!);
            
            if (isAvailable != null) {
              final status = isAvailable ? 'available' : 'unavailable';
              _notificationController.add('Product ${name ?? 'Unknown'} is now $status');
            }
          }
          break;

        case WebSocketMessageType.productCreated:
          final productData = data['product'] as Map<String, dynamic>;
          final product = Product.fromJson(productData);

          if (product.id != null) {
            _productsCache[product.id!] = product;
            _productUpdateController.add(product);
            _notificationController.add('New product added: ${product.name}');
          }
          break;

        case WebSocketMessageType.productDeleted:
          final productId = data['productId'] as int;
          final removedProduct = _productsCache.remove(productId);
          if (removedProduct != null) {
            _notificationController.add('Product ${removedProduct.name} removed');
          }
          break;

        default:
          break;
      }

      notifyListeners();
    } catch (e) {
      print('Error handling product update: $e');
    }
  }

  void _handleSystemMessage(WebSocketMessage message) {
    try {
      final data = message.data;
      final messageText = data['message'] as String;
      final level = data['level'] as String? ?? 'info';

      print('System message [$level]: $messageText');
      _notificationController.add('System: $messageText');
    } catch (e) {
      print('Error handling system message: $e');
    }
  }

  // Methods to update local cache from API responses
  void updateTablesCache(List<DiningTable> tables) {
    _tablesCache.clear();
    for (final table in tables) {
      if (table.id != null) {
        _tablesCache[table.id!] = table;
      }
    }
    notifyListeners();
  }

  void updateOrdersCache(List<Order> orders) {
    _ordersCache.clear();
    for (final order in orders) {
      if (order.id != null) {
        _ordersCache[order.id!] = order;
      }
    }
    notifyListeners();
  }

  void updateProductsCache(List<Product> products) {
    _productsCache.clear();
    for (final product in products) {
      if (product.id != null) {
        _productsCache[product.id!] = product;
      }
    }
    notifyListeners();
  }

  // Method to get filtered data
  List<DiningTable> getTablesByStatus(TableStatus status) {
    return _tablesCache.values
        .where((table) => table.status == status)
        .toList();
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _ordersCache.values
        .where((order) => order.status == status)
        .toList();
  }

  List<Order> getOrdersByTableId(int tableId) {
    return _ordersCache.values
        .where((order) => order.tableId == tableId)
        .toList();
  }

  List<Product> getAvailableProducts() {
    return _productsCache.values
        .where((product) => product.isAvailable)
        .toList();
  }

  // Request full sync from server
  void requestFullSync() {
    _connectionService.webSocketService.requestSync('all');
  }

  void requestTableSync() {
    _connectionService.webSocketService.requestSync('tables');
  }

  void requestOrderSync() {
    _connectionService.webSocketService.requestSync('orders');
  }

  void requestProductSync() {
    _connectionService.webSocketService.requestSync('products');
  }

  @override
  void dispose() {
    _webSocketSubscription?.cancel();
    _tableUpdateController.close();
    _orderUpdateController.close();
    _productUpdateController.close();
    _notificationController.close();
    super.dispose();
  }
}