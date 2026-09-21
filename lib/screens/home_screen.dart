import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_transfer_mobile/utils/socket_test.dart';
import 'package:file_transfer_mobile/utils/peer_discovery.dart';
import 'package:file_transfer_mobile/dialogs/peer_selection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isInternet = false;

  void toggleInternetMode() {
    setState(() {
      isInternet = !isInternet;
    });
  }

  final listener = TcpListenerTest(); // inilialize the TcpListneterTest
  PeerDiscovery? peerDiscovery;
  List<Peer> peers = []; // store discovered peers

  List<PlatformFile> uploadData = []; // stores the user uploaded file / media

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await listener.start(); // bind socket first, so we know the real port

    final deviceId =
        'device-${DateTime.now().millisecondsSinceEpoch}'; // simple unique-ish ID for now

    peerDiscovery = PeerDiscovery(myDeviceId: deviceId, myPort: listener.port!);
    peerDiscovery!.onPeersChanged = (updatedPeers) {
      setState(() => peers = updatedPeers);
    };

    await peerDiscovery!.start();
    setState(() {}); // refresh UI once port is known
  }

  Future<void> _connectToPeer(Peer peer) async {
    try {
      final socket = await Socket.connect(
        peer.ip,
        peer.port,
        timeout: const Duration(seconds: 5),
      );
      print('Connected to ${peer.name}!');
      socket.add('hello from device'.codeUnits);
    } catch (e) {
      print('Connection failed: $e');
    }
  }

  Future<void> testConnect(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(seconds: 5),
      );
      print('Connected!');
      socket.add('hello from device B'.codeUnits);
    } catch (e) {
      print('Connection failed: $e');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
      withData: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        uploadData.add(result.files.first);
      });
    }
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.pickFiles(
      type: FileType.media,
      allowMultiple: false,
      withData: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        uploadData.add(result.files.first);
      });
    }
  }

  void _removeUpload(PlatformFile upload) {
    setState(() {
      uploadData.removeWhere((f) => f.path == upload.path);
    });
  }

  // Open the peer dialog for peer selection
  void openPeerSelectionDialog(context) {
    if (uploadData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("No files or media selected!")),
      );
      return;
    }
    print('Opening dialog with peers: ${peers.map((p) => p.name).toList()}');
    PeerSelectionDialog(peers: peers).openDialog(context);
  }

  // Return the matching Icon for each file/media type
  IconData _iconForExtension(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'heic':
        return Icons.image_outlined;
      case 'mov':
      case 'mp4':
        return Icons.videocam_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'zip':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  void dispose() {
    peerDiscovery?.stop();
    listener.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade200,
      body: SafeArea(
        child: Column(
          children: [
            Text(
              "Peer-to-Peer File Transfer",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),

            Padding(
              padding: EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.shade400,
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Colors.amberAccent.shade200,
                          Colors.amber.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security),
                        SizedBox(width: 10),
                        Text(
                          "Secure",
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade300,
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.shade100,
                          Colors.blue.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.devices),
                        SizedBox(width: 10),
                        Text(
                          "Direct",
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade200,
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent.shade100,
                          Colors.red.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.favorite_border),
                        SizedBox(width: 10),
                        Text(
                          "Favourite",
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.0),
                margin: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withOpacity(0.65),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => toggleInternetMode(),
                          child: Container(
                            width: 140,
                            decoration: BoxDecoration(
                              border: BoxBorder.all(
                                color: isInternet ? Colors.green : Colors.red,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.all(4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Icon(
                                  isInternet ? Icons.wifi : Icons.wifi_off,
                                  size: 26,
                                  color: isInternet ? Colors.green : Colors.red,
                                ),
                                Text(
                                  isInternet
                                      ? "Internet: On "
                                      : "Internet: Off",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(width: 12),

                        Column(
                          children: [
                            Icon(Icons.info_outline, size: 26),
                            Text("Info", style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),

                    Divider(color: Colors.black12, height: 4),

                    SizedBox(height: 10),

                    Text(
                      'App listening on port: ${listener.port ?? "starting..."}',
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Select File or Media for sharing",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 5),

                    Container(
                      height: 100,
                      width: 302,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.black54),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _pickFile(),
                            child: Container(
                              width: 150,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(26),
                                  bottomLeft: Radius.circular(26),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file_outlined,
                                        size: 26,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "File",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  Text(
                                    "(ZIP, PDF, PNG, JPG)",
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () => _pickMedia(),
                            child: Container(
                              width: 150,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(26),
                                  bottomRight: Radius.circular(26),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, size: 26),
                                      SizedBox(width: 12),
                                      Text(
                                        "Media",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "(Photos & Videos)",
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Maximum File Size: 1GB",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                      ),
                    ),

                    SizedBox(height: 12),

                    GestureDetector(
                      onTap: () =>
                          openPeerSelectionDialog(context), // open peer dialog
                      child: Container(
                        width: 160,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: uploadData.isNotEmpty
                                  ? Colors.green.shade600
                                  : Colors.grey.shade700,
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: uploadData.isNotEmpty
                                ? [
                                    Colors.greenAccent.shade400,
                                    Colors.green.shade500,
                                  ]
                                : [Colors.grey.shade300, Colors.grey.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.ios_share_outlined,
                              color: uploadData.isNotEmpty
                                  ? Colors.black
                                  : Colors.black45,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Share",
                              style: TextStyle(
                                fontSize: 14,
                                color: uploadData.isNotEmpty
                                    ? Colors.black
                                    : Colors.black45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded(
                    //   child: ListView.builder(
                    //     itemCount: peers.length,
                    //     itemBuilder: (context, index) {
                    //       final peer = peers[index];
                    //       return ListTile(
                    //         title: Text(peer.name),
                    //         subtitle: Text('${peer.ip}:${peer.port}'),
                    //         trailing: ElevatedButton(
                    //           onPressed: () => _connectToPeer(peer),
                    //           child: const Text('Connect'),
                    //         ),
                    //       );
                    //     },
                    //   ),
                    // ),
                    Expanded(
                      child: uploadData.isNotEmpty
                          ? ListView.builder(
                              itemCount: uploadData.length,
                              itemBuilder: (context, index) {
                                
                                const videoExtensions = {'mov', 'mp4'};

                                final upload = uploadData[index];
                                final extension =
                                    upload.extension?.toLowerCase() ?? '';

                                final isImage = extension == "heic";
                                final isVideo = videoExtensions.contains(
                                  extension,
                                );

                                return ListTile(
                                  title: Text(isImage ? "Image" : isVideo ? "Video" : upload.name),
                                  subtitle: Text(
                                    '${(upload.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                  ), // convert bytes -> megabytes
                                  trailing: InkWell(
                                    onTap: () => _removeUpload(
                                      upload,
                                    ), // remove current uploaded item from uploadData list
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                  leading: Icon(_iconForExtension(extension), size: 28),
                                );
                              },
                            )
                          : SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
