import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class JsonToFirestoreUploader extends StatefulWidget {
  @override
  _JsonToFirestoreUploaderState createState() => _JsonToFirestoreUploaderState();
}

class _JsonToFirestoreUploaderState extends State<JsonToFirestoreUploader> {
  bool _isUploading = false;
  String _status = '';
  Map<String, dynamic>? _previewData;

  Future<void> pickAndUploadJson() async {
    try {
      // Pick JSON file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Important for web
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _status = '📂 File selected: ${result.files.single.name}';
        });

        // Read file content
        String jsonString;
        if (kIsWeb) {
          // Web platform
          jsonString = utf8.decode(result.files.single.bytes!);
        } else {
          // Mobile/Desktop platforms
          final file = File(result.files.single.path!);
          jsonString = await file.readAsString();
        }

        // Parse JSON
        final dynamic jsonData = json.decode(jsonString);
        
        // Handle both single document and array of documents
        if (jsonData is Map<String, dynamic>) {
          // Single document
          setState(() {
            _previewData = jsonData;
            _status = '📄 Found 1 document to upload';
          });
          await _uploadSingleDocument(jsonData);
        } else if (jsonData is List) {
          // Multiple documents
          setState(() {
            _status = '📄 Found ${jsonData.length} documents to upload';
          });
          await _uploadMultipleDocuments(jsonData);
        } else {
          setState(() {
            _status = '❌ Invalid JSON format';
          });
        }
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadSingleDocument(Map<String, dynamic> docData) async {
    setState(() {
      _isUploading = true;
      _status = '⬆️ Uploading document...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Generate document ID - you can customize this logic
      String docId;
      if (docData.containsKey('id')) {
        docId = docData['id'].toString();
        docData.remove('id'); // Remove id from data if it's used as doc ID
      } else if (docData.containsKey('name')) {
        // Use name as ID if available (make it URL-safe)
        docId = docData['name'].toString().toLowerCase().replaceAll(' ', '_');
      } else {
        // Auto-generate ID
        docId = firestore.collection('documents').doc().id;
      }

      // Add timestamp
      docData['uploadedAt'] = FieldValue.serverTimestamp();
      
      // Upload to Firestore
      await firestore.collection('documents').doc(docId).set(docData);
      
      setState(() {
        _status = '✅ Successfully uploaded document with ID: $docId';
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Upload failed: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadMultipleDocuments(List<dynamic> documents) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      int uploaded = 0;
      int total = documents.length;

      for (var doc in documents) {
        if (doc is Map<String, dynamic>) {
          // Generate document ID
          String docId;
          if (doc.containsKey('id')) {
            docId = doc['id'].toString();
            doc.remove('id');
          } else if (doc.containsKey('name')) {
            docId = doc['name'].toString().toLowerCase().replaceAll(' ', '_');
          } else {
            docId = firestore.collection('documents').doc().id;
          }

          // Add timestamp
          doc['uploadedAt'] = FieldValue.serverTimestamp();
          
          // Upload to Firestore
          await firestore.collection('documents').doc(docId).set(doc);
          
          uploaded++;
          setState(() {
            _status = '⬆️ Uploading: $uploaded / $total';
          });
        }
      }

      setState(() {
        _status = '✅ Successfully uploaded $uploaded documents!';
        _isUploading = false;
        _previewData = null;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Upload failed: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'JSON to Firestore Uploader',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Upload JSON files to create documents',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 20),
          
          // Upload button
          ElevatedButton.icon(
            onPressed: _isUploading ? null : pickAndUploadJson,
            icon: Icon(Icons.upload_file),
            label: Text('Choose JSON File'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Colors.blue,
            ),
          ),
          
          SizedBox(height: 20),
          
          // Status display
          if (_status.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status.contains('✅') 
                  ? Colors.green.withOpacity(0.1)
                  : _status.contains('❌')
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _status.contains('✅') 
                    ? Colors.green
                    : _status.contains('❌')
                      ? Colors.red
                      : Colors.blue,
                  width: 1,
                ),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status.contains('✅') 
                    ? Colors.green[700]
                    : _status.contains('❌')
                      ? Colors.red[700]
                      : Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          // Loading indicator
          if (_isUploading)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            ),
          
          // Preview data (optional)
          if (_previewData != null && !_isUploading)
            Container(
              margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview (first few fields):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...(_previewData!.entries.take(3).map((e) => 
                    Text('${e.key}: ${e.value}', 
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    )
                  )),
                  if (_previewData!.length > 3)
                    Text('...and ${_previewData!.length - 3} more fields',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          
          // Instructions
          Container(
            margin: EdgeInsets.only(top: 30),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📝 JSON Format Examples:', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Single document:', style: TextStyle(fontSize: 12)),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: Text(
                    '{"name": "Company ABC", "industry": "Tech", "size": 100}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
                Text('Multiple documents:', style: TextStyle(fontSize: 12)),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: Text(
                    '[{"name": "Company A"}, {"name": "Company B"}]',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Full page version
class JsonUploaderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload JSON to Firestore'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: JsonToFirestoreUploader(),
        ),
      ),
    );
  }
}