import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/server_connection_service.dart';
import '../services/network_discovery_service.dart';
import '../models/discovered_server.dart';
import 'server_discovery_screen.dart';

class WaiterHomeScreen extends StatefulWidget {
  const WaiterHomeScreen({super.key});

  @override
  State<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends State<WaiterHomeScreen> {
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
              return IconButton(
                icon: Icon(
                  connectionService.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: connectionService.isConnected ? Colors.green : Colors.red,
                ),
                onPressed: () => _showConnectionDialog(context, connectionService),
              );
            },
          ),
        ],
      ),
      body: Consumer<ServerConnectionService>(
        builder: (context, connectionService, child) {
          if (!connectionService.isConnected) {
            return _buildConnectionScreen(connectionService);
          }
          return _buildMainScreen(connectionService);
        },
      ),
    );
  }

  Widget _buildConnectionScreen(ServerConnectionService connectionService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Not Connected to Server',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect to a cashier terminal to start taking orders',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (connectionService.status == ConnectionStatus.connecting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Connecting...'),
            ] else if (connectionService.status == ConnectionStatus.error) ...[
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Connection Error',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                connectionService.errorMessage ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showServerDiscovery(context),
                child: const Text('Try Again'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _showServerDiscovery(context),
                icon: const Icon(Icons.search),
                label: const Text('Find Servers'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showManualConnection(context),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Manual Connection'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainScreen(ServerConnectionService connectionService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConnectionStatusCard(connectionService),
          const SizedBox(height: 16),
          _buildServerInfoCard(connectionService),
          const SizedBox(height: 16),
          _buildQuickActionsCard(connectionService),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(ServerConnectionService connectionService) {
    final server = connectionService.connectedServer;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wifi,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Connected to Server',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (server != null) ...[
              Text(
                server.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                server.displayAddress,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoCard(ServerConnectionService connectionService) {
    final server = connectionService.connectedServer;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (server != null) ...[
              _buildInfoRow('Server Name', server.serverInfo.name),
              _buildInfoRow('IP Address', server.serverInfo.ipAddress),
              _buildInfoRow('HTTP Port', server.serverInfo.httpPort.toString()),
              _buildInfoRow('WebSocket Port', server.serverInfo.webSocketPort.toString()),
              _buildInfoRow('Version', server.serverInfo.version),
              _buildInfoRow('Discovered', _formatDateTime(server.discoveredAt)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ServerConnectionService connectionService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('View Menu'),
                    onPressed: () => _showComingSoon(context, 'Menu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.table_restaurant),
                    label: const Text('Tables'),
                    onPressed: () => _showComingSoon(context, 'Tables'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('New Order'),
                    onPressed: () => _showComingSoon(context, 'New Order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Orders'),
                    onPressed: () => _showComingSoon(context, 'Orders'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showServerDiscovery(BuildContext context) async {
    final result = await Navigator.push<DiscoveredServer>(
      context,
      MaterialPageRoute(
        builder: (context) => const ServerDiscoveryScreen(),
      ),
    );

    if (result != null && mounted) {
      final connectionService = context.read<ServerConnectionService>();
      final success = await connectionService.connectToServer(result);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to server successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showManualConnection(BuildContext context) {
    final ipController = TextEditingController();
    final httpPortController = TextEditingController(text: '8080');
    final webSocketPortController = TextEditingController(text: '8081');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: httpPortController,
                    decoration: const InputDecoration(
                      labelText: 'HTTP Port',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: webSocketPortController,
                    decoration: const InputDecoration(
                      labelText: 'WebSocket Port',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (ipController.text.isNotEmpty) {
                Navigator.of(context).pop();
                
                final discoveryService = context.read<NetworkDiscoveryService>();
                final success = await discoveryService.addServerManually(
                  ipController.text.trim(),
                  httpPort: int.tryParse(httpPortController.text) ?? 8080,
                  webSocketPort: int.tryParse(webSocketPortController.text) ?? 8081,
                );
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showConnectionDialog(BuildContext context, ServerConnectionService connectionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${connectionService.status.name}'),
            if (connectionService.connectedServer != null)
              Text('Server: ${connectionService.connectedServer!.displayAddress}'),
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
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature - Coming Soon'),
        content: Text('The $feature feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}