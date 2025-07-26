import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmailController.text.isEmpty ||
        _loginPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Đăng nhập bằng Firebase Auth SDK
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _loginEmailController.text.trim(),
            password: _loginPasswordController.text,
          );

      // 2. Lấy ID Token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Không thể lấy token');
      }

      // 3. Gửi token lên backend để xác thực (optional - có thể bỏ qua nếu chỉ dùng Firebase)
      await _verifyTokenWithBackend(idToken);

      Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Đăng nhập thất bại';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    if (_registerEmailController.text.isEmpty ||
        _registerPasswordController.text.isEmpty ||
        _registerConfirmController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }

    if (_registerPasswordController.text != _registerConfirmController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận không khớp';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Đăng ký bằng Firebase Auth SDK
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _registerEmailController.text.trim(),
            password: _registerPasswordController.text,
          );

      // 2. Lấy ID Token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Không thể lấy token');
      }

      // 3. Gửi token lên backend để lưu thông tin user (optional)
      await _verifyTokenWithBackend(idToken);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đăng ký thành công!')));
      Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Đăng ký thất bại';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyTokenWithBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/verify-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode != 200) {
        print('Backend verification failed: ${response.body}');
      }
    } catch (e) {
      print('Backend verification error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng nhập/Đăng ký'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Đăng nhập'),
            Tab(text: 'Đăng ký'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Đăng nhập
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextField(
                  controller: _loginEmailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _loginPasswordController,
                  decoration: InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Đăng nhập'),
                ),
              ],
            ),
          ),
          // Đăng ký
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextField(
                  controller: _registerEmailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _registerPasswordController,
                  decoration: InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _registerConfirmController,
                  decoration: InputDecoration(labelText: 'Xác nhận mật khẩu'),
                  obscureText: true,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Đăng ký'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
