import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import '../database/database_helper.dart';
import '../models/dining_table.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/server_info.dart';
import '../models/websocket_message.dart';
import 'network_discovery_service.dart';
import 'realtime_sync_service.dart';
import 'websocket_service.dart';

class HttpServerService {
  static final HttpServerService _instance = HttpServerService._internal();
  factory HttpServerService() => _instance;
  HttpServerService._internal();

  HttpServer? _server;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final WebSocketService _webSocketService = WebSocketService();
  final NetworkDiscoveryService _discoveryService = NetworkDiscoveryService();
  final RealTimeSyncService _syncService = RealTimeSyncService();
  ServerInfo? _serverInfo;

  Future<void> start({int port = 8080}) async {
    try {
      // Get local IP address
      final ipAddress =
          await _discoveryService.getLocalIpAddress() ?? 'localhost';

      // Create server info
      _serverInfo = ServerInfo.create(
        ipAddress: ipAddress,
        httpPort: port,
        webSocketPort: 8081,
      );

      // Create router
      final router = Router();

      // Add routes
      _addProductRoutes(router);
      _addTableRoutes(router);
      _addOrderRoutes(router);
      _addSystemRoutes(router);

      // Create middleware pipeline
      final handler = Pipeline()
          .addMiddleware(corsHeaders())
          .addMiddleware(logRequests())
          .addMiddleware(_jsonMiddleware)
          .addHandler(router);

      // Start HTTP server
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      print('HTTP server started on http://$ipAddress:$port');

      // Start WebSocket server
      print('Starting WebSocket server...');
      await _webSocketService.start(port: 8081);
      print('WebSocket server started successfully');

      // Start network discovery
      print('Starting network discovery...');
      await _discoveryService.startBroadcasting(_serverInfo!);
      print('Network discovery started successfully');

      // Initialize sync service
      print('Initializing real-time sync service...');
      await _syncService.initialize();
      print('Real-time sync service initialized');

      print('All services started successfully');
    } catch (e) {
      print('Error starting HTTP server: $e');
      rethrow;
    }
  }

