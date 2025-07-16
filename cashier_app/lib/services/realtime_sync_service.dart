import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/websocket_message.dart';
import '../models/product.dart';
import '../models/dining_table.dart';
import '../models/order.dart';
import 'websocket_service.dart';

class RealTimeSyncService extends ChangeNotifier {
  static final RealTimeSyncService _instance = RealTimeSyncService._internal();
  factory RealTimeSyncService() => _instance;
  RealTimeSyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final WebSocketService _webSocketService = WebSocketService();
  
  final StreamController<Map<String, dynamic>> _syncEventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  StreamSubscription? _webSocketSubscription;
  
  // Data caches for quick access
  final Map<int, DiningTable> _tablesCache = {};
  final Map<int, Order> _ordersCache = {};
  final Map<int, Product> _productsCache = {};
  
  // Getters
  Stream<Map<String, dynamic>> get syncEvents => _syncEventController.stream;
  Map<int, DiningTable> get tablesCache => Map.unmodifiable(_tablesCache);
  Map<int, Order> get ordersCache => Map.unmodifiable(_ordersCache);
  Map<int, Product> get productsCache => Map.unmodifiable(_productsCache);

  Future<void> initialize() async {
    // Load initial data into cache
    await _loadInitialData();
    
    // Listen to WebSocket messages
    _webSocketSubscription = _webSocketService.messageStream.listen(
      _handleWebSocketMessage,
      onError: (error) {
        print('RealTimeSync WebSocket error: $error');
      },
    );
    
    print('RealTimeSyncService initialized');
  }

  Future<void> _loadInitialData() async {
    try {
      // Load tables
      final tables = await _dbHelper.getAllDiningTables();
      _tablesCache.clear();
      for (final table in tables) {
        if (table.id != null) {
          _tablesCache[table.id!] = table;
        }
      }

      // Load orders
      final orders = await _dbHelper.getAllOrders();
      _ordersCache.clear();
      for (final order in orders) {
        if (order.id != null) {
          _ordersCache[order.id!] = order;
        }
      }

      // Load products
      final products = await _dbHelper.getAllProducts();
      _productsCache.clear();
      for (final product in products) {
        if (product.id != null) {
          _productsCache[product.id!] = product;
        }
      }

      print('Initial data loaded: ${_tablesCache.length} tables, ${_ordersCache.length} orders, ${_productsCache.length} products');
      notifyListeners();
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    print('Handling WebSocket message: ${message.type}');
    
    // Don't process our own messages
    if (message.clientId != null && message.clientId == _getCurrentClientId()) {
      return;
    }

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
        
      case WebSocketMessageType.syncRequest:
        _handleSyncRequest(message);
        break;
        
      case WebSocketMessageType.syncResponse:
        _handleSyncResponse(message);
        break;
        
      case WebSocketMessageType.fullSync:
        _handleFullSync(message);
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
          
          if (_tablesCache.containsKey(tableId)) {
            final tableStatus = TableStatus.values.firstWhere(
              (s) => s.name == status,
              orElse: () => TableStatus.available,
            );
            
            _tablesCache[tableId] = _tablesCache[tableId]!.copyWith(
              status: tableStatus,
              updatedAt: DateTime.now(),
            );
            
            _emitSyncEvent('table_status_updated', {
              'tableId': tableId,
              'status': status,
              'table': _tablesCache[tableId]!.toJson(),
            });
          }
          break;
          
        case WebSocketMessageType.tableCreated:
          final tableData = data['table'] as Map<String, dynamic>;
          final table = DiningTable.fromJson(tableData);
          
          if (table.id != null) {
            _tablesCache[table.id!] = table;
            _emitSyncEvent('table_created', {
              'table': table.toJson(),
            });
          }
          break;
          
        case WebSocketMessageType.tableUpdated:
          final tableData = data['table'] as Map<String, dynamic>;
          final table = DiningTable.fromJson(tableData);
          
          if (table.id != null) {
            _tablesCache[table.id!] = table;
            _emitSyncEvent('table_updated', {
              'table': table.toJson(),
            });
          }
          break;
          
        case WebSocketMessageType.tableDeleted:
          final tableId = data['tableId'] as int;
          _tablesCache.remove(tableId);
          _emitSyncEvent('table_deleted', {
            'tableId': tableId,
          });
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
            _emitSyncEvent('order_created', {
              'order': order.toJson(),
            });
          }
          break;
          
        case WebSocketMessageType.orderUpdated:
        case WebSocketMessageType.orderStatusUpdate:
          final orderData = data['order'] as Map<String, dynamic>?;
          
          if (orderData != null) {
            final order = Order.fromJson(orderData);
            if (order.id != null) {
              _ordersCache[order.id!] = order;
              _emitSyncEvent('order_updated', {
                'order': order.toJson(),
              });
            }
          } else {
            // Handle status-only updates
            final orderId = data['orderId'] as int;
            final status = data['status'] as String;
            
            if (_ordersCache.containsKey(orderId)) {
              final orderStatus = OrderStatus.values.firstWhere(
                (s) => s.name == status,
                orElse: () => OrderStatus.pending,
              );
              
              _ordersCache[orderId] = _ordersCache[orderId]!.copyWith(
                status: orderStatus,
                updatedAt: DateTime.now(),
              );
              
              _emitSyncEvent('order_status_updated', {
                'orderId': orderId,
                'status': status,
                'order': _ordersCache[orderId]!.toJson(),
              });
            }
          }
          break;
          
        case WebSocketMessageType.orderDeleted:
          final orderId = data['orderId'] as int;
          _ordersCache.remove(orderId);
          _emitSyncEvent('order_deleted', {
            'orderId': orderId,
          });
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
            
            _emitSyncEvent('product_updated', {
              'productId': productId,
              'product': _productsCache[productId]!.toJson(),
            });
          }
          break;
          
