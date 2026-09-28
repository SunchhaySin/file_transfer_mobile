import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetConnectivity {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  void Function(bool isOnline)? onModeChanged;

  Future<bool> hasRealInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<bool> start() async {
    // Fire once immediately with the current state
    final initial = await Connectivity().checkConnectivity();
    
    final hasInterface =
        initial.contains(ConnectivityResult.wifi) ||
        initial.contains(ConnectivityResult.mobile);
    final trulyOnline = hasInterface && await hasRealInternetAccess();
    onModeChanged?.call(trulyOnline);

    // Then listen for future changes
    _subscription = Connectivity().onConnectivityChanged.listen((result) async {
      final hasInterface =
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);
      final trulyOnline = hasInterface && await hasRealInternetAccess();
      onModeChanged?.call(trulyOnline);
    });

    return trulyOnline;
  }

  void stop() {
    _subscription?.cancel();
  }
}
