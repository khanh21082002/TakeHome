import 'package:flutter/material.dart';

class ProcessingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đang xử lý')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Đang xử lý bài toán, vui lòng chờ...'),
          ],
        ),
      ),
    );
  }
} 