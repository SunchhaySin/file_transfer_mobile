import 'dart:io';

class TcpListener {
  ServerSocket? _serverSocket;

  Future<void> start() async {
    // Bind to all available network interfaces, port 0 = let OS pick a free port
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    print('Listening on ${_serverSocket!.address.address}:${_serverSocket!.port}');

    _serverSocket!.listen((Socket client) {
      print('Incoming connection from ${client.remoteAddress.address}:${client.remotePort}');

      client.listen(
        (data) => print('Received: ${String.fromCharCodes(data)}'),
        onDone: () => print('Client disconnected'),
        onError: (e) => print('Socket error: $e'),
      );
    });
  }

  Future<void> stop() async {
    await _serverSocket?.close();
    print('Listener stopped');
  }

  int? get port => _serverSocket?.port;
}