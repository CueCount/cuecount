import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoveDocumentsButton extends StatefulWidget {
  @override
  _MoveDocumentsButtonState createState() => _MoveDocumentsButtonState();
}

class _MoveDocumentsButtonState extends State<MoveDocumentsButton> {
  bool _isMoving = false;
  String _status = '';

  Future<void> moveAllDocuments() async {
    setState(() {
      _isMoving = true;
      _status = 'Starting move...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Get all documents from companies collection
      final companiesSnapshot = await firestore.collection('companies').get();
      
      int moved = 0;
      int total = companiesSnapshot.docs.length;
      
      setState(() {
        _status = 'Found $total documents to move';
      });

      // Move each document
      for (final doc in companiesSnapshot.docs) {
        // Write to documents collection
        await firestore.collection('documents').doc(doc.id).set(doc.data());
        
        // Delete from companies collection
        await doc.reference.delete();
        
        moved++;
        setState(() {
          _status = 'Moved $moved of $total documents';
        });
      }

      setState(() {
        _status = '✅ Successfully moved $moved documents!';
        _isMoving = false;
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isMoving = false;
      });
    }
  }

  Future<void> moveSingleDocument(String docId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Get the document
      final doc = await firestore.collection('companies').doc(docId).get();
      
      if (doc.exists) {
        // Write to documents collection
        await firestore.collection('documents').doc(docId).set(doc.data()!);
        
        // Delete from companies
        await doc.reference.delete();
        
        setState(() {
          _status = '✅ Moved document: $docId';
        });
      } else {
        setState(() {
          _status = '❌ Document not found: $docId';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Move Documents Tool',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          
          // Move all documents button
          ElevatedButton(
            onPressed: _isMoving ? null : moveAllDocuments,
            child: Text('Move ALL from companies → documents'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Colors.blue,
            ),
          ),
          
          SizedBox(height: 20),
          
          // Status text
          if (_status.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _status.contains('✅') 
                  ? Colors.green.withOpacity(0.1)
                  : _status.contains('❌')
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status.contains('✅') 
                    ? Colors.green
                    : _status.contains('❌')
                      ? Colors.red
                      : Colors.blue,
                ),
              ),
            ),
          
          if (_isMoving)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

// Add this to any page in your app:
// MoveDocumentsButton()

// Or use as a full page:
class MoveDocumentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Move Firestore Documents'),
      ),
      body: Center(
        child: MoveDocumentsButton(),
      ),
    );
  }
}