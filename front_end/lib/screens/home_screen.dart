import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _historyItems = [];
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User chưa đăng nhập');
        return;
      }

      setState(() => _isProcessing = true);
      print('Đang tải lịch sử cho user: ${user.uid}');

      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Thêm kiểm tra kiểu dữ liệu trước khi parse
        dynamic responseData;
        if (response.body is String) {
          responseData = jsonDecode(response.body);
        } else {
          responseData = response.body;
        }

        print('Dữ liệu nhận được: ${responseData}');

        // Kiểm tra và xử lý dữ liệu an toàn
        if (responseData is Map && responseData.containsKey('history')) {
          final historyList = responseData['history'] as List? ?? [];

          setState(() {
            _historyItems = historyList.map((item) {
              final Map<String, dynamic> safeItem = item is Map
                  ? Map<String, dynamic>.from(item)
                  : {};
              print('Item: $safeItem');
              return {
                'id': safeItem['id']?.toString() ?? '',
                'problem': safeItem['problem']?.toString() ?? '',
                'solution': safeItem['solution']?.toString() ?? '',
                'file_type': safeItem['file_type']?.toString() ?? '',
                'date': _formatDateTime(safeItem['created_at']?.toString()),
              };
            }).toList();
            _isProcessing = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tải lịch sử: $e');
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải lịch sử: ${e.toString()}')),
      );
    }
  }

  // Hàm hỗ trợ chuyển đổi chuỗi ngày tháng
  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'Không rõ ngày';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return dateString; // Trả về nguyên bản nếu không parse được
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đăng xuất thất bại: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chủ'),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'Đăng xuất',
            )
          else
            IconButton(
              icon: Icon(Icons.login),
              onPressed: () => Navigator.pushNamed(context, '/auth'),
              tooltip: 'Đăng nhập',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Xin chào, ${user.email}!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Chụp ảnh bài toán'),
              onPressed: () => Navigator.pushNamed(context, '/camera'),
            ),
          ],
        ),
      ),
    );
  }
}