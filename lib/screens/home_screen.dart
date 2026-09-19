import 'package:flutter/material.dart';
import 'package:file_transfer_mobile/utils/socket_test.dart';

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

  @override
  void initState() {
    super.initState();
    listener.start();
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

                    Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.green.shade300,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade200,
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),

                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_sharp, size: 26),
                          SizedBox(width: 12),
                          Text(
                            "Upload Files",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
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
                  ],
                ),
              ),
            ),

            // Container(
            //   padding: EdgeInsets.all(10),
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(28),
            //     border:
            //   ),
            // )
            // TextButton(onPressed: () {}, child: Text("Learn More")),
            ElevatedButton(onPressed: () {}, child: Text("Learn More")),
          ],
        ),
      ),
    );
  }
}
