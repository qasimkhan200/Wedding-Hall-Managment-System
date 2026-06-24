import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backend_connectivity_service.dart';
import '../config/env_config.dart';

/// Debug screen to check backend connectivity and diagnose issues.
/// Access via: Navigator.push(context, MaterialPageRoute(builder: (_) => BackendDebugScreen()))
class BackendDebugScreen extends StatefulWidget {
  const BackendDebugScreen({super.key});

  @override
  State<BackendDebugScreen> createState() => _BackendDebugScreenState();
}

class _BackendDebugScreenState extends State<BackendDebugScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    setState(() => _isChecking = true);
    BackendConnectivityService.reset();
    await BackendConnectivityService.checkConnectivity();
    setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = BackendConnectivityService.isConnected;
    final errorMessage = BackendConnectivityService.errorMessage;
    final serverInfo = BackendConnectivityService.serverInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isChecking ? null : _checkConnectivity,
          ),
        ],
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Card
                Card(
                  color:
                      isConnected ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          isConnected ? Icons.check_circle : Icons.error,
                          size: 64,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isConnected
                              ? '✅ Backend is Accessible'
                              : '❌ Backend is Not Accessible',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: isConnected ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        if (!isConnected && errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Configuration Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuration',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Divider(),
                        _buildInfoRow(
                            'Backend URL', EnvConfig.storageBackendUrl),
                        _buildInfoRow(
                            'API Key',
                            EnvConfig.storageApiKey.isEmpty
                                ? 'Not set'
                                : '${EnvConfig.storageApiKey.substring(0, 4)}...'),
                      ],
                    ),
                  ),
                ),

                if (isConnected && serverInfo != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Server Information',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Divider(),
                          _buildInfoRow(
                              'Message', serverInfo['message'] ?? 'N/A'),
                          _buildInfoRow(
                              'Timestamp', serverInfo['timestamp'] ?? 'N/A'),
                          _buildInfoRow(
                              'Port',
                              serverInfo['server']?['port']?.toString() ??
                                  'N/A'),
                          _buildInfoRow(
                            'Uptime',
                            '${serverInfo['server']?['uptime']?.toStringAsFixed(0) ?? 'N/A'} seconds',
                          ),
                          _buildInfoRow(
                            'Firebase Initialized',
                            serverInfo['firebase']?['initialized']
                                    ?.toString() ??
                                'N/A',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (!isConnected) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Troubleshooting',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const Text('1. Is the backend server running?'),
                          const SizedBox(height: 4),
                          _buildCodeBlock('cd backend && npm run dev'),
                          const SizedBox(height: 12),
                          const Text('2. Check your .env file:'),
                          const SizedBox(height: 4),
                          _buildCodeBlock(
                              'STORAGE_BACKEND_URL=${EnvConfig.storageBackendUrl}'),
                          const SizedBox(height: 12),
                          const Text('3. For Android Emulator:'),
                          const SizedBox(height: 4),
                          _buildCodeBlock(
                              'STORAGE_BACKEND_URL=http://10.0.2.2:3000'),
                          const SizedBox(height: 12),
                          const Text('4. For Physical Device:'),
                          const SizedBox(height: 4),
                          _buildCodeBlock(
                              'STORAGE_BACKEND_URL=http://192.168.x.x:3000'),
                          const SizedBox(height: 12),
                          const Text('5. Check Windows Firewall:'),
                          const SizedBox(height: 4),
                          const Text(
                            'Port 3000 may be blocked by Windows Defender',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkConnectivity,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),

                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: EnvConfig.storageBackendUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Backend URL copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Backend URL'),
                ),

                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: () {
                    BackendConnectivityService.printDiagnostics();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Diagnostics printed to console')),
                    );
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Print Diagnostics to Console'),
                ),
              ],
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
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }
}
