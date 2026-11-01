import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_transfer_mobile/screens/splash_screen.dart';
import 'package:file_transfer_mobile/utils/performance/metrics.dart';

void main() {
  Metrics.markAppStart();
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => Metrics.mark('first_frame_ms'), // the first frame has been drawn
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline File Transfer System Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: SplashScreen(),
    );
  }
}