  Middleware get _jsonMiddleware => (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      return response.change(
        headers: {'Content-Type': 'application/json', ...response.headers},
      );
    };
  };

  void _addProductRoutes(Router router) {
    // GET /api/products - Get all products
    router.get('/api/products', (Request request) async {
      try {
        final products = await _dbHelper.getAllProducts();
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': products.map((p) => p.toJson()).toList(),
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // GET /api/products/available - Get available products
    router.get('/api/products/available', (Request request) async {
      try {
        final products = await _dbHelper.getAvailableProducts();
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': products.map((p) => p.toJson()).toList(),
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // GET /api/products/category/<category> - Get products by category
    router.get('/api/products/category/<category>', (Request request) async {
      try {
        final category = request.params['category']!;
        final products = await _dbHelper.getProductsByCategory(category);
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': products.map((p) => p.toJson()).toList(),
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // GET /api/products/<id> - Get product by ID
    router.get('/api/products/<id>', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final product = await _dbHelper.getProductById(id);
        if (product == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Product not found'}),
          );
        }
        return Response.ok(
          jsonEncode({'success': true, 'data': product.toJson()}),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // POST /api/products - Create new product
    router.post('/api/products', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final product = Product.fromJson(data);
        final id = await _dbHelper.insertProduct(product);

        // Broadcast product created
        final createdProduct = product.copyWith(id: id);
        final message = WebSocketMessage.productCreated(
          productData: createdProduct.toJson(),
        );
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'id': id},
          }),
        );
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // PUT /api/products/<id> - Update product
    router.put('/api/products/<id>', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final product = Product.fromJson(data).copyWith(id: id);

        final updated = await _dbHelper.updateProduct(product);
        if (updated == 0) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Product not found'}),
          );
        }

        // Broadcast product updated
        final message = WebSocketMessage.productUpdate(
          productId: id,
          name: product.name,
          isAvailable: product.isAvailable,
        );
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'updated': updated},
          }),
        );
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // DELETE /api/products/<id> - Delete product
    router.delete('/api/products/<id>', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final deleted = await _dbHelper.deleteProduct(id);
        if (deleted == 0) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Product not found'}),
          );
        }

        // Broadcast product deleted
        final message = WebSocketMessage.productDeleted(productId: id);
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'deleted': deleted},
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });
  }

  void _addTableRoutes(Router router) {
    // GET /api/tables - Get all tables
    router.get('/api/tables', (Request request) async {
      try {
        final tables = await _dbHelper.getAllDiningTables();
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': tables.map((t) => t.toJson()).toList(),
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // GET /api/tables/status/<status> - Get tables by status
    router.get('/api/tables/status/<status>', (Request request) async {
      try {
        final statusStr = request.params['status']!;
        final status = TableStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => TableStatus.available,
        );
        final tables = await _dbHelper.getDiningTablesByStatus(status);
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': tables.map((t) => t.toJson()).toList(),
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // GET /api/tables/<id> - Get table by ID
    router.get('/api/tables/<id>', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final table = await _dbHelper.getDiningTableById(id);
        if (table == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Table not found'}),
          );
        }
        return Response.ok(
          jsonEncode({'success': true, 'data': table.toJson()}),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // POST /api/tables - Create new table
    router.post('/api/tables', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final table = DiningTable.fromJson(data);
        final id = await _dbHelper.insertDiningTable(table);

        // Broadcast table created
        final createdTable = table.copyWith(id: id);
        final message = WebSocketMessage.tableCreated(
          tableData: createdTable.toJson(),
        );
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'id': id},
          }),
        );
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // PUT /api/tables/<id> - Update table
    router.put('/api/tables/<id>', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final table = DiningTable.fromJson(data).copyWith(id: id);

        final updated = await _dbHelper.updateDiningTable(table);
        if (updated == 0) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Table not found'}),
          );
        }

        // Broadcast table updated
        final message = WebSocketMessage.tableUpdated(
          tableData: table.toJson(),
        );
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'updated': updated},
          }),
        );
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // PATCH /api/tables/<id>/status - Update table status only
    router.patch('/api/tables/<id>/status', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final statusStr = data['status'] as String;

        final status = TableStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => TableStatus.available,
        );

        final table = await _dbHelper.getDiningTableById(id);
        if (table == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Table not found'}),
          );
        }

        final updatedTable = table.copyWith(status: status);
        final updated = await _dbHelper.updateDiningTable(updatedTable);

        // Broadcast table status update
        final message = WebSocketMessage.tableStatusUpdate(
          tableId: id,
          tableName: table.name,
          status: status.name,
        );
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'updated': updated},
          }),
        );
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // DELETE /api/tables/<id> - Delete table
    router.delete('/api/tables/<id>', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final deleted = await _dbHelper.deleteDiningTable(id);
        if (deleted == 0) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Table not found'}),
          );
        }

        // Broadcast table deleted
        final message = WebSocketMessage.tableDeleted(tableId: id);
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'deleted': deleted},
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });
  }

  void _addOrderRoutes(Router router) {
    // GET /api/orders - Get all orders
    router.get('/api/orders', (Request request) async {
      try {
        final orders = await _dbHelper.getAllOrders();
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': orders.map((o) => o.toJson()).toList(),
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // GET /api/orders/status/<status> - Get orders by status
    router.get('/api/orders/status/<status>', (Request request) async {
      try {
        final statusStr = request.params['status']!;
        final status = OrderStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => OrderStatus.pending,
        );
        final orders = await _dbHelper.getOrdersByStatus(status);
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': orders.map((o) => o.toJson()).toList(),
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // GET /api/orders/table/<tableId> - Get orders by table
    router.get('/api/orders/table/<tableId>', (Request request) async {
      try {
        final tableId = int.parse(request.params['tableId']!);
        final orders = await _dbHelper.getOrdersByTableId(tableId);
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': orders.map((o) => o.toJson()).toList(),
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // GET /api/orders/<id> - Get order by ID
    router.get('/api/orders/<id>', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final order = await _dbHelper.getOrderById(id);
        if (order == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Order not found'}),
          );
        }
        return Response.ok(
          jsonEncode({'success': true, 'data': order.toJson()}),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // POST /api/orders - Create new order
    router.post('/api/orders', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final order = Order.fromJson(data);
        final id = await _dbHelper.insertOrder(order);

        // Broadcast order created
        final createdOrder = order.copyWith(id: id);
        final message = WebSocketMessage.orderCreated(
          orderData: createdOrder.toJson(),
        );
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'id': id},
          }),
        );
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // PUT /api/orders/<id> - Update order
    router.put('/api/orders/<id>', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final order = Order.fromJson(data).copyWith(id: id);

        final updated = await _dbHelper.updateOrder(order);
        if (updated == 0) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Order not found'}),
          );
        }

        // Broadcast order updated
        final message = WebSocketMessage.orderUpdated(
          orderData: order.toJson(),
        );
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'updated': updated},
          }),
        );
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // PATCH /api/orders/<id>/status - Update order status only
    router.patch('/api/orders/<id>/status', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final statusStr = data['status'] as String;

        final status = OrderStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => OrderStatus.pending,
        );

        final updated = await _dbHelper.updateOrderStatus(id, status);
        if (updated == 0) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Order not found'}),
          );
        }

        // Get order to broadcast update
        final order = await _dbHelper.getOrderById(id);
        if (order != null) {
          final updatedOrder = order.copyWith(status: status);
          final message = WebSocketMessage.orderStatusUpdate(
            orderData: updatedOrder.toJson(),
          );
          _webSocketService.broadcastMessage(message);
        }

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'updated': updated},
          }),
        );
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // DELETE /api/orders/<id> - Delete order
    router.delete('/api/orders/<id>', (Request request) async {
      try {
        final id = int.parse(request.params['id']!);
        final deleted = await _dbHelper.deleteOrder(id);
        if (deleted == 0) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Order not found'}),
          );
        }

        // Broadcast order deleted
        final message = WebSocketMessage.orderDeleted(orderId: id);
        _webSocketService.broadcastMessage(message);

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'deleted': deleted},
          }),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });
  }

  void _addSystemRoutes(Router router) {
    // GET /api/system/info - Get server info
    router.get('/api/system/info', (Request request) async {
      return Response.ok(
        jsonEncode({'success': true, 'data': _serverInfo?.toJson()}),
      );
    });

    // GET /api/system/stats - Get database stats
    router.get('/api/system/stats', (Request request) async {
      try {
        final stats = await _dbHelper.getDatabaseStats();
        return Response.ok(jsonEncode({'success': true, 'data': stats}));
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // GET /api/system/websocket/clients - Get WebSocket clients info
    router.get('/api/system/websocket/clients', (Request request) async {
      return Response.ok(
        jsonEncode({
          'success': true,
          'data': {
            'clientCount': _webSocketService.clientCount,
            'clients': _webSocketService.getAllClientsInfo(),
          },
        }),
      );
    });

    // POST /api/system/broadcast - Broadcast system message
    router.post('/api/system/broadcast', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final message = data['message'] as String;
        final level = data['level'] as String?;

        _webSocketService.broadcastSystemMessage(
          message: message,
          level: level,
        );

        return Response.ok(
          jsonEncode({
            'success': true,
            'data': {'broadcasted': true},
          }),
        );
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'error': e.toString()}),
        );
      }
    });

    // Health check endpoint
    router.get('/health', (Request request) async {
      return Response.ok(
        jsonEncode({
          'status': 'healthy',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    });
  }

  Future<void> stop() async {
    print('Stopping HTTP server...');

    await _discoveryService.stop();
    await _webSocketService.stop();
    await _server?.close(force: true);

    _server = null;
    _serverInfo = null;

    print('HTTP server stopped');
  }
}
