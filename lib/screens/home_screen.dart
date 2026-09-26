import 'package:file_transfer_mobile/providers/transfer_listener_provider.dart';
import 'package:file_transfer_mobile/utils/identify_device.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_transfer_mobile/utils/file_saver.dart';
import 'package:file_transfer_mobile/dialogs/peer_selection.dart';
import 'package:file_transfer_mobile/providers/peer_provider.dart';
import 'package:file_transfer_mobile/dialogs/transfer_request.dart';
import 'package:file_transfer_mobile/dialogs/transfer_complete.dart';
import 'package:file_transfer_mobile/dialogs/transfer_progress.dart';
import 'package:file_transfer_mobile/widgets/uploaded_file_tile.dart';
import 'package:file_transfer_mobile/utils/internet_connectivity.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isInternet = false;

  void toggleInternetMode() {
    setState(() {
      isInternet = !isInternet;
    });
  }

  List<PlatformFile> uploadData = []; // stores the user uploaded file / media
  final internetConnectivity = InternetConnectivity(); // check for a internet connection in the app

  @override
  void initState() {
    super.initState();
    // Future.microtask(() => ref.read(peerProvider.notifier).start());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initailizeServices();
    });
    _setupInternetCheck();
  }

  TransferProgressController? progressController;
  int? port;

  void initailizeServices() async {
    final identity = ref.read(deviceIdentityProvider);
    port = await ref.read(transferListenerProvider.notifier).start(
          // 1. Consent Step
          onRequestConsent: (fileName, fileSize, deviceId, deviceName) async {
            if (!mounted) return false;
            final displayName = ref
              .read(peerProvider.notifier)
              .resolveDisplayName(deviceId, deviceName); // this device name is a placeholder for when deviceID can't be resovled

            final bool userAccepted = await TransferRequestDialog.show(
              context: context,
              fileName: fileName,
              fileSize: fileSize,
              deviceName: displayName,
              deviceId: deviceId,
            );

            // If accepted, pop open the standalone Progress Dialog
            if (userAccepted && mounted) {
              TransferProgressDialog.show(
                context: context,
                fileName: fileName,
                fileSize: fileSize,
                onReady: (controller) {
                  progressController = controller;
                },
              );
            }

            return userAccepted;
          },

          // 2. Stream Progress Updates -> Drives TransferProgressDialog
          onProgress: (progress) {
            progressController?.updateProgress(progress);
          },

          // 3. Bytes Complete in RAM -> Close Progress Dialog & Open Save/Discard Dialog
          onFileComplete: (fileName, fileBytes) async {
            if (!mounted) return;

            // Dismiss the progress dialog
            progressController?.close();
            progressController = null;

            // Pop up the Save / Discard Dialog
            final TransferCompleteChoice? choice =
                await TransferCompleteDialog.show(
                  context: context,
                  fileName: fileName,
                  fileSize: fileBytes.length,
                );

            if (choice == TransferCompleteChoice.save) {
              if(!mounted) return;

              await SafeFileSaver.save(
                context: context,
                fileName: fileName,
                fileBytes: fileBytes,
              );
            } else {
              print('User selected to DISCARD file. RAM reclaimed.');
            }
          },
        );
        
        // use the port returned from the listener to engage the peer discovery service
        await ref.read(peerProvider.notifier).start(
          deviceId: identity.id,
          deviceName: identity.name,
          port: port!,
        );
  }

  Future<void> _setupInternetCheck() async {
    internetConnectivity.onModeChanged = (isOnline) {
      if (!mounted) return;

      setState(() {
        isInternet = isOnline;
      });
    };

    await internetConnectivity.start();
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
    final uploadedExtensions = uploadData
        .map((u) => u.extension)
        .toList(); // collects all the uploaded file data by their extensions
    PeerSelectionDialog(
      uploadsByExtensions: uploadedExtensions,
      allUploads: uploadData,
    ).openDialog(context, ref);
  }

  @override
  void dispose() {
    internetConnectivity.stop();
    ref.read(peerProvider.notifier).stop();
    ref.read(transferListenerProvider.notifier).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final peers = ref.watch(peerProvider); // get discovered peers from peer provider
    // final port = ref.read(peerProvider.notifier).myPort; // get connected port

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

                    Text('App listening on port: ${port ?? "starting..."}'),

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

                    SizedBox(height: 20),

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

                                return UploadedFileTile(
                                  key: ValueKey(upload.path),
                                  uploadName: isImage
                                      ? "Image"
                                      : isVideo
                                      ? "Video"
                                      : upload.name,
                                  uploadSize:
                                      '${(upload.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                  uploadExtension: upload.extension ?? "",
                                  onTap: () => _removeUpload(upload),
                                ); // remove current uploaded item from uploadData list,);
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
