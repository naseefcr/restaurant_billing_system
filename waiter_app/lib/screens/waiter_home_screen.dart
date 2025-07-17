import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dining_table.dart';
import '../models/discovered_server.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/product.dart';
import '../services/network_discovery_service.dart';
import '../services/realtime_data_service.dart';
import '../services/server_connection_service.dart';
import 'server_discovery_screen.dart';

class WaiterHomeScreen extends StatefulWidget {
  const WaiterHomeScreen({super.key});

  @override
  State<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends State<WaiterHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<DiningTable> _tables = [];
  List<Product> _products = [];
  List<Order> _orders = [];
  final Map<int, List<OrderItem>> _currentOrderItems = {};
  int? _selectedTableId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Start network discovery automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNetworkDiscovery();
      _setupRealtimeListeners();
    });
  }

  void _setupRealtimeListeners() {
    // Listen for real-time order updates
    final realtimeService = context.read<RealTimeDataService>();
    
    realtimeService.orderUpdates.listen((order) {
      setState(() {
        // Update the order in the local list
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = order;
        } else {
          _orders.add(order);
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startNetworkDiscovery() async {
    final discoveryService = NetworkDiscoveryService();
    try {
      await discoveryService.startDiscovery();
    } catch (e) {
      print('Error starting network discovery: $e');
    }
  }

  Widget _buildConnectionHealthIndicator() {
    return Consumer<RealTimeDataService>(
      builder: (context, realtimeService, child) {
        final connectionService = context.watch<ServerConnectionService>();
        final isConnected = connectionService.isConnected;
        final isHealthy = realtimeService.isConnectionHealthy;
        
        Color iconColor;
        IconData iconData;
        String tooltip;
        
        if (!isConnected) {
          iconColor = Colors.red;
          iconData = Icons.wifi_off;
          tooltip = 'Disconnected';
        } else if (!isHealthy) {
          iconColor = Colors.orange;
          iconData = Icons.warning;
          tooltip = 'Connection may be stale';
        } else {
          iconColor = Colors.green;
          iconData = Icons.wifi;
          tooltip = 'Connected and healthy';
        }
        
        return Tooltip(
          message: tooltip,
          child: Icon(
            iconData,
            color: iconColor,
          ),
        );
      },
    );
  }

  void _refreshConnection() {
    final realtimeService = context.read<RealTimeDataService>();
    realtimeService.refreshConnection();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing connection...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _loadRealtimeData() {
    final realtimeService = context.read<RealTimeDataService>();
    setState(() {
      _tables = realtimeService.tablesCache.values.toList();
      _products = realtimeService.productsCache.values.toList();
      _orders = realtimeService.ordersCache.values.toList();
    });
  }

  Future<void> _refreshOrderData() async {
    try {
      final connectionService = context.read<ServerConnectionService>();
      final realtimeService = context.read<RealTimeDataService>();
      
      // Fetch fresh order data from server
      final ordersResponse = await connectionService.getOrders();
      
      if (ordersResponse['success'] == true) {
        final orders = (ordersResponse['data'] as List)
            .map((item) => Order.fromJson(item))
            .toList();
        
        // Update cache with fresh data
        realtimeService.updateOrdersCache(orders);
        
        // Update local state
        setState(() {
          _orders = orders;
        });
      }
    } catch (e) {
      print('Error refreshing order data: $e');
    }
  }

  Future<void> _fetchInitialData() async {
    try {
      final connectionService = context.read<ServerConnectionService>();
      final realtimeService = context.read<RealTimeDataService>();

      // Fetch initial data from server
      final tablesResponse = await connectionService.getTables();
      final productsResponse = await connectionService.getProducts();
      final ordersResponse = await connectionService.getOrders();

      // Update cache with fetched data
      if (tablesResponse['success'] == true) {
        final tables =
            (tablesResponse['data'] as List)
                .map((item) => DiningTable.fromJson(item))
                .toList();
        realtimeService.updateTablesCache(tables);
      }

      if (productsResponse['success'] == true) {
        final products =
            (productsResponse['data'] as List)
                .map((item) => Product.fromJson(item))
                .toList();
        realtimeService.updateProductsCache(products);
      }

      if (ordersResponse['success'] == true) {
        final orders =
            (ordersResponse['data'] as List)
                .map((item) => Order.fromJson(item))
                .toList();
        realtimeService.updateOrdersCache(orders);
      }

      // Load data into local state
      _loadRealtimeData();
    } catch (e) {
      print('Error fetching initial data: $e');
    }
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
              'Waiter App',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          Consumer<ServerConnectionService>(
            builder: (context, connectionService, child) {
              return Row(
                children: [
                  _buildConnectionHealthIndicator(),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _refreshConnection,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Connection',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed:
                        () => _showConnectionDialog(context, connectionService),
                  ),
                ],
              );
            },
          ),
        ],
        bottom:
            context.watch<ServerConnectionService>().isConnected
                ? TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.table_restaurant), text: 'Tables'),
                    Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
                    Tab(icon: Icon(Icons.receipt), text: 'Orders'),
                  ],
                )
                : null,
      ),
      body: Consumer<ServerConnectionService>(
        builder: (context, connectionService, child) {
          if (!connectionService.isConnected) {
            return _buildConnectionScreen(connectionService);
          }

          return Consumer<RealTimeDataService>(
            builder: (context, realtimeService, child) {
              // Update local data when real-time data changes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _loadRealtimeData();
                }
              });

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTablesView(),
                  _buildMenuView(),
                  _buildOrdersView(),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<ServerConnectionService>(
        builder: (context, connectionService, child) {
          if (!connectionService.isConnected ||
              _selectedTableId == null ||
              _currentOrderItems.isEmpty) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: _submitOrder,
            icon: const Icon(Icons.send),
            label: Text(
              'Submit Order (${_currentOrderItems.values.expand((items) => items).length} items)',
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionScreen(ServerConnectionService connectionService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            connectionService.status == ConnectionStatus.connecting
                ? Icons.wifi_find
                : Icons.wifi_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            _getStatusMessage(connectionService.status),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (connectionService.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              connectionService.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _navigateToDiscovery(context),
                icon: const Icon(Icons.search),
                label: const Text('Find Server'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed:
                    () =>
                        _showManualConnectionDialog(context, connectionService),
                icon: const Icon(Icons.edit),
                label: const Text('Manual IP'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
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
              if (_selectedTableId != null)
                Chip(
                  label: Text(
                    'Table ${_tables.firstWhere((t) => t.id == _selectedTableId).name}',
                  ),
                  backgroundColor: Colors.blue[100],
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted:
                      () => setState(() {
                        _selectedTableId = null;
                        _currentOrderItems.clear();
                      }),
                ),
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
        const SizedBox(width: 12),
        _buildLegendItem(Colors.red[100]!, Colors.red, 'Occupied'),
        const SizedBox(width: 12),
        _buildLegendItem(Colors.yellow[100]!, Colors.orange, 'Reserved'),
        const SizedBox(width: 12),
        _buildLegendItem(Colors.grey[200]!, Colors.grey, 'Cleaning'),
      ],
    );
  }

  Widget _buildLegendItem(Color bgColor, Color borderColor, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildTableCard(DiningTable table) {
    Color backgroundColor;
    Color borderColor;
    IconData icon;
    bool isSelectable = false;

    switch (table.status) {
      case TableStatus.available:
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green;
        icon = Icons.check_circle;
        isSelectable = true;
        break;
      case TableStatus.occupied:
        backgroundColor = Colors.red[100]!;
        borderColor = Colors.red;
        icon = Icons.people;
        isSelectable = true;
        break;
      case TableStatus.reserved:
        backgroundColor = Colors.yellow[100]!;
        borderColor = Colors.orange;
        icon = Icons.schedule;
        isSelectable = true;
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
    final isSelected = _selectedTableId == table.id;

    return Card(
      elevation: isSelected ? 8 : 4,
      child: InkWell(
        onTap: isSelectable ? () => _selectTable(table) : null,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: isSelected ? Colors.blue : borderColor,
              width: isSelected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon(icon, color: isSelected ? Colors.blue : borderColor, size: 24),
                // const SizedBox(height: 4),
                Text(
                  table.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue : borderColor,
                  ),
                ),
                Text(
                  '${table.capacity} seats',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.blue : borderColor,
                  ),
                ),
                if (tableOrders.isNotEmpty)
                  Text(
                    '${tableOrders.length} order(s)',
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected ? Colors.blue : borderColor,
                    ),
                  ),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.blue, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuView() {
    if (_selectedTableId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a table first',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Choose a table from the Tables tab to start taking orders',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
              Text(
                'Table: ${_tables.firstWhere((t) => t.id == _selectedTableId).name}',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
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
    final currentQuantity =
        _currentOrderItems[_selectedTableId!]
            ?.where((item) => item.productId == product.id)
            .fold(0, (sum, item) => sum + item.quantity) ??
        0;

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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.description != null) Text(product.description!),
            Text(
              '₹${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing:
            product.isAvailable
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentQuantity > 0) ...[
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => _decrementProduct(product),
                      ),
                      Text(
                        currentQuantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _incrementProduct(product),
                    ),
                  ],
                )
                : const Text(
                  'Unavailable',
                  style: TextStyle(color: Colors.red),
                ),
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
          const Text(
            'Active Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_currentOrderItems.isNotEmpty) ...[
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Order (Draft)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._currentOrderItems.entries.expand(
                      (entry) => entry.value.map((item) {
                        final product = _products.firstWhere(
                          (p) => p.id == item.productId,
                        );
                        return ListTile(
                          dense: true,
                          title: Text('${product.name} x${item.quantity}'),
                          trailing: Text(
                            '₹${(product.price * item.quantity).toStringAsFixed(2)}',
                          ),
                        );
                      }),
                    ),
                    const Divider(),
                    Text(
                      'Total: ₹${_calculateCurrentOrderTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Text(
              '${DateTime.now().difference(order.createdAt).inMinutes}m ago',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showOrderDetails(order),
      ),
    );
  }

  void _selectTable(DiningTable table) {
    final tableOrders =
        _orders
            .where(
              (order) =>
                  order.tableId == table.id &&
                  order.status != OrderStatus.completed,
            )
            .toList();

    if (tableOrders.length > 1) {
      _showOrderSelectionDialog(table, tableOrders);
    } else {
      setState(() {
        _selectedTableId = table.id;
        _currentOrderItems.clear();
      });

      // Switch to menu tab
      _tabController.animateTo(1);
    }
  }

  void _showOrderSelectionDialog(DiningTable table, List<Order> orders) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${table.name} - Select Action'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create New Order'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedTableId = table.id;
                      _currentOrderItems.clear();
                    });
                    _tabController.animateTo(1);
                  },
                ),
                if (orders.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Existing Orders:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...orders.map(
                    (order) => ListTile(
                      leading: Icon(
                        Icons.receipt,
                        color: _getOrderStatusColor(order.status),
                      ),
                      title: Text('Order #${order.id}'),
                      subtitle: Text(
                        '₹${order.totalAmount.toStringAsFixed(2)} - ${order.status.toString().split('.').last}',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showOrderDetails(order);
                      },
                    ),
                  ),
                ],
              ],
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

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.served:
        return Colors.teal;
      case OrderStatus.completed:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  void _incrementProduct(Product product) {
    setState(() {
      if (_currentOrderItems[_selectedTableId!] == null) {
        _currentOrderItems[_selectedTableId!] = [];
      }

      final existingItemIndex = _currentOrderItems[_selectedTableId!]!
          .indexWhere((item) => item.productId == (product.id ?? 0));

      if (existingItemIndex >= 0) {
        final currentItem =
            _currentOrderItems[_selectedTableId!]![existingItemIndex];
        _currentOrderItems[_selectedTableId!]![existingItemIndex] = currentItem
            .copyWith(
              quantity: currentItem.quantity + 1,
              totalPrice: currentItem.unitPrice * (currentItem.quantity + 1),
            );
      } else {
        _currentOrderItems[_selectedTableId!]!.add(
          OrderItem(
            orderId: 0, // Temporary, will be set when order is created
            productId: product.id ?? 0,
            productName: product.name,
            quantity: 1,
            unitPrice: product.price,
            totalPrice: product.price,
            createdAt: DateTime.now(),
          ),
        );
      }
    });
  }

  void _decrementProduct(Product product) {
    setState(() {
      if (_currentOrderItems[_selectedTableId!] == null) return;

      final existingItemIndex = _currentOrderItems[_selectedTableId!]!
          .indexWhere((item) => item.productId == (product.id ?? 0));

      if (existingItemIndex >= 0) {
        final currentItem =
            _currentOrderItems[_selectedTableId!]![existingItemIndex];
        if (currentItem.quantity > 1) {
          _currentOrderItems[_selectedTableId!]![existingItemIndex] =
              currentItem.copyWith(
                quantity: currentItem.quantity - 1,
                totalPrice: currentItem.unitPrice * (currentItem.quantity - 1),
              );
        } else {
          _currentOrderItems[_selectedTableId!]!.removeAt(existingItemIndex);
        }
      }

      if (_currentOrderItems[_selectedTableId!]!.isEmpty) {
        _currentOrderItems.remove(_selectedTableId);
      }
    });
  }

  double _calculateCurrentOrderTotal() {
    return _currentOrderItems.values
        .expand((items) => items)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _submitOrder() async {
    if (_selectedTableId == null || _currentOrderItems.isEmpty) return;

    try {
      final connectionService = context.read<ServerConnectionService>();
      final selectedTable = _tables.firstWhere((t) => t.id == _selectedTableId);
      
      final orderData = {
        'tableId': _selectedTableId!,
        'tableName': selectedTable.name,
        'items':
            _currentOrderItems[_selectedTableId!]!
                .map(
                  (item) => {
                    'productId': item.productId,
                    'productName': item.productName,
                    'quantity': item.quantity,
                    'unitPrice': item.unitPrice,
                    'totalPrice': item.totalPrice,
                  },
                )
                .toList(),
        'totalAmount': _calculateCurrentOrderTotal(),
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await connectionService.createOrder(orderData);
      
      // Refresh order data after successful submission
      await _refreshOrderData();

      setState(() {
        _currentOrderItems.clear();
        _selectedTableId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Switch to orders tab
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  '(Order items will be loaded from server)',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showManualConnectionDialog(
    BuildContext context,
    ServerConnectionService connectionService,
  ) {
    final ipController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Manual Connection'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(
                    labelText: 'Server IP Address',
                    hintText: 'e.g. 192.168.1.4',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Enter the IP address of the cashier app'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (ipController.text.isNotEmpty) {
                    Navigator.pop(context);
                    final success = await connectionService.connectToServerByIp(
                      ipController.text,
                    );

                    if (success) {
                      // Initialize real-time data service after successful connection
                      // Wait a moment to ensure WebSocket connection is established
                      await Future.delayed(const Duration(milliseconds: 1000));
                      final realtimeService =
                          context.read<RealTimeDataService>();
                      realtimeService.initialize();

                      // Fetch initial data from server
                      _fetchInitialData();

                      // Show success message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connected to server successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      // Show error message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to connect to server: ${connectionService.errorMessage}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Connect'),
              ),
            ],
          ),
    );
  }

  String _getStatusMessage(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return 'Not Connected to Server\n\nPlease find and connect to the cashier app to begin taking orders.';
      case ConnectionStatus.connecting:
        return 'Connecting to Server...\n\nPlease wait while we establish connection.';
      case ConnectionStatus.error:
        return 'Connection Failed\n\nUnable to connect to the server. Please try again.';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...\n\nTrying to restore connection to server.';
      default:
        return 'Ready to Connect';
    }
  }

  void _navigateToDiscovery(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ServerDiscoveryScreen()),
    );

    if (result is DiscoveredServer) {
      // Connect to the selected server
      final connectionService = context.read<ServerConnectionService>();
      final success = await connectionService.connectToServer(result);

      if (success) {
        // Initialize real-time data service after successful connection
        // Wait a moment to ensure WebSocket connection is established
        await Future.delayed(const Duration(milliseconds: 1000));
        final realtimeService = context.read<RealTimeDataService>();
        realtimeService.initialize();

        // Fetch initial data from server
        _fetchInitialData();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected to server successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to connect to server: ${connectionService.errorMessage}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showConnectionDialog(
    BuildContext context,
    ServerConnectionService connectionService,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Connection Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${_getStatusText(connectionService.status)}'),
                if (connectionService.connectedServer != null)
                  Text(
                    'Server: ${connectionService.connectedServer!.serverInfo.ipAddress}',
                  ),
                if (connectionService.errorMessage != null)
                  Text('Error: ${connectionService.errorMessage}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (connectionService.isConnected)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    connectionService.disconnect();
                  },
                  child: const Text('Disconnect'),
                ),
              if (!connectionService.isConnected)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navigateToDiscovery(context);
                  },
                  child: const Text('Find Server'),
                ),
            ],
          ),
    );
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting';
    }
  }
}
