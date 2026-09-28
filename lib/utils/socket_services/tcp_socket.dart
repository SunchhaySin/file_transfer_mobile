import 'dart:io';

class TcpListener {
  ServerSocket? _serverSocket;

  final void Function(Socket client, List<int> data)? onDataReceived;
  final void Function(Socket client)? onClientConnected;
  final void Function(Socket client)? onClientDisconnected;

  TcpListener({
    this.onDataReceived,
    this.onClientConnected,
    this.onClientDisconnected,
  });

  Future<void> start() async {
    // Bind to all available network interfaces, port 0 = let OS pick a free port
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    print('Listening on ${_serverSocket!.address.address}:${_serverSocket!.port}');

    _serverSocket!.listen((Socket client) {
      print('Incoming connection from ${client.remoteAddress.address}:${client.remotePort}');

      client.listen(
          (data)  {
            onDataReceived?.call(client, data);
          },
          onDone: () {
            print('Client ${client.remoteAddress.address} disconnected');
            onClientDisconnected?.call(client);
            client.destroy();
          },
          onError: (error) {
            print('Socket error on ${client.remoteAddress.address}: $error');
            client.destroy();
          },
        );
      },
      onError: (error) {
        print('Server socket error: $error');
      },
    );
  }

  Future<void> stop() async {
    await _serverSocket?.close();
    print('Listener stopped');
  }

  int? get port => _serverSocket?.port;
}