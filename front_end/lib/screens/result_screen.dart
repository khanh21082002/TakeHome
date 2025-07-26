import 'package:flutter/material.dart';
import '../widgets/solution_steps_widget.dart';

class ResultScreen extends StatelessWidget {
  // Placeholder dữ liệu
  final String imagePath = 'assets/sample_math.jpg';
  final String problemText = '2x + 3 = 7';
  final String solutionText = 'x = 2';
  final List<String> steps = [
    'Chuyển 3 sang phải: 2x = 7 - 3',
    '2x = 4',
    'Chia hai vế cho 2: x = 2',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kết quả')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ảnh bài toán:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(border: Border.all()),
              child: Center(child: Text('Preview ảnh: $imagePath')),
            ),
            SizedBox(height: 16),
            Text('Đề bài:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(problemText),
            SizedBox(height: 16),
            Text('Lời giải:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(solutionText),
            SizedBox(height: 16),
            Text('Các bước giải:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Expanded(child: SolutionStepsWidget(steps: steps)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('Lưu vào lịch sử'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                    child: Text('Giải bài mới'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 