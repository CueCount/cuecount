import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/nav.dart';
import 'company_documents.dart';
import 'login_page.dart';

class CompaniesPage extends StatelessWidget {
  final User? user;
  const CompaniesPage({super.key, this.user});

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
            const Text(
              'Companies',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('companies')
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No companies found'),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final companyName = data['name'] ?? 'Unknown Company';
                      final documents = List<String>.from(data['documents'] ?? []);

                      return CompanyCard(
                        companyId: doc.id,
                        companyName: companyName,
                        documentCount: documents.length,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompanyDetailPage(
                                companyId: doc.id,
                                companyName: companyName,
                                documentIds: documents,
                                user: user,
                              ),
                            ),
                          );
                        },
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

class CompanyCard extends StatelessWidget {
  final String companyId;
  final String companyName;
  final int documentCount;
  final VoidCallback onTap;

  const CompanyCard({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.documentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.business,
                  size: 48,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(height: 16),
                Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '$documentCount documents',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
