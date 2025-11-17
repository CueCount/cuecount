import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';  // Uses your existing Firebase config
import 'dart:io';

/// Move documents between Firestore collections
/// 
/// Usage from your project root:
/// dart run bin/move_document.dart <fromCollection> <docId> <toCollection>
/// 
/// Examples:
/// dart run bin/move_document.dart users abc123 archived_users
/// dart run bin/move_document.dart posts post456 deleted_posts

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    print("\n📋 Firestore Document Mover");
    print("=" * 50);
    print("\nUsage: dart run bin/move_document.dart <fromCollection> <docId> <toCollection>");
    print("\nExamples:");
    print("  • dart run bin/move_document.dart users abc123 archived_users");
    print("  • dart run bin/move_document.dart posts post456 deleted_posts");
    exit(1);
  }

  final fromCollection = args[0];
  final docId = args[1];
  final toCollection = args[2];

  print("\n🚀 Initializing Firebase...");
  
  // Initialize with your existing Firebase configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("✅ Firebase initialized\n");

  try {
    final firestore = FirebaseFirestore.instance;

    // Create references
    final fromRef = firestore.collection(fromCollection).doc(docId);
    final toRef = firestore.collection(toCollection).doc(docId);

    print("📖 Reading document from: $fromCollection/$docId");
    
    // Fetch the source document
    final snapshot = await fromRef.get();

    if (!snapshot.exists) {
      print("\n❌ Document not found at $fromCollection/$docId");
      exit(1);
    }

    final data = snapshot.data()!;
    print("✅ Found document with ${data.length} fields");

    // Check if destination already exists
    final destSnapshot = await toRef.get();
    if (destSnapshot.exists) {
      print("\n⚠️  Document already exists at $toCollection/$docId");
      print("Overwrite? (y/n)");
      final input = stdin.readLineSync();
      if (input?.toLowerCase() != 'y') {
        print("Cancelled");
        exit(0);
      }
    }

    // Write to destination
    print("✍️  Writing to: $toCollection/$docId");
    await toRef.set(data);

    // Delete original
    print("🗑️  Deleting original");
    await fromRef.delete();

    print("\n✅ Successfully moved $docId from $fromCollection → $toCollection");

  } catch (e) {
    print("\n❌ Error: $e");
    exit(1);
  }

  exit(0);
}