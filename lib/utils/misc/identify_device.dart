import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Returns deviceId & deviceName for registering peer into the TCP socket connection
class DeviceIdentity {
  final String id;
  final String name;
  const DeviceIdentity({required this.id, required this.name});
}

/// Generated once per app run — no listeners or sockets involved.
final deviceIdentityProvider = Provider<DeviceIdentity>((ref) {
  return DeviceIdentity(
    id: 'device-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}',
    name: 'Mobile Device', // fallback shown when a peer can't be resolved
  );
});