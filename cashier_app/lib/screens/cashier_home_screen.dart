import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/server_manager.dart';

class CashierHomeScreen extends StatefulWidget {
  const CashierHomeScreen({super.key});

  @override
  State<CashierHomeScreen> createState() => _CashierHomeScreenState();
}

class _CashierHomeScreenState extends State<CashierHomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // Start server automatically when the app launches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startServer();
    });
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
              return IconButton(
                icon: Icon(
                  serverManager.isRunning ? Icons.cloud_done : Icons.cloud_off,
                  color: serverManager.isRunning ? Colors.green : Colors.red,
                ),
                onPressed: () => _showServerDialog(context, serverManager),
              );
            },
          ),
        ],
      ),
      body: Consumer<ServerManager>(
        builder: (context, serverManager, child) {
          print('UI rebuilding with server status: ${serverManager.status.name}');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServerStatusCard(serverManager),
                const SizedBox(height: 16),
                _buildServerInfoCard(serverManager),
                const SizedBox(height: 16),
                _buildClientInfoCard(serverManager),
                const SizedBox(height: 16),
                _buildQuickActionsCard(serverManager),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServerStatusCard(ServerManager serverManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  serverManager.isRunning ? Icons.check_circle : Icons.error,
                  color: serverManager.isRunning ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Server Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              serverManager.status.name.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _getStatusColor(serverManager.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (serverManager.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${serverManager.errorMessage}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoCard(ServerManager serverManager) {
    final serverInfo = serverManager.serverInfo;
    
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
            if (serverInfo != null) ...[
              _buildInfoRow('Name', serverInfo.name),
              _buildInfoRow('Version', serverInfo.version),
              _buildInfoRow('IP Address', serverInfo.ipAddress),
              _buildInfoRow('HTTP Port', serverInfo.httpPort.toString()),
              _buildInfoRow('WebSocket Port', serverInfo.webSocketPort.toString()),
              _buildInfoRow('Started', _formatDateTime(serverInfo.startTime)),
            ] else ...[
              const Text('Server not running'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoCard(ServerManager serverManager) {
    final clientCount = serverManager.connectedClients;
    final clientsInfo = serverManager.getClientsInfo();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices),
                const SizedBox(width: 8),
                Text(
                  'Connected Clients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Chip(
                  label: Text(clientCount.toString()),
                  backgroundColor: clientCount > 0 ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (clientsInfo.isNotEmpty) ...[
              for (final entry in clientsInfo.entries) ...[
                _buildClientRow(entry.key, entry.value),
                const SizedBox(height: 4),
              ],
            ] else ...[
              const Text('No clients connected'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ServerManager serverManager) {
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
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart Server'),
                    onPressed: serverManager.isRunning 
                        ? () => _restartServer(serverManager)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.broadcast_on_personal),
                    label: const Text('Broadcast Message'),
                    onPressed: serverManager.isRunning
                        ? () => _showBroadcastDialog(serverManager)
                        : null,
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
            width: 100,
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

  Widget _buildClientRow(String clientId, Map<String, dynamic> info) {
    final connectedAt = info['connectedAt'] as DateTime?;
    final remoteAddress = info['remoteAddress'] as String?;
    
    return Row(
      children: [
        const Icon(Icons.phone_android, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientId,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (remoteAddress != null)
                Text(
                  remoteAddress,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (connectedAt != null)
          Text(
            _formatDateTime(connectedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Color _getStatusColor(ServerStatus status) {
    switch (status) {
      case ServerStatus.running:
        return Colors.green;
      case ServerStatus.starting:
        return Colors.orange;
      case ServerStatus.stopping:
        return Colors.orange;
      case ServerStatus.stopped:
        return Colors.grey;
      case ServerStatus.error:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _restartServer(ServerManager serverManager) async {
    try {
      await serverManager.restart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server restarted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restart server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showServerDialog(BuildContext context, ServerManager serverManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Control'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${serverManager.status.name}'),
            Text('Connected Clients: ${serverManager.connectedClients}'),
            if (serverManager.errorMessage != null)
              Text('Error: ${serverManager.errorMessage}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (serverManager.isRunning)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                serverManager.stop();
              },
              child: const Text('Stop Server'),
            ),
          if (!serverManager.isRunning)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                serverManager.start();
              },
              child: const Text('Start Server'),
            ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(ServerManager serverManager) {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast Message'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            hintText: 'Enter message to broadcast...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                serverManager.broadcastSystemMessage(
                  message: messageController.text,
                  level: 'info',
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message broadcasted to all clients'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
  }
}