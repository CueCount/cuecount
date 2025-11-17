import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../widgets/uploadbutton.dart';


class ConnectionsSettingsPage extends StatelessWidget {
  const ConnectionsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Group metrics by category
    final Map<String, List<FinancialDataPoint>> grouped = {};

    for (var p in financialDataPoints) {
      grouped.putIfAbsent(p.category, () => []);
      grouped[p.category]!.add(p);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Connections Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          final category = entry.key;
          final items = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JsonToFirestoreUploader(),

              Text(
                category,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      e.label,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
            ],
          );
        }).toList(),
      ),
    );
  }
}
