import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/dining_table.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import 'database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables
    await db.execute(DatabaseConstants.createProductsTable);
    await db.execute(DatabaseConstants.createDiningTablesTable);
    await db.execute(DatabaseConstants.createOrdersTable);
    await db.execute(DatabaseConstants.createOrderItemsTable);

    // Create indexes
    final indexes = DatabaseConstants.createIndexes.split(';');
    for (final index in indexes) {
      if (index.trim().isNotEmpty) {
        await db.execute(index.trim());
      }
    }

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    // For now, we'll just recreate the database
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.orderItemsTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.ordersTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.diningTablesTable}');
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.productsTable}');
    await _onCreate(db, newVersion);
  }

  Future<void> _insertSampleData(Database db) async {
    // Insert sample products
    for (final product in DatabaseConstants.sampleProducts) {
      await db.insert(DatabaseConstants.productsTable, product);
    }

    // Insert sample tables
    for (final table in DatabaseConstants.sampleTables) {
      await db.insert(DatabaseConstants.diningTablesTable, table);
    }
  }

  // PRODUCT CRUD OPERATIONS
  Future<int> insertProduct(Product product) async {
    final db = await database;
    final productMap = product.toMap();
    productMap[DatabaseConstants.productCreatedAt] = DateTime.now().toIso8601String();
    return await db.insert(DatabaseConstants.productsTable, productMap);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query(DatabaseConstants.productsTable);
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.productsTable,
      where: '${DatabaseConstants.productCategory} = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<List<Product>> getAvailableProducts() async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.productsTable,
      where: '${DatabaseConstants.productIsAvailable} = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.productsTable,
      where: '${DatabaseConstants.productId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    final productMap = product.toMap();
    productMap[DatabaseConstants.productUpdatedAt] = DateTime.now().toIso8601String();
    return await db.update(
      DatabaseConstants.productsTable,
      productMap,
      where: '${DatabaseConstants.productId} = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      DatabaseConstants.productsTable,
      where: '${DatabaseConstants.productId} = ?',
      whereArgs: [id],
    );
  }

  // DINING TABLE CRUD OPERATIONS
  Future<int> insertDiningTable(DiningTable table) async {
    final db = await database;
    final tableMap = table.toMap();
    tableMap[DatabaseConstants.tableCreatedAt] = DateTime.now().toIso8601String();
    return await db.insert(DatabaseConstants.diningTablesTable, tableMap);
  }

  Future<List<DiningTable>> getAllDiningTables() async {
    final db = await database;
    final maps = await db.query(DatabaseConstants.diningTablesTable);
    return List.generate(maps.length, (i) => DiningTable.fromMap(maps[i]));
  }

  Future<List<DiningTable>> getDiningTablesByStatus(TableStatus status) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.diningTablesTable,
      where: '${DatabaseConstants.tableStatus} = ?',
      whereArgs: [status.name],
    );
    return List.generate(maps.length, (i) => DiningTable.fromMap(maps[i]));
  }

  Future<DiningTable?> getDiningTableById(int id) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.diningTablesTable,
      where: '${DatabaseConstants.tableId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DiningTable.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateDiningTable(DiningTable table) async {
    final db = await database;
    final tableMap = table.toMap();
    tableMap[DatabaseConstants.tableUpdatedAt] = DateTime.now().toIso8601String();
    return await db.update(
      DatabaseConstants.diningTablesTable,
      tableMap,
      where: '${DatabaseConstants.tableId} = ?',
      whereArgs: [table.id],
    );
  }

  Future<int> deleteDiningTable(int id) async {
    final db = await database;
    return await db.delete(
      DatabaseConstants.diningTablesTable,
      where: '${DatabaseConstants.tableId} = ?',
      whereArgs: [id],
    );
  }

  // ORDER CRUD OPERATIONS
  Future<int> insertOrder(Order order) async {
    final db = await database;
    
    // Start a transaction to ensure data consistency
    return await db.transaction((txn) async {
      // Insert the order
      final orderMap = order.toMap();
      orderMap[DatabaseConstants.orderCreatedAt] = DateTime.now().toIso8601String();
      final orderId = await txn.insert(DatabaseConstants.ordersTable, orderMap);
      
      // Insert order items
      for (final item in order.items) {
        final itemMap = item.toMap();
        itemMap[DatabaseConstants.orderItemOrderId] = orderId;
        itemMap[DatabaseConstants.orderItemCreatedAt] = DateTime.now().toIso8601String();
        await txn.insert(DatabaseConstants.orderItemsTable, itemMap);
      }
      
      return orderId;
    });
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.ordersTable,
      orderBy: '${DatabaseConstants.orderCreatedAt} DESC',
    );
    
    final orders = <Order>[];
    for (final map in maps) {
      final items = await getOrderItemsByOrderId(map[DatabaseConstants.orderId] as int);
      orders.add(Order.fromMap(map, items: items));
    }
    
    return orders;
  }

  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.ordersTable,
      where: '${DatabaseConstants.orderStatus} = ?',
      whereArgs: [status.name],
      orderBy: '${DatabaseConstants.orderCreatedAt} DESC',
    );
    
    final orders = <Order>[];
    for (final map in maps) {
      final items = await getOrderItemsByOrderId(map[DatabaseConstants.orderId] as int);
      orders.add(Order.fromMap(map, items: items));
    }
    
    return orders;
  }

  Future<List<Order>> getOrdersByTableId(int tableId) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.ordersTable,
      where: '${DatabaseConstants.orderTableId} = ?',
      whereArgs: [tableId],
      orderBy: '${DatabaseConstants.orderCreatedAt} DESC',
    );
    
    final orders = <Order>[];
    for (final map in maps) {
      final items = await getOrderItemsByOrderId(map[DatabaseConstants.orderId] as int);
      orders.add(Order.fromMap(map, items: items));
    }
    
    return orders;
  }

  Future<Order?> getOrderById(int id) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.ordersTable,
      where: '${DatabaseConstants.orderId} = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      final items = await getOrderItemsByOrderId(id);
      return Order.fromMap(maps.first, items: items);
    }
    return null;
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    final orderMap = order.toMap();
    orderMap[DatabaseConstants.orderUpdatedAt] = DateTime.now().toIso8601String();
    return await db.update(
      DatabaseConstants.ordersTable,
      orderMap,
      where: '${DatabaseConstants.orderId} = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> updateOrderStatus(int orderId, OrderStatus status) async {
    final db = await database;
    final updateMap = <String, dynamic>{
      DatabaseConstants.orderStatus: status.name,
      DatabaseConstants.orderUpdatedAt: DateTime.now().toIso8601String(),
    };
    
    if (status == OrderStatus.served) {
      updateMap[DatabaseConstants.orderServedAt] = DateTime.now().toIso8601String();
    }
    
    return await db.update(
      DatabaseConstants.ordersTable,
      updateMap,
      where: '${DatabaseConstants.orderId} = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete(
      DatabaseConstants.ordersTable,
      where: '${DatabaseConstants.orderId} = ?',
      whereArgs: [id],
    );
  }

  // ORDER ITEM CRUD OPERATIONS
  Future<List<OrderItem>> getOrderItemsByOrderId(int orderId) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.orderItemsTable,
      where: '${DatabaseConstants.orderItemOrderId} = ?',
      whereArgs: [orderId],
    );
    return List.generate(maps.length, (i) => OrderItem.fromMap(maps[i]));
  }

  Future<int> insertOrderItem(OrderItem item) async {
    final db = await database;
    final itemMap = item.toMap();
    itemMap[DatabaseConstants.orderItemCreatedAt] = DateTime.now().toIso8601String();
    return await db.insert(DatabaseConstants.orderItemsTable, itemMap);
  }

  Future<int> updateOrderItem(OrderItem item) async {
    final db = await database;
    return await db.update(
      DatabaseConstants.orderItemsTable,
      item.toMap(),
      where: '${DatabaseConstants.orderItemId} = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteOrderItem(int id) async {
    final db = await database;
    return await db.delete(
      DatabaseConstants.orderItemsTable,
      where: '${DatabaseConstants.orderItemId} = ?',
      whereArgs: [id],
    );
  }

  // UTILITY METHODS
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    final productCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.productsTable}'),
    ) ?? 0;
    
    final tableCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.diningTablesTable}'),
    ) ?? 0;
    
    final orderCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.ordersTable}'),
    ) ?? 0;
    
    final orderItemCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.orderItemsTable}'),
    ) ?? 0;
    
    return {
      'products': productCount,
      'tables': tableCount,
      'orders': orderCount,
      'orderItems': orderItemCount,
    };
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DatabaseConstants.orderItemsTable);
      await txn.delete(DatabaseConstants.ordersTable);
      await txn.delete(DatabaseConstants.diningTablesTable);
      await txn.delete(DatabaseConstants.productsTable);
    });
    
    // Re-insert sample data
    await _insertSampleData(db);
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}