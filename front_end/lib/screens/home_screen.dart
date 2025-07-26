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
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User chưa đăng nhập');
        return;
      }

      setState(() => _isLoading = true);
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
            _history = historyList.map((item) {
              final Map<String, dynamic> safeItem = item is Map
                  ? Map<String, dynamic>.from(item)
                  : {};
              print('Item: $safeItem');
              return {
                'id': safeItem['id']?.toString() ?? '',
                'problem': safeItem['problem']?.toString() ?? '',
                'solution': safeItem['solution']?.toString() ?? '',
                'file_type': safeItem['file_type']?.toString() ?? '',
                'date': _formatDateFromString(
                  safeItem['created_at']?.toString(),
                ),
              };
            }).toList();
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tải lịch sử: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải lịch sử: ${e.toString()}')),
      );
    }
  }

  // Hàm hỗ trợ chuyển đổi chuỗi ngày tháng
  String _formatDateFromString(String? dateString) {
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
              onPressed: () => Navigator.pushNamed(context, '/camera_upload'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.upload_file),
              label: Text('Tải lên ảnh/file'),
              onPressed: () => Navigator.pushNamed(context, '/camera_upload'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Lịch sử các bài đã giải:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                  ? Center(child: Text('Chưa có lịch sử.'))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(_getFileTypeIcon(item['file_type'])),
                            title: Text(
                              item['problem'].toString().length > 50
                                  ? '${item['problem'].toString().substring(0, 50)}...'
                                  : item['problem'],
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(item['date']),
                            onTap: () => _showSolutionDialog(context, item),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showSolutionDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết bài giải'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bài toán:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item['problem']),
              SizedBox(height: 16),
              Text('Lời giải:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item['solution']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
