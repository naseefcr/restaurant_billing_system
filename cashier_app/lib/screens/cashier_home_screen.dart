import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/dining_table.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/server_manager.dart';

class CashierHomeScreen extends StatefulWidget {
  const CashierHomeScreen({super.key});

  @override
  State<CashierHomeScreen> createState() => _CashierHomeScreenState();
}

class _CashierHomeScreenState extends State<CashierHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<DiningTable> _tables = [];
  List<Product> _products = [];
  List<Order> _orders = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();

    // Start server automatically when the app launches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startServer();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startServer() async {
    final serverManager = context.read<ServerManager>();

    if (!serverManager.isRunning) {
      try {
        print('Starting server from UI...');
        await serverManager.start();
        print('Server start completed from UI');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server started successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error starting server from UI: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start server: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadData() async {
    final tables = await _dbHelper.getAllDiningTables();
    final products = await _dbHelper.getAllProducts();
    final orders = await _dbHelper.getAllOrders();

    setState(() {
      _tables = tables;
      _products = products;
      _orders = orders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Restaurant Billing System'),
            Text(
              'Cashier App',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          Consumer<ServerManager>(
            builder: (context, serverManager, child) {
              return Row(
                children: [
                  Icon(
                    serverManager.isRunning ? Icons.wifi : Icons.wifi_off,
                    color: serverManager.isRunning ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      serverManager.isRunning ? Icons.stop : Icons.play_arrow,
                      color:
                          serverManager.isRunning ? Colors.red : Colors.green,
                    ),
                    onPressed: () => _toggleServer(serverManager),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.table_restaurant), text: 'Tables'),
            Tab(icon: Icon(Icons.inventory), text: 'Products'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
            Tab(icon: Icon(Icons.settings), text: 'Server'),
          ],
        ),
      ),
      body: Consumer<ServerManager>(
        builder: (context, serverManager, child) {
          if (!serverManager.isRunning) {
            return _buildStartServerView(serverManager);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTablesView(),
              _buildProductsView(),
              _buildOrdersView(),
              _buildServerView(serverManager),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStartServerView(ServerManager serverManager) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Restaurant Billing System',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Start the server to begin accepting connections from waiter apps',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _toggleServer(serverManager),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Server'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Restaurant Tables',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            ],
          ),
          const SizedBox(height: 16),
          _buildTableLegend(),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _tables.length,
              itemBuilder: (context, index) {
                return _buildTableCard(_tables[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableLegend() {
    return Row(
      children: [
        _buildLegendItem(Colors.green[100]!, Colors.green, 'Free'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.red[100]!, Colors.red, 'Occupied'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.yellow[100]!, Colors.orange, 'Completed'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.grey[200]!, Colors.grey, 'Cleaning'),
      ],
    );
  }

  Widget _buildLegendItem(Color bgColor, Color borderColor, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTableCard(DiningTable table) {
    Color backgroundColor;
    Color borderColor;
    IconData icon;

    switch (table.status) {
      case TableStatus.available:
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case TableStatus.occupied:
        backgroundColor = Colors.red[100]!;
        borderColor = Colors.red;
        icon = Icons.people;
        break;
      case TableStatus.reserved:
        backgroundColor = Colors.yellow[100]!;
        borderColor = Colors.orange;
        icon = Icons.schedule;
        break;
      case TableStatus.cleaning:
        backgroundColor = Colors.grey[200]!;
        borderColor = Colors.grey;
        icon = Icons.cleaning_services;
        break;
      case TableStatus.maintenance:
        backgroundColor = Colors.purple[100]!;
        borderColor = Colors.purple;
        icon = Icons.build;
        break;
    }

    final tableOrders =
        _orders
            .where(
              (order) =>
                  order.tableId == table.id &&
                  order.status != OrderStatus.completed,
            )
            .toList();

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showTableDetails(table),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon(icon, color: borderColor, size: 32),
                // const SizedBox(height: 8),
                Text(
                  table.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
                Text(
                  '${table.capacity} seats',
                  style: TextStyle(fontSize: 12, color: borderColor),
                ),
                if (tableOrders.isNotEmpty)
                  Text(
                    '${tableOrders.length} order(s)',
                    style: TextStyle(fontSize: 10, color: borderColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Menu Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddProductDialog(),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.isAvailable ? Colors.green : Colors.red,
          child: const Icon(Icons.restaurant_menu, color: Colors.white),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(product.description ?? 'No description'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              product.isAvailable ? 'Available' : 'Unavailable',
              style: TextStyle(
                fontSize: 12,
                color: product.isAvailable ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        onTap: () => _showEditProductDialog(product),
      ),
    );
  }

  Widget _buildOrdersView() {
    final activeOrders =
        _orders
            .where((order) => order.status != OrderStatus.completed)
            .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Active Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(activeOrders[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final table = _tables.firstWhere(
      (t) => t.id == order.tableId,
      orElse:
          () => DiningTable(
            name: 'Unknown',
            capacity: 0,
            status: TableStatus.available,
          ),
    );

    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case OrderStatus.confirmed:
        statusColor = Colors.blue;
        statusIcon = Icons.check;
        break;
      case OrderStatus.preparing:
        statusColor = Colors.purple;
        statusIcon = Icons.restaurant;
        break;
      case OrderStatus.ready:
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      case OrderStatus.served:
        statusColor = Colors.teal;
        statusIcon = Icons.room_service;
        break;
      case OrderStatus.completed:
        statusColor = Colors.grey;
        statusIcon = Icons.receipt;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(statusIcon, color: Colors.white),
        ),
        title: Text('Order #${order.id} - ${table.name}'),
        subtitle: Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              order.status.toString().split('.').last.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Text(
              '${DateTime.now().difference(order.createdAt).inMinutes}m ago',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showOrderDetails(order),
      ),
    );
  }

  Widget _buildServerView(ServerManager serverManager) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServerStatusCard(serverManager),
          const SizedBox(height: 16),
          _buildServerInfoCard(serverManager),
          const SizedBox(height: 16),
          _buildConnectionInfo(serverManager),
        ],
      ),
    );
  }

  Widget _buildServerStatusCard(ServerManager serverManager) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (serverManager.status) {
      case ServerStatus.stopped:
        statusColor = Colors.grey;
        statusText = 'Server Stopped';
        statusIcon = Icons.stop_circle;
        break;
      case ServerStatus.starting:
        statusColor = Colors.orange;
        statusText = 'Server Starting...';
        statusIcon = Icons.play_circle;
        break;
      case ServerStatus.running:
        statusColor = Colors.green;
        statusText = 'Server Running';
        statusIcon = Icons.check_circle;
        break;
      case ServerStatus.error:
        statusColor = Colors.red;
        statusText = 'Server Error';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (serverManager.errorMessage != null)
                  Text(
                    serverManager.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoCard(ServerManager serverManager) {
    final serverInfo = serverManager.serverInfo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (serverInfo != null) ...[
              Text('Name: ${serverInfo.name}'),
              Text('Version: ${serverInfo.version}'),
              Text('IP Address: ${serverInfo.ipAddress}'),
              Text('HTTP Port: ${serverInfo.httpPort}'),
              Text('WebSocket Port: ${serverInfo.webSocketPort}'),
              Text('Started: ${_formatDateTime(serverInfo.startTime)}'),
            ] else ...[
              const Text('Server not running'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInfo(ServerManager serverManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connected Clients',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Active Connections: ${serverManager.connectedClients}'),
            const SizedBox(height: 8),
            const Text('Services Status:'),
            Text('• HTTP Server: ✓ Running'),
            Text('• WebSocket Server: ✓ Running'),
            Text('• UDP Discovery: ✓ Broadcasting'),
            Text('• Real-time Sync: ✓ Active'),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showTableDetails(DiningTable table) {
    final tableOrders =
        _orders
            .where(
              (order) =>
                  order.tableId == table.id &&
                  order.status != OrderStatus.completed,
            )
            .toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${table.name} Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Capacity: ${table.capacity} seats'),
                Text('Status: ${table.status.toString().split('.').last}'),
                const SizedBox(height: 16),
                Text('Active Orders (${tableOrders.length}):'),
                ...tableOrders.map(
                  (order) => ListTile(
                    dense: true,
                    title: Text('Order #${order.id}'),
                    subtitle: Text('₹${order.totalAmount.toStringAsFixed(2)}'),
                    trailing: Text(order.status.toString().split('.').last),
                    onTap: () {
                      Navigator.pop(context);
                      _showOrderDetails(order);
                    },
                  ),
                ),
                if (tableOrders.length > 1)
                  const Text(
                    'Tap an order to view details',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showChangeTableStatusDialog(table);
                },
                child: const Text('Change Status'),
              ),
            ],
          ),
    );
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Order #${order.id}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table: ${_tables.firstWhere((t) => t.id == order.tableId).name}',
                ),
                Text('Status: ${order.status.toString().split('.').last}'),
                Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
                Text('Created: ${order.createdAt.toString().substring(0, 16)}'),
                const SizedBox(height: 16),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '(Order items will be loaded from database)',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (order.status != OrderStatus.completed)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showBillDialog(order);
                  },
                  child: const Text('Bill Order'),
                ),
            ],
          ),
    );
  }

  void _showChangeTableStatusDialog(DiningTable table) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Change ${table.name} Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  TableStatus.values
                      .map(
                        (status) => ListTile(
                          title: Text(status.toString().split('.').last),
                          leading: Radio<TableStatus>(
                            value: status,
                            groupValue: table.status,
                            onChanged: (value) {
                              Navigator.pop(context);
                              _updateTableStatus(table, value!);
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showBillDialog(Order order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Bill Order #${order.id}'),
            content: Text(
              'Generate bill for ₹${order.totalAmount.toStringAsFixed(2)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _generateBill(order);
                },
                child: const Text('Generate Bill'),
              ),
            ],
          ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Product'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    Navigator.pop(context);
                    _addProduct(
                      nameController.text,
                      double.parse(priceController.text),
                      descriptionController.text,
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final descriptionController = TextEditingController(
      text: product.description ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Product'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateProduct(
                    product,
                    nameController.text,
                    double.parse(priceController.text),
                    descriptionController.text,
                  );
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateTableStatus(
    DiningTable table,
    TableStatus newStatus,
  ) async {
    try {
      final updatedTable = table.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await _dbHelper.updateDiningTable(updatedTable);
      
      // Broadcast table status update to connected clients
      final serverManager = context.read<ServerManager>();
      serverManager.broadcastTableStatusUpdate(
        tableId: table.id!,
        tableName: table.name,
        status: newStatus.name,
      );
      
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${table.name} status updated to ${newStatus.toString().split('.').last}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating table status: $e')),
        );
      }
    }
  }

  Future<void> _generateBill(Order order) async {
    try {
      final updatedOrder = order.copyWith(
        status: OrderStatus.completed,
        updatedAt: DateTime.now(),
      );
      await _dbHelper.updateOrder(updatedOrder);
      
      // Broadcast order update to connected clients
      final serverManager = context.read<ServerManager>();
      serverManager.broadcastOrderUpdate(
        orderData: updatedOrder.toJson(),
      );

      // Update table status to available if this was the last order
      final table = _tables.firstWhere((t) => t.id == order.tableId);
      final remainingOrders =
          _orders
              .where(
                (o) =>
                    o.tableId == table.id &&
                    o.status != OrderStatus.completed &&
                    o.id != order.id,
              )
              .toList();

      if (remainingOrders.isEmpty && table.status == TableStatus.occupied) {
        await _updateTableStatus(table, TableStatus.available);
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating bill: $e')));
      }
    }
  }

  Future<void> _addProduct(
    String name,
    double price,
    String description,
  ) async {
    try {
      final product = Product(
        name: name,
        price: price,
        description: description.isEmpty ? null : description,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbHelper.insertProduct(product);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding product: $e')));
      }
    }
  }

  Future<void> _updateProduct(
    Product product,
    String name,
    double price,
    String description,
  ) async {
    try {
      final updatedProduct = product.copyWith(
        name: name,
        price: price,
        description: description.isEmpty ? null : description,
        updatedAt: DateTime.now(),
      );
      await _dbHelper.updateProduct(updatedProduct);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating product: $e')));
      }
    }
  }

  void _toggleServer(ServerManager serverManager) {
    if (serverManager.isRunning) {
      serverManager.stop();
    } else {
      serverManager.start();
    }
  }
}
