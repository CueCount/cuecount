import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single cell in the data table
class DataCell {
  final dynamic value;
  final String documentId;
  final bool exists;
  
  DataCell({
    required this.value,
    required this.documentId,
    this.exists = true,
  });
  
  DataCell.empty(this.documentId) : value = null, exists = false;
  
  double? get numericValue {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }
}

/// Represents a row in the data table (one field across all quarters)
class DataRow {
  final String fieldName;
  final List<DataCell> cells;
  
  DataRow({
    required this.fieldName,
    required this.cells,
  });
  
  /// Get all numeric values in this row
  List<double> get numericValues {
    return cells
        .where((cell) => cell.numericValue != null)
        .map((cell) => cell.numericValue!)
        .toList();
  }
  
  /// Get min and max values for normalization
  double? get minValue {
    final values = numericValues;
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a < b ? a : b);
  }
  
  double? get maxValue {
    final values = numericValues;
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }
}

/// Represents the complete data table
class DataTable {
  final List<String> quarters; // Column headers (e.g., "2024_Q3", "2024_Q2", etc.)
  final List<String> documentIds; // Document IDs in same order as quarters
  final List<DataRow> rows; // Each row is a field across all quarters
  final Map<String, Map<String, dynamic>> metadata; // Store non-numeric data
  
  DataTable({
    required this.quarters,
    required this.documentIds,
    required this.rows,
    this.metadata = const {},
  });
  
  /// Get a specific cell value
  DataCell? getCell(String fieldName, String quarter) {
    final row = rows.firstWhere(
      (r) => r.fieldName == fieldName,
      orElse: () => DataRow(fieldName: fieldName, cells: []),
    );
    
    final quarterIndex = quarters.indexOf(quarter);
    if (quarterIndex == -1 || quarterIndex >= row.cells.length) {
      return null;
    }
    
    return row.cells[quarterIndex];
  }
  
  /// Get all field names
  List<String> get fieldNames => rows.map((r) => r.fieldName).toList();
  
  /// Get numeric field names only
  List<String> get numericFieldNames {
    return rows
        .where((row) => row.numericValues.isNotEmpty)
        .map((row) => row.fieldName)
        .toList();
  }
}

/// Builds a data table from financial documents
class DataTableBuilder {
  
  /// Create a data table from a list of documents sorted by period
  static DataTable buildFromDocuments(List<DocumentSnapshot> sortedDocuments) {
    if (sortedDocuments.isEmpty) {
      return DataTable(quarters: [], documentIds: [], rows: []);
    }
    
    // Extract quarters and document IDs
    final quarters = <String>[];
    final documentIds = <String>[];
    final metadata = <String, Map<String, dynamic>>{};
    
    // Get all unique field names from the nested 'data' field
    final allFields = <String>{};
    
    for (var doc in sortedDocuments) {
      if (!doc.exists) continue;
      
      final docData = doc.data() as Map<String, dynamic>;
      
      // Extract the nested data map
      final financialData = docData['data'] as Map<String, dynamic>?;
      if (financialData == null) {
        print('Warning: Document ${doc.id} has no data field');
        continue;
      }
      
      // Get period from the data field or use document ID
      final period = financialData['period'] ?? 
                     docData['period'] ?? 
                     'Q${documentIds.length + 1}';
      
      quarters.add(period.toString());
      documentIds.add(doc.id);
      
      // Store metadata
      metadata[doc.id] = {
        'company': docData['company'],
        'uploadedAt': docData['uploadedAt'],
      };
      
      // Collect all field names from the financial data
      allFields.addAll(financialData.keys);
    }
    
    print('Building table for ${quarters.length} documents');
    print('Company: ${metadata.values.first['company']}');
    
    // Remove any non-financial fields if they exist in the data map
    final excludedFields = {'period', 'ticker', 'type', 'timestamp', 'createdAt'};
    final dataFields = allFields.difference(excludedFields).toList()..sort();
    
    print('Found ${dataFields.length} financial fields');
    
    // Build rows - one for each financial field
    final rows = <DataRow>[];
    
    for (String fieldName in dataFields) {
      final cells = <DataCell>[];
      
      for (var doc in sortedDocuments) {
        if (!doc.exists) {
          cells.add(DataCell.empty(doc.id));
          continue;
        }
        
        final docData = doc.data() as Map<String, dynamic>;
        final financialData = docData['data'] as Map<String, dynamic>?;
        
        if (financialData != null && financialData.containsKey(fieldName)) {
          cells.add(DataCell(
            value: financialData[fieldName],
            documentId: doc.id,
          ));
        } else {
          cells.add(DataCell.empty(doc.id));
        }
      }
      
      rows.add(DataRow(
        fieldName: fieldName,
        cells: cells,
      ));
    }
    
    // Debug output - show first few rows with actual values
    print('Created table with ${rows.length} rows and ${quarters.length} columns');
    for (var row in rows.take(5)) {
      final values = row.cells.map((c) {
        if (c.numericValue != null) {
          // Format large numbers for readability
          final val = c.numericValue!;
          if (val.abs() >= 1e9) {
            return '${(val / 1e9).toStringAsFixed(1)}B';
          } else if (val.abs() >= 1e6) {
            return '${(val / 1e6).toStringAsFixed(1)}M';
          }
          return val.toStringAsFixed(0);
        }
        return 'null';
      }).join(', ');
      print('  ${row.fieldName}: [$values]');
    }
    
    return DataTable(
      quarters: quarters,
      documentIds: documentIds,
      rows: rows,
      metadata: metadata,
    );
  }
  
