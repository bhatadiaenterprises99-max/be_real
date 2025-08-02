import 'package:be_real/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:be_real/routes/app_pages.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with more explicit error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

    // Test Firestore connection to verify it's working
    try {
      final usersCollection = await FirebaseFirestore.instance
          .collection('users')
          .get();
      print(
        "Firestore connection successful: ${usersCollection.docs.isNotEmpty ? 'Documents exist' : 'No documents found'}",
      );
    } catch (e) {
      print("Firestore connection error: $e");
    }
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  await GetStorage.init(); // Initialize GetStorage
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If web, always start at login (admin only); else normal login
    final initialRoute = kIsWeb ? AppRoutes.loginScreen : AppRoutes.loginScreen;
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BE Real',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}


// rules_version = '2';

// service cloud.firestore {
//   match /databases/{database}/documents {

//     // This rule allows anyone with your Firestore database reference to view, edit,
//     // and delete all data in your Firestore database. It is useful for getting
//     // started, but it is configured to expire after 30 days because it
//     // leaves your app open to attackers. At that time, all client
//     // requests to your Firestore database will be denied.
//     //
//     // Make sure to write security rules for your app before that time, or else
//     // all client requests to your Firestore database will be denied until you Update
//     // your rules
//     match /{document=**} {
//       allow read, write: if request.time < timestamp.date(2025, 8, 18);
//     }
//   }
// }