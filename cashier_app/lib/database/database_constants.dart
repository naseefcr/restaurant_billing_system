class DatabaseConstants {
  static const String databaseName = 'restaurant_billing.db';
  static const int databaseVersion = 1;

  // Table names
  static const String productsTable = 'products';
  static const String diningTablesTable = 'dining_tables';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';

  // Products table columns
  static const String productId = 'id';
  static const String productName = 'name';
  static const String productPrice = 'price';
  static const String productDescription = 'description';
  static const String productCategory = 'category';
  static const String productIsAvailable = 'is_available';
  static const String productCreatedAt = 'created_at';
  static const String productUpdatedAt = 'updated_at';

  // Dining tables table columns
  static const String tableId = 'id';
  static const String tableName = 'name';
  static const String tableCapacity = 'capacity';
  static const String tableStatus = 'status';
  static const String tableLocation = 'location';
  static const String tableCreatedAt = 'created_at';
  static const String tableUpdatedAt = 'updated_at';

  // Orders table columns
  static const String orderId = 'id';
  static const String orderTableId = 'table_id';
  static const String orderTableName = 'table_name';
  static const String orderTotalAmount = 'total_amount';
  static const String orderStatus = 'status';
  static const String orderCustomerName = 'customer_name';
  static const String orderSpecialInstructions = 'special_instructions';
  static const String orderCreatedAt = 'created_at';
  static const String orderUpdatedAt = 'updated_at';
  static const String orderServedAt = 'served_at';

  // Order items table columns
  static const String orderItemId = 'id';
  static const String orderItemOrderId = 'order_id';
  static const String orderItemProductId = 'product_id';
  static const String orderItemProductName = 'product_name';
  static const String orderItemUnitPrice = 'unit_price';
  static const String orderItemQuantity = 'quantity';
  static const String orderItemTotalPrice = 'total_price';
  static const String orderItemSpecialInstructions = 'special_instructions';
  static const String orderItemCreatedAt = 'created_at';

  // SQL for creating tables
  static const String createProductsTable = '''
    CREATE TABLE $productsTable (
      $productId INTEGER PRIMARY KEY AUTOINCREMENT,
      $productName TEXT NOT NULL,
      $productPrice REAL NOT NULL,
      $productDescription TEXT,
      $productCategory TEXT,
      $productIsAvailable INTEGER NOT NULL DEFAULT 1,
      $productCreatedAt TEXT NOT NULL,
      $productUpdatedAt TEXT
    )
  ''';

  static const String createDiningTablesTable = '''
    CREATE TABLE $diningTablesTable (
      $tableId INTEGER PRIMARY KEY AUTOINCREMENT,
      $tableName TEXT NOT NULL UNIQUE,
      $tableCapacity INTEGER NOT NULL,
      $tableStatus TEXT NOT NULL DEFAULT 'available',
      $tableLocation TEXT,
      $tableCreatedAt TEXT NOT NULL,
      $tableUpdatedAt TEXT
    )
  ''';

  static const String createOrdersTable = '''
    CREATE TABLE $ordersTable (
      $orderId INTEGER PRIMARY KEY AUTOINCREMENT,
      $orderTableId INTEGER NOT NULL,
      $orderTableName TEXT NOT NULL,
      $orderTotalAmount REAL NOT NULL,
      $orderStatus TEXT NOT NULL DEFAULT 'pending',
      $orderCustomerName TEXT,
      $orderSpecialInstructions TEXT,
      $orderCreatedAt TEXT NOT NULL,
      $orderUpdatedAt TEXT,
      $orderServedAt TEXT,
      FOREIGN KEY ($orderTableId) REFERENCES $diningTablesTable ($tableId)
    )
  ''';

  static const String createOrderItemsTable = '''
    CREATE TABLE $orderItemsTable (
      $orderItemId INTEGER PRIMARY KEY AUTOINCREMENT,
      $orderItemOrderId INTEGER NOT NULL,
      $orderItemProductId INTEGER NOT NULL,
      $orderItemProductName TEXT NOT NULL,
      $orderItemUnitPrice REAL NOT NULL,
      $orderItemQuantity INTEGER NOT NULL,
      $orderItemTotalPrice REAL NOT NULL,
      $orderItemSpecialInstructions TEXT,
      $orderItemCreatedAt TEXT NOT NULL,
      FOREIGN KEY ($orderItemOrderId) REFERENCES $ordersTable ($orderId) ON DELETE CASCADE,
      FOREIGN KEY ($orderItemProductId) REFERENCES $productsTable ($productId)
    )
  ''';

  // Indexes for better performance
  static const String createIndexes = '''
    CREATE INDEX idx_products_category ON $productsTable ($productCategory);
    CREATE INDEX idx_products_available ON $productsTable ($productIsAvailable);
    CREATE INDEX idx_tables_status ON $diningTablesTable ($tableStatus);
    CREATE INDEX idx_orders_table_id ON $ordersTable ($orderTableId);
    CREATE INDEX idx_orders_status ON $ordersTable ($orderStatus);
    CREATE INDEX idx_orders_created_at ON $ordersTable ($orderCreatedAt);
    CREATE INDEX idx_order_items_order_id ON $orderItemsTable ($orderItemOrderId);
    CREATE INDEX idx_order_items_product_id ON $orderItemsTable ($orderItemProductId);
  ''';

  // Sample data for testing
  static const List<Map<String, dynamic>> sampleProducts = [
    {
      'name': 'Margherita Pizza',
      'price': 12.99,
      'description': 'Classic pizza with tomato sauce, mozzarella, and basil',
      'category': 'Pizza',
      'is_available': 1,
      'created_at': '2024-01-01T10:00:00Z',
    },
    {
      'name': 'Caesar Salad',
      'price': 8.99,
      'description': 'Fresh romaine lettuce with Caesar dressing and croutons',
      'category': 'Salad',
      'is_available': 1,
      'created_at': '2024-01-01T10:00:00Z',
    },
    {
      'name': 'Grilled Chicken',
      'price': 15.99,
      'description': 'Juicy grilled chicken breast with herbs and spices',
      'category': 'Main Course',
      'is_available': 1,
      'created_at': '2024-01-01T10:00:00Z',
    },
    {
      'name': 'Chocolate Cake',
      'price': 6.99,
      'description': 'Rich chocolate cake with cream frosting',
      'category': 'Dessert',
      'is_available': 1,
      'created_at': '2024-01-01T10:00:00Z',
    },
    {
      'name': 'Cappuccino',
      'price': 4.99,
      'description': 'Espresso with steamed milk and foam',
      'category': 'Beverage',
      'is_available': 1,
      'created_at': '2024-01-01T10:00:00Z',
    },
  ];

  static const List<Map<String, dynamic>> sampleTables = [
    {
      'name': 'Table 1',
      'capacity': 4,
      'status': 'available',
      'location': 'Window Side',
      'created_at': '2024-01-01T10:00:00Z',
    },
    {
      'name': 'Table 2',
      'capacity': 2,
      'status': 'available',
      'location': 'Center',
      'created_at': '2024-01-01T10:00:00Z',
    },
    {
      'name': 'Table 3',
      'capacity': 6,
      'status': 'available',
      'location': 'Private Room',
      'created_at': '2024-01-01T10:00:00Z',
    },
    {
      'name': 'Table 4',
      'capacity': 4,
      'status': 'available',
      'location': 'Patio',
      'created_at': '2024-01-01T10:00:00Z',
    },
    {
      'name': 'Table 5',
      'capacity': 8,
      'status': 'available',
      'location': 'Main Hall',
      'created_at': '2024-01-01T10:00:00Z',
    },
  ];
}