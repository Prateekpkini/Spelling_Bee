import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'dart:ui';
void main() async {
  try {
    usePathUrlStrategy();
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('FlutterError: ${details.exception}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      print('PlatformDispatcher error: $error');
      return true;
    };
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const ProviderScope(child: SpellingBeeApp()));
  } catch (e, stackTrace) {
    print('Initialization error: $e');
    print(stackTrace);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Initialization failed: $e\n$stackTrace'),
          ),
        ),
      ),
    );
  }
}
