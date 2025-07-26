import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class MathProblemSolverScreen extends StatefulWidget {
  @override
  _MathProblemSolverScreenState createState() =>
      _MathProblemSolverScreenState();
}

class _MathProblemSolverScreenState extends State<MathProblemSolverScreen> {
  // Trạng thái file
  File? _selectedImageFile;
  String? _fileType;
  String? _fileName;
  String? _warning;
  String? _pdfPath;
  Uint8List? _webFileBytes;

  // Trạng thái upload
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _downloadUrl;

  // Trạng thái xử lý
  bool _isProcessing = false;
  String? _processingResult;
  List<String>? _solutionSteps;

  Future<void> _pickFile() async {
    setState(() {
      _warning = null;
      _downloadUrl = null;
      _webFileBytes = null;
      _processingResult = null;
      _solutionSteps = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext =
            file.extension?.toLowerCase() ??
            (file.name.contains('.')
                ? file.name.split('.').last.toLowerCase()
                : '');

        setState(() {
          _fileType = ext;
          _fileName = file.name;
        });

        if (kIsWeb) {
          if (file.bytes != null) {
            setState(() {
              _webFileBytes = file.bytes;
              if (!['jpg', 'jpeg', 'png'].contains(ext)) {
                _warning = 'Chỉ xem trước được ảnh trên web';
              }
            });
          }
        } else {
          if (file.path != null) {
            setState(() {
              if (['jpg', 'jpeg', 'png'].contains(ext)) {
                _selectedImageFile = File(file.path!);
                _pdfPath = null;
              } else if (ext == 'pdf') {
                _pdfPath = file.path!;
                _selectedImageFile = null;
              } else {
                _warning = 'File $ext sẽ được gửi đến server để xử lý';
              }
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _warning = 'Lỗi khi chọn file: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadFile() async {
    if ((_selectedImageFile == null &&
            _pdfPath == null &&
            _webFileBytes == null) ||
        _isUploading)
      return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _downloadUrl = null;
      _processingResult = null;
      _solutionSteps = null;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          _fileName ?? 'math_problem_$timestamp.${_fileType ?? 'jpg'}';
      final ref = FirebaseStorage.instance.ref().child(
        'math_problems/$fileName',
      );

      if (kIsWeb && _webFileBytes != null) {
        final uploadTask = ref.putData(
          _webFileBytes!,
          SettableMetadata(contentType: _getMimeType(_fileType)),
        );

        uploadTask.snapshotEvents.listen((taskSnapshot) {
          setState(() {
            _uploadProgress =
                taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          });
        });

        await uploadTask;
      } else if (!kIsWeb) {
        final fileToUpload = _selectedImageFile ?? File(_pdfPath!);
        final uploadTask = ref.putFile(fileToUpload);

        uploadTask.snapshotEvents.listen((taskSnapshot) {
          setState(() {
            _uploadProgress =
                taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          });
        });

        await uploadTask;
      }

      final url = await ref.getDownloadURL();
      setState(() {
        _downloadUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload file thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload thất bại: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _processMathProblem() async {
    if (_downloadUrl == null) return;

    setState(() {
      _isProcessing = true;
      _processingResult = null;
      _solutionSteps = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/api/solve'),
      );

      // Thêm các trường dữ liệu
      request.fields['fileUrl'] = _downloadUrl!;
      request.fields['fileType'] = _fileType ?? 'pdf';
      request.fields['options'] = jsonEncode({
        'detectHandwriting': true,
        'detailedSteps': true,
      });

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        setState(() {
          _processingResult = data['solution'];
          _solutionSteps = List<String>.from(data['steps'] ?? []);
        });
      } else {
        throw Exception('Server error: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _getMimeType(String? extension) {
    if (extension == null) return 'application/octet-stream';
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  void _resetAll() {
    setState(() {
      _selectedImageFile = null;
      _fileType = null;
      _fileName = null;
      _warning = null;
      _pdfPath = null;
      _webFileBytes = null;
      _downloadUrl = null;
      _processingResult = null;
      _solutionSteps = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giải Bài Toán Từ File'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetAll,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Khu vực chọn file
            _buildFileSelectionSection(),
            SizedBox(height: 24),

            // Hiển thị preview file
            if (_selectedImageFile != null ||
                _pdfPath != null ||
                _webFileBytes != null)
              _buildFilePreviewSection(),

            // Khu vực upload
            if ((_selectedImageFile != null ||
                    _pdfPath != null ||
                    _webFileBytes != null) &&
                _downloadUrl == null)
              _buildUploadSection(),

            // Khu vực xử lý bài toán
            if (_downloadUrl != null) _buildProcessingSection(),

            // Hiển thị kết quả
            if (_processingResult != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionSection() {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.upload_file),
          label: Text('CHỌN FILE BÀI TOÁN'),
          onPressed: _pickFile,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Hỗ trợ file ảnh (JPG/PNG), PDF, DOC/DOCX',
          style: TextStyle(color: Colors.grey),
        ),
        if (_fileName != null) ...[
          SizedBox(height: 16),
          Text(
            'File đã chọn: $_fileName',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
        if (_warning != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(_warning!, style: TextStyle(color: Colors.orange)),
          ),
      ],
    );
  }

  Widget _buildFilePreviewSection() {
    return Column(
      children: [
        if (_selectedImageFile != null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.file(_selectedImageFile!, fit: BoxFit.contain),
          ),

        if (_pdfPath != null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PdfDocumentLoader(
              doc: PdfDocument.openFile(_pdfPath!),
              pageNumber: 1,
              pageBuilder: (context, textureBuilder, pageSize) =>
                  textureBuilder(),
            ),
          ),

        if (_webFileBytes != null && ['jpg', 'jpeg', 'png'].contains(_fileType))
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.memory(_webFileBytes!, fit: BoxFit.contain),
          ),

        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      children: [
        if (_isUploading) ...[
          LinearProgressIndicator(value: _uploadProgress),
          SizedBox(height: 8),
          Text(
            'Đang upload: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 16),
        ],
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadFile,
          child: Text(_isUploading ? 'ĐANG UPLOAD...' : 'UPLOAD LÊN SERVER'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingSection() {
    return Column(
      children: [
        Text(
          'File đã upload thành công!',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processMathProblem,
          child: _isProcessing
              ? CircularProgressIndicator(color: Colors.white)
              : Text('GIẢI BÀI TOÁN NÀY'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        SizedBox(height: 8),
        if (_isProcessing)
          Text(
            'Đang phân tích và giải bài toán...',
            style: TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 32),
        Text(
          'KẾT QUẢ GIẢI TOÁN',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_processingResult!, style: TextStyle(fontSize: 16)),
        ),
        if (_solutionSteps != null && _solutionSteps!.isNotEmpty) ...[
          SizedBox(height: 24),
          Text(
            'CÁC BƯỚC GIẢI:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 8),
          ..._solutionSteps!.map(
            (step) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(step)),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: _resetAll,
          child: Text('GIẢI BÀI TOÁN KHÁC'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
