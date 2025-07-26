import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/camera_upload_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Solver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Kiểm tra trạng thái kết nối
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Nếu đã đăng nhập, chuyển đến HomeScreen
          if (snapshot.hasData) {
            return HomeScreen();
          }

          // Nếu chưa đăng nhập, hiển thị AuthScreen
          return AuthScreen();
        },
      ),
      routes: {
        '/home': (context) => HomeScreen(),
        '/auth': (context) => AuthScreen(),
        '/camera_upload': (context) => MathProblemSolverScreen(),
        '/processing': (context) => ProcessingScreen(),
        '/result': (context) => ResultScreen(),
      },
    );
  }
}
