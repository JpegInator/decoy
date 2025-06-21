import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerWidget extends StatelessWidget {
  final Widget child;
  final String permissionType;
  final IconData icon;
  final Function? onPermissionDenied;
  final Permission permission; // Добавляем тип разрешения

  const PermissionHandlerWidget({
    super.key,
    required this.child,
    this.permissionType = 'доступа к данным о физической активности',
    this.icon = Icons.warning_amber_rounded,
    this.onPermissionDenied,
    required this.permission, // Делаем обязательным параметром
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPermissions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == true) {
          return child;
        }

        return _buildPermissionDenied(context);
      },
    );
  }

  Future<bool> _checkPermissions() async {
    // Запрашиваем разрешение напрямую
    final status = await permission.request();
    return status.isGranted;
  }

  Widget _buildPermissionDenied(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.orange),
          const SizedBox(height: 20),
          Text(
            'Требуется разрешение',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Для работы этой функции необходимо предоставить разрешение $permissionType',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            child: const Text('Запросить разрешение'),
            onPressed: () async {
              final granted = await _checkPermissions();
              if (!granted && onPermissionDenied != null) {
                onPermissionDenied!();
              }
            },
          ),
          TextButton(
            child: const Text('Открыть настройки'),
            onPressed: () => openAppSettings(),
          ),
        ],
      ),
    );
  }
}