        case WebSocketMessageType.productCreated:
          final productData = data['product'] as Map<String, dynamic>;
          final product = Product.fromJson(productData);
          
          if (product.id != null) {
            _productsCache[product.id!] = product;
            _emitSyncEvent('product_created', {
              'product': product.toJson(),
            });
          }
          break;
          
        case WebSocketMessageType.productDeleted:
          final productId = data['productId'] as int;
          _productsCache.remove(productId);
          _emitSyncEvent('product_deleted', {
            'productId': productId,
          });
          break;
          
        default:
          break;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error handling product update: $e');
    }
  }

  void _handleSyncRequest(WebSocketMessage message) {
    try {
      final syncType = message.data['syncType'] as String;
      final requestId = message.data['requestId'] as String;
      
      Map<String, dynamic> syncData = {};
      
      switch (syncType) {
        case 'tables':
          syncData = {
            'tables': _tablesCache.values.map((t) => t.toJson()).toList(),
          };
          break;
        case 'orders':
          syncData = {
            'orders': _ordersCache.values.map((o) => o.toJson()).toList(),
          };
          break;
        case 'products':
          syncData = {
            'products': _productsCache.values.map((p) => p.toJson()).toList(),
          };
          break;
        case 'all':
          syncData = {
            'tables': _tablesCache.values.map((t) => t.toJson()).toList(),
            'orders': _ordersCache.values.map((o) => o.toJson()).toList(),
            'products': _productsCache.values.map((p) => p.toJson()).toList(),
          };
          break;
      }
      
      final response = WebSocketMessage.syncResponse(
        syncType: syncType,
        syncData: syncData,
        requestId: requestId,
      );
      
      _webSocketService.broadcastMessage(response);
    } catch (e) {
      print('Error handling sync request: $e');
    }
  }

  void _handleSyncResponse(WebSocketMessage message) {
    // Handle sync responses if needed
    print('Received sync response: ${message.data}');
  }

  void _handleFullSync(WebSocketMessage message) {
    try {
      final allData = message.data['allData'] as Map<String, dynamic>;
      
      // Update caches with full sync data
      if (allData.containsKey('tables')) {
        _tablesCache.clear();
        final tablesData = allData['tables'] as List<dynamic>;
        for (final tableData in tablesData) {
          final table = DiningTable.fromJson(tableData);
          if (table.id != null) {
            _tablesCache[table.id!] = table;
          }
        }
      }
      
      if (allData.containsKey('orders')) {
        _ordersCache.clear();
        final ordersData = allData['orders'] as List<dynamic>;
        for (final orderData in ordersData) {
          final order = Order.fromJson(orderData);
          if (order.id != null) {
            _ordersCache[order.id!] = order;
          }
        }
      }
      
      if (allData.containsKey('products')) {
        _productsCache.clear();
        final productsData = allData['products'] as List<dynamic>;
        for (final productData in productsData) {
          final product = Product.fromJson(productData);
          if (product.id != null) {
            _productsCache[product.id!] = product;
          }
        }
      }
      
      _emitSyncEvent('full_sync_received', allData);
      notifyListeners();
    } catch (e) {
      print('Error handling full sync: $e');
    }
  }

  void _emitSyncEvent(String eventType, Map<String, dynamic> data) {
    _syncEventController.add({
      'type': eventType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  String? _getCurrentClientId() {
    // This should return the current client ID
    // For now, we'll return null to process all messages
    return null;
  }

  // Public methods to broadcast changes
  Future<void> broadcastTableStatusUpdate(int tableId, String status) async {
    try {
      final table = await _dbHelper.getDiningTableById(tableId);
      if (table != null) {
        final message = WebSocketMessage.tableStatusUpdate(
          tableId: tableId,
          tableName: table.name,
          status: status,
        );
        _webSocketService.broadcastMessage(message);
      }
    } catch (e) {
      print('Error broadcasting table status update: $e');
    }
  }

  Future<void> broadcastOrderCreated(Order order) async {
    try {
      final message = WebSocketMessage.orderCreated(
        orderData: order.toJson(),
      );
      _webSocketService.broadcastMessage(message);
    } catch (e) {
      print('Error broadcasting order created: $e');
    }
  }

  Future<void> broadcastOrderUpdated(Order order) async {
    try {
      final message = WebSocketMessage.orderUpdated(
        orderData: order.toJson(),
      );
      _webSocketService.broadcastMessage(message);
    } catch (e) {
      print('Error broadcasting order updated: $e');
    }
  }

  Future<void> broadcastOrderDeleted(int orderId) async {
    try {
      final message = WebSocketMessage.orderDeleted(
        orderId: orderId,
      );
      _webSocketService.broadcastMessage(message);
    } catch (e) {
      print('Error broadcasting order deleted: $e');
    }
  }

  Future<void> requestSync(String syncType) async {
    try {
      final message = WebSocketMessage.syncRequest(
        syncType: syncType,
      );
      _webSocketService.broadcastMessage(message);
    } catch (e) {
      print('Error requesting sync: $e');
    }
  }

  @override
  void dispose() {
    _webSocketSubscription?.cancel();
    _syncEventController.close();
    super.dispose();
  }
}