  /// Create connections from the data table for visualization
  static List<TableConnection> createConnections(DataTable table) {
    final connections = <TableConnection>[];
    
    for (var row in table.rows) {
      // Skip non-numeric rows
      if (row.numericValues.isEmpty) continue;
      
      // Create connections between consecutive quarters
      for (int i = 0; i < row.cells.length - 1; i++) {
        final currentCell = row.cells[i];
        final nextCell = row.cells[i + 1];
        
        if (currentCell.numericValue != null && nextCell.numericValue != null) {
          connections.add(TableConnection(
            fieldName: row.fieldName,
            fromQuarter: table.quarters[i],
            toQuarter: table.quarters[i + 1],
            fromValue: currentCell.numericValue!,
            toValue: nextCell.numericValue!,
            quarterIndex: i,
          ));
        }
      }
    }
    
    return connections;
  }
}

/// Represents a connection between two data points in the table
class TableConnection {
  final String fieldName;
  final String fromQuarter;
  final String toQuarter;
  final double fromValue;
  final double toValue;
  final int quarterIndex;
  
  TableConnection({
    required this.fieldName,
    required this.fromQuarter,
    required this.toQuarter,
    required this.fromValue,
    required this.toValue,
    required this.quarterIndex,
  });
  
  double get delta => toValue - fromValue;
  
  double get percentageChange {
    if (fromValue == 0) return 0;
    return (delta / fromValue) * 100;
  }
}

/// Helper class for visualizing the data table
class TableVisualizationData {
  final DataTable table;
  final List<TableConnection> connections;
  final Map<String, List<double>> fieldTimeSeries;
  final Map<String, double> minValues;
  final Map<String, double> maxValues;
  final double globalMin;
  final double globalMax;
  
  TableVisualizationData({
    required this.table,
    required this.connections,
    required this.fieldTimeSeries,
    required this.minValues,
    required this.maxValues,
    required this.globalMin,
    required this.globalMax,
  });
  
  /// Create visualization data from a data table
  static TableVisualizationData fromTable(DataTable table) {
    final connections = DataTableBuilder.createConnections(table);
    
    // Build time series for each field
    final fieldTimeSeries = <String, List<double>>{};
    final minValues = <String, double>{};
    final maxValues = <String, double>{};
    
    double globalMin = double.infinity;
    double globalMax = double.negativeInfinity;
    
    for (var row in table.rows) {
      final values = row.numericValues;
      if (values.isEmpty) continue;
      
      fieldTimeSeries[row.fieldName] = values;
      
      final fieldMin = row.minValue ?? 0;
      final fieldMax = row.maxValue ?? 1;
      
      minValues[row.fieldName] = fieldMin;
      maxValues[row.fieldName] = fieldMax;
      
      // Update global min/max
      globalMin = fieldMin < globalMin ? fieldMin : globalMin;
      globalMax = fieldMax > globalMax ? fieldMax : globalMax;
    }
    
    // Ensure we have valid bounds
    if (globalMin == double.infinity) globalMin = 0;
    if (globalMax == double.negativeInfinity) globalMax = 1;
    
    print('Global value range: ${globalMin / 1e9}B to ${globalMax / 1e9}B');
    
    return TableVisualizationData(
      table: table,
      connections: connections,
      fieldTimeSeries: fieldTimeSeries,
      minValues: minValues,
      maxValues: maxValues,
      globalMin: globalMin,
      globalMax: globalMax,
    );
  }
  
  /// Get normalized value for visualization (0-1 range) using field-specific normalization
  double normalizeValue(String fieldName, double value) {
    final min = minValues[fieldName] ?? globalMin;
    final max = maxValues[fieldName] ?? globalMax;
    
    if (max == min) return 0.5;
    return (value - min) / (max - min);
  }
  
  /// Get normalized value using global scale (for consistent visualization)
  double normalizeValueGlobal(double value) {
    if (globalMax == globalMin) return 0.5;
    return (value - globalMin) / (globalMax - globalMin);
  }
}