import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_discovery_service.dart';
import '../models/discovered_server.dart';

class ServerDiscoveryScreen extends StatefulWidget {
  const ServerDiscoveryScreen({super.key});

  @override
  State<ServerDiscoveryScreen> createState() => _ServerDiscoveryScreenState();
}

class _ServerDiscoveryScreenState extends State<ServerDiscoveryScreen> {
  final _manualIpController = TextEditingController();
  final _httpPortController = TextEditingController(text: '8080');
  final _webSocketPortController = TextEditingController(text: '8081');
  
  NetworkDiscoveryService? _discoveryService;
  bool _isAddingManually = false;

  @override
  void initState() {
    super.initState();
    _discoveryService = NetworkDiscoveryService();
    _startDiscovery();
  }

  @override
  void dispose() {
    _discoveryService?.stopDiscovery();
    _manualIpController.dispose();
    _httpPortController.dispose();
    _webSocketPortController.dispose();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    try {
      await _discoveryService?.startDiscovery();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start discovery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshDiscovery(NetworkDiscoveryService service) async {
    try {
      await service.refreshDiscovery();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discovery refreshed - scanning for servers...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing discovery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addServerManually() async {
    if (_manualIpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an IP address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAddingManually = true);

    try {
      final httpPort = int.tryParse(_httpPortController.text) ?? 8080;
      final webSocketPort = int.tryParse(_webSocketPortController.text) ?? 8081;

      final success = await _discoveryService?.addServerManually(
        _manualIpController.text.trim(),
        httpPort: httpPort,
        webSocketPort: webSocketPort,
      );

      if (success == true) {
        _manualIpController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to server'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAddingManually = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Discovery'),
        actions: [
          ChangeNotifierProvider.value(
            value: _discoveryService,
            child: Consumer<NetworkDiscoveryService>(
              builder: (context, service, child) {
                return IconButton(
                  icon: Icon(
                    service.isDiscovering ? Icons.stop : Icons.play_arrow,
                  ),
                  onPressed: service.isDiscovering
                      ? () => service.stopDiscovery()
                      : () => _startDiscovery(),
                );
              },
            ),
          ),
        ],
      ),
      body: ChangeNotifierProvider.value(
        value: _discoveryService,
        child: Consumer<NetworkDiscoveryService>(
          builder: (context, service, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDiscoveryStatusCard(service),
                  const SizedBox(height: 16),
                  _buildManualEntryCard(),
                  const SizedBox(height: 16),
                  _buildDiscoveredServersCard(service),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDiscoveryStatusCard(NetworkDiscoveryService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  service.isDiscovering ? Icons.radar : Icons.radar_outlined,
                  color: service.isDiscovering ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Discovery Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  service.isDiscovering ? 'Discovering...' : 'Stopped',
                  style: TextStyle(
                    color: service.isDiscovering ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _refreshDiscovery(service),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Discovery',
                    ),
                    Chip(
                      label: Text('${service.serverCount} servers'),
                      backgroundColor: service.serverCount > 0 ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Online: ${service.onlineServerCount}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle_outline),
                const SizedBox(width: 8),
                Text(
                  'Add Server Manually',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualIpController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.computer),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _httpPortController,
                    decoration: const InputDecoration(
                      labelText: 'HTTP Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _webSocketPortController,
                    decoration: const InputDecoration(
                      labelText: 'WebSocket Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAddingManually ? null : _addServerManually,
                icon: _isAddingManually
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isAddingManually ? 'Adding...' : 'Add Server'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredServersCard(NetworkDiscoveryService service) {
    final servers = service.discoveredServers;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns),
                const SizedBox(width: 8),
                Text(
                  'Discovered Servers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (servers.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No servers discovered yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Make sure the cashier app is running on the same network',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              for (final server in servers)
                _buildServerTile(server),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServerTile(DiscoveredServer server) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: server.isOnline ? Colors.green : Colors.grey,
          child: Icon(
            server.isManuallyAdded ? Icons.edit : Icons.wifi,
            color: Colors.white,
          ),
        ),
        title: Text(server.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(server.displayAddress),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  server.isOnline ? Icons.circle : Icons.circle_outlined,
                  size: 8,
                  color: server.isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  server.statusText,
                  style: TextStyle(
                    color: server.isOnline ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                if (server.isManuallyAdded)
                  const Icon(Icons.star, size: 12, color: Colors.amber),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.connect_without_contact),
              onPressed: () => _connectToServer(server),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeServer(server),
            ),
          ],
        ),
      ),
    );
  }

  void _connectToServer(DiscoveredServer server) {
    // Return the selected server to the previous screen
    Navigator.pop(context, server);
  }

  void _removeServer(DiscoveredServer server) {
    final serverId = '${server.serverInfo.ipAddress}:${server.serverInfo.httpPort}';
    _discoveryService?.removeServer(serverId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed server: ${server.displayName}'),
      ),
    );
  }
}