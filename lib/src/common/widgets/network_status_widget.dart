import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:todo_app/src/common/services/services_locator.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({super.key});

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  final Logger log = Logger();
  bool _isOnline = false;
  String _networkType = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initializeNetworkStatus();
  }

  Future<void> _initializeNetworkStatus() async {
    try {
      final networkService = ServicesLocator.networkService;
      _isOnline = await networkService.checkConnectivity();
      _networkType = await networkService.getNetworkType();

      if (mounted) {
        setState(() {});
      }

      networkService.networkStatusStream.listen((isOnline) async {
        if (mounted) {
          setState(() {
            _isOnline = isOnline;
            _networkType = 'Checking...';
          });

          final networkType = await networkService.getNetworkType();
          if (mounted) {
            setState(() {
              _networkType = networkType;
            });
          }
        }
      });
    } catch (error) {
      log.e("NetworkStatusWidget::Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green.withAlpha((0.1 * 255).round()) : Colors.red.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isOnline ? Colors.green : Colors.red, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_isOnline ? Icons.wifi : Icons.wifi_off, size: 16, color: _isOnline ? Colors.green : Colors.red),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _isOnline ? Colors.green : Colors.red),
          ),
          if (_isOnline) ...[const SizedBox(width: 4), Text('($_networkType)', style: TextStyle(fontSize: 10, color: Colors.grey[600]))],
        ],
      ),
    );
  }
}
