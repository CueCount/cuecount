import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/nav.dart';
import 'login_page.dart';
import 'visualization.dart';

class CompanyDetailPage extends StatelessWidget {
  final String companyId;
  final String companyName;
  final List<String> documentIds;
  final User? user;

  const CompanyDetailPage({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.documentIds,
    this.user,
  });

  Future<List<DocumentSnapshot>> _fetchAndSortDocuments(List<String> docIds) async {
    // Fetch all documents
    final futures = docIds.map((id) => 
      FirebaseFirestore.instance
        .collection('documents')
        .doc(id)
        .get()
    ).toList();
    
    final snapshots = await Future.wait(futures);
    
    // Sort documents by period (year desc, then quarter asc)
    snapshots.sort((a, b) {
      if (!a.exists || !b.exists) return 0;
      
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      
      final aPeriod = aData['period'] ?? '';
      final bPeriod = bData['period'] ?? '';
      
      // Parse periods (e.g., "2024_Q2")
      final aMatch = RegExp(r'(\d{4})_Q(\d)').firstMatch(aPeriod.toString());
      final bMatch = RegExp(r'(\d{4})_Q(\d)').firstMatch(bPeriod.toString());
      
      if (aMatch == null || bMatch == null) return 0;
      
      final aYear = int.parse(aMatch.group(1)!);
      final bYear = int.parse(bMatch.group(1)!);
      final aQuarter = int.parse(aMatch.group(2)!);
      final bQuarter = int.parse(bMatch.group(2)!);
      
      // Sort by year (descending)
      if (aYear != bYear) {
        return bYear.compareTo(aYear);
      }
      
      // If same year, sort by quarter (ascending)
      return aQuarter.compareTo(bQuarter);
    });
    
    return snapshots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        user: user,
        onHome: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onLogin: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
          );
        },
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      drawer: SidebarMenu(
        user: user,
        onHome: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onLogin: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
          );
        },
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisualizationPage(
                          companyId: companyId,
                          companyName: companyName,
                          documentIds: documentIds,
                          user: user,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('3D Visualization'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${documentIds.length} documents',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: documentIds.isEmpty
                  ? const Center(
                      child: Text(
                        'No documents linked to this company',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : FutureBuilder<List<DocumentSnapshot>>(
                      future: _fetchAndSortDocuments(documentIds),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error loading documents: ${snapshot.error}'),
                          );
                        }

                        final documents = snapshot.data ?? [];
                        
                        return ListView.builder(
                          itemCount: documents.length,
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            final data = doc.exists ? doc.data() as Map<String, dynamic> : null;
                            
                            if (data == null) {
                              return DocumentCard(
                                documentId: doc.id,
                                documentTitle: 'Document ID: ${doc.id}',
                                documentSubtitle: 'Document not found',
                                ticker: '',
                                isError: true,
                              );
                            }

                            final type = data['type'] ?? 'Unknown type';
                            final period = data['period'] ?? 'Period unknown';
                            final ticker = data['ticker'] ?? '';

                            return DocumentCard(
                              documentId: doc.id,
                              documentTitle: type,
                              documentSubtitle: period,
                              ticker: ticker,
                              data: data,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  final String documentId;
  final String documentTitle;
  final String documentSubtitle;
  final String ticker;
  final Map<String, dynamic>? data;
  final bool isError;

  const DocumentCard({
    super.key,
    required this.documentId,
    required this.documentTitle,
    required this.documentSubtitle,
    this.ticker = '',
    this.data,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          if (!isError && data != null) {
            // Show document details in a dialog or navigate to a detail page
            showDialog(
              context: context,
              builder: (context) => DocumentDetailDialog(
                documentId: documentId,
                documentTitle: documentTitle,
                data: data!,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isError ? Colors.red.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.description,
                  color: isError ? Colors.red.shade700 : Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (ticker.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ticker,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            documentTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (documentSubtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        documentSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isError)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DocumentDetailDialog extends StatelessWidget {
  final String documentId;
  final String documentTitle;
  final Map<String, dynamic> data;

  const DocumentDetailDialog({
    super.key,
    required this.documentId,
    required this.documentTitle,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    documentTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Document ID: $documentId',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.entries.map((entry) {
                    String value = '';
                    if (entry.value is Timestamp) {
                      value = (entry.value as Timestamp).toDate().toString();
                    } else if (entry.value is List) {
                      value = (entry.value as List).join(', ');
                    } else {
                      value = entry.value.toString();